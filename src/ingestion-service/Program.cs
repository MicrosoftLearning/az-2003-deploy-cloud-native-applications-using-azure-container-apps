// Ingestion Service
// ASP.NET Core minimal API microservice that consumes messages from Azure Service Bus
// Demonstrates: Event-driven scaling, Dapr integration, scale-to-zero

using Azure.Core;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Concurrent;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Register singleton services
builder.Services.AddSingleton<MessageProcessor>();
// Note: ServiceBusConsumer is disabled because Dapr pub/sub handles messaging.
// The consumer was causing a loop by reading from the same queue Dapr publishes to.
// builder.Services.AddHostedService<ServiceBusConsumer>();

var app = builder.Build();

// Configure middleware
app.UseCors();
app.UseSwagger();
app.UseSwaggerUI();

// ============================================================================
// API Endpoints
// ============================================================================

app.MapGet("/", () => new
{
    service = "ingestion-service",
    version = "1.0.0",
    framework = ".NET 8",
    description = "Service Bus consumer for Contoso Analytics",
    differentiators = new[]
    {
        "Scale-to-zero when no messages",
        "Event-driven autoscaling via KEDA",
        "Dapr pub/sub for reliable messaging"
    }
});

app.MapGet("/health", () => new { status = "healthy", timestamp = DateTime.UtcNow.ToString("o") });

app.MapGet("/ready", () => new { status = "ready", timestamp = DateTime.UtcNow.ToString("o") });

app.MapGet("/stats", (MessageProcessor processor) => new
{
    messagesProcessed = processor.MessageCount,
    lastMessageTime = processor.LastMessageTime?.ToString("o"),
    queueName = Environment.GetEnvironmentVariable("SERVICEBUS_QUEUE_NAME") ?? "telemetry"
});

// Debug endpoint to check Dapr status
app.MapGet("/dapr-status", async () =>
{
    var daprPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500";
    using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };
    
    try
    {
        // Check Dapr health
        var healthResponse = await client.GetAsync($"http://localhost:{daprPort}/v1.0/healthz");
        
        // Get Dapr metadata (shows loaded components)
        var metadataResponse = await client.GetAsync($"http://localhost:{daprPort}/v1.0/metadata");
        var metadata = await metadataResponse.Content.ReadAsStringAsync();
        
        return Results.Ok(new
        {
            daprHealthy = healthResponse.IsSuccessStatusCode,
            daprPort,
            metadata = JsonSerializer.Deserialize<JsonElement>(metadata)
        });
    }
    catch (Exception ex)
    {
        return Results.Ok(new
        {
            daprHealthy = false,
            daprPort,
            error = ex.Message
        });
    }
});

app.MapPost("/simulate", async ([FromBody] SimulatedEvent? eventData, MessageProcessor processor) =>
{
    // Artificial delay to simulate processing time and create visible concurrency for scaling demos
    await Task.Delay(500);
    
    var data = eventData ?? new SimulatedEvent
    {
        Id = $"sim-{processor.MessageCount + 1}",
        DeviceId = "simulator-001",
        EventType = "temperature",
        Payload = new Dictionary<string, object>
        {
            { "temperature", 72.5 },
            { "humidity", 45.2 },
            { "pressure", 1013.25 }
        }
    };
    
    var processed = await processor.ProcessMessageAsync(data);
    return Results.Ok(new { message = "Event simulated", @event = processed });
});

app.MapGet("/dapr/subscribe", () => Array.Empty<object>());

app.Run();

// ============================================================================
// Models
// ============================================================================

public class SimulatedEvent
{
    public string Id { get; set; } = string.Empty;
    public string DeviceId { get; set; } = string.Empty;
    public string EventType { get; set; } = "telemetry";
    public string? Timestamp { get; set; }
    public Dictionary<string, object>? Payload { get; set; }
}

public class EnrichedEvent
{
    public string Id { get; set; } = string.Empty;
    public string DeviceId { get; set; } = string.Empty;
    public string Timestamp { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty;
    public Dictionary<string, object>? Payload { get; set; }
    public ProcessingMetadata ProcessingMetadata { get; set; } = new();
}

public class ProcessingMetadata
{
    public string IngestedAt { get; set; } = string.Empty;
    public string IngestedBy { get; set; } = "ingestion-service";
    public long SequenceNumber { get; set; }
}

// ============================================================================
// Message Processor Service
// ============================================================================

public class MessageProcessor
{
    private long _messageCount;
    private readonly ILogger<MessageProcessor> _logger;
    private readonly HttpClient _httpClient;
    private readonly string _daprPort;
    private bool _daprReady = false;

    public long MessageCount => _messageCount;
    public DateTime? LastMessageTime { get; private set; }

    public MessageProcessor(ILogger<MessageProcessor> logger)
    {
        _logger = logger;
        _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };
        _daprPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500";
    }

    public async Task<EnrichedEvent> ProcessMessageAsync(SimulatedEvent eventData)
    {
        var count = Interlocked.Increment(ref _messageCount);
        LastMessageTime = DateTime.UtcNow;
        
        var enriched = new EnrichedEvent
        {
            Id = string.IsNullOrEmpty(eventData.Id) ? count.ToString() : eventData.Id,
            DeviceId = eventData.DeviceId ?? "unknown",
            Timestamp = eventData.Timestamp ?? DateTime.UtcNow.ToString("o"),
            EventType = eventData.EventType ?? "telemetry",
            Payload = eventData.Payload,
            ProcessingMetadata = new ProcessingMetadata
            {
                IngestedAt = DateTime.UtcNow.ToString("o"),
                IngestedBy = "ingestion-service",
                SequenceNumber = count
            }
        };
        
        await PublishToDaprAsync(enriched);
        return enriched;
    }

    private async Task PublishToDaprAsync(EnrichedEvent evt)
    {
        // Wait for Dapr sidecar to be ready (with retry)
        if (!_daprReady)
        {
            await WaitForDaprAsync();
        }
        
        // Topic name must match the Service Bus queue name
        var daprUrl = $"http://localhost:{_daprPort}/v1.0/publish/pubsub/telemetry";
        
        // Retry logic with exponential backoff
        var maxRetries = 3;
        var delay = TimeSpan.FromMilliseconds(100);
        
        for (int attempt = 1; attempt <= maxRetries; attempt++)
        {
            try
            {
                var json = JsonSerializer.Serialize(evt);
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync(daprUrl, content);
                
                if (response.StatusCode == System.Net.HttpStatusCode.NoContent)
                {
                    _logger.LogDebug("Published event {EventId} to Dapr pub/sub", evt.Id);
                    return;
                }
                else
                {
                    var responseBody = await response.Content.ReadAsStringAsync();
                    _logger.LogWarning("Dapr publish returned {StatusCode}: {ResponseBody}", response.StatusCode, responseBody);
                    return;
                }
            }
            catch (HttpRequestException ex) when (attempt < maxRetries)
            {
                _logger.LogWarning("Dapr publish attempt {Attempt} failed, retrying in {Delay}ms: {Message}", 
                    attempt, delay.TotalMilliseconds, ex.Message);
                await Task.Delay(delay);
                delay *= 2; // Exponential backoff
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish to Dapr after {Attempts} attempts", attempt);
                return;
            }
        }
    }
    
    private async Task WaitForDaprAsync()
    {
        var healthUrl = $"http://localhost:{_daprPort}/v1.0/healthz";
        var maxWaitTime = TimeSpan.FromSeconds(30);
        var startTime = DateTime.UtcNow;
        
        _logger.LogInformation("Waiting for Dapr sidecar to be ready...");
        
        while (DateTime.UtcNow - startTime < maxWaitTime)
        {
            try
            {
                var response = await _httpClient.GetAsync(healthUrl);
                if (response.IsSuccessStatusCode)
                {
                    _daprReady = true;
                    _logger.LogInformation("Dapr sidecar is ready");
                    return;
                }
            }
            catch
            {
                // Dapr not ready yet
            }
            await Task.Delay(500);
        }
        
        _logger.LogWarning("Dapr sidecar health check timed out after {Seconds}s, proceeding anyway", maxWaitTime.TotalSeconds);
        _daprReady = true; // Proceed anyway to avoid blocking
    }
}

// ============================================================================
// Service Bus Consumer Background Service
// ============================================================================

public class ServiceBusConsumer : BackgroundService
{
    private readonly ILogger<ServiceBusConsumer> _logger;
    private readonly MessageProcessor _processor;
    private ServiceBusClient? _client;
    private ServiceBusProcessor? _serviceBusProcessor;

    public ServiceBusConsumer(ILogger<ServiceBusConsumer> logger, MessageProcessor processor)
    {
        _logger = logger;
        _processor = processor;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var namespaceHost = Environment.GetEnvironmentVariable("SERVICEBUS_NAMESPACE") ?? "";
        var queueName = Environment.GetEnvironmentVariable("SERVICEBUS_QUEUE_NAME") ?? "telemetry";
        var managedIdentityClientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID") ?? "";
        
        if (string.IsNullOrEmpty(namespaceHost))
        {
            _logger.LogWarning("No Service Bus namespace configured (SERVICEBUS_NAMESPACE)");
            return;
        }
        
        _logger.LogInformation("Starting Service Bus consumer for queue {QueueName} on {Namespace}", 
            queueName, namespaceHost);
        
        try
        {
            var fullyQualifiedNamespace = namespaceHost.Contains(".servicebus.windows.net") 
                ? namespaceHost 
                : $"{namespaceHost}.servicebus.windows.net";
            
            // Use managed identity credential
            TokenCredential credential = !string.IsNullOrEmpty(managedIdentityClientId)
                ? new ManagedIdentityCredential(managedIdentityClientId)
                : new DefaultAzureCredential();
            
            _logger.LogInformation("Using {CredentialType} for authentication", 
                !string.IsNullOrEmpty(managedIdentityClientId) ? "user-assigned managed identity" : "default Azure credential");
            
            _client = new ServiceBusClient(fullyQualifiedNamespace, credential);
            _serviceBusProcessor = _client.CreateProcessor(queueName, new ServiceBusProcessorOptions
            {
                AutoCompleteMessages = true,
                MaxConcurrentCalls = 10
            });
            
            _serviceBusProcessor.ProcessMessageAsync += async args =>
            {
                try
                {
                    var body = args.Message.Body.ToString();
                    var eventData = JsonSerializer.Deserialize<SimulatedEvent>(body) ?? new SimulatedEvent();
                    await _processor.ProcessMessageAsync(eventData);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing message");
                }
            };
            
            _serviceBusProcessor.ProcessErrorAsync += args =>
            {
                _logger.LogError(args.Exception, "Service Bus error: {ErrorSource}", args.ErrorSource);
                return Task.CompletedTask;
            };
            
            await _serviceBusProcessor.StartProcessingAsync(stoppingToken);
            
            // Keep running until cancelled
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Service Bus consumer stopping");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Service Bus consumer error");
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_serviceBusProcessor is not null)
        {
            await _serviceBusProcessor.StopProcessingAsync(cancellationToken);
            await _serviceBusProcessor.DisposeAsync();
        }
        
        if (_client is not null)
        {
            await _client.DisposeAsync();
        }
        
        await base.StopAsync(cancellationToken);
    }
}
