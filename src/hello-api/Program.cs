// Hello API
// ASP.NET Core minimal API for Traffic Splitting Demo
// Demonstrates: Blue-green deployments, canary releases, traffic splitting

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configuration
var version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "v1";
var color = version == "v1" ? "#3b82f6" : "#22c55e"; // Blue for v1, Green for v2
var hostname = Environment.MachineName;

// Configure middleware
app.UseSwagger();
app.UseSwaggerUI();

// ============================================================================
// API Endpoints
// ============================================================================

app.MapGet("/", () => Results.Content($@"
<!DOCTYPE html>
<html>
<head>
  <meta charset=""UTF-8"">
  <title>Hello API - {version}</title>
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      color: white;
    }}
    .container {{
      text-align: center;
      padding: 40px;
      background: rgba(255,255,255,0.05);
      border-radius: 20px;
      border: 2px solid {color};
      box-shadow: 0 0 30px {color}40;
    }}
    h1 {{
      font-size: 72px;
      margin: 0;
      color: {color};
    }}
    p {{
      font-size: 24px;
      color: #9ca3af;
      margin: 20px 0 0;
    }}
    .version-badge {{
      display: inline-block;
      background: {color};
      color: white;
      padding: 8px 24px;
      border-radius: 20px;
      font-size: 18px;
      font-weight: bold;
      margin-top: 20px;
    }}
    .hostname {{
      font-size: 12px;
      color: #6b7280;
      margin-top: 20px;
    }}
    .framework {{
      font-size: 14px;
      color: #8b5cf6;
      margin-top: 10px;
    }}
  </style>
</head>
<body>
  <div class=""container"">
    <h1>🚀 Hello!</h1>
    <p>Azure Container Apps Traffic Splitting Demo</p>
    <div class=""version-badge"">{version}</div>
    <p class=""framework"">.NET 8</p>
    <p class=""hostname"">Hostname: {hostname}</p>
  </div>
</body>
</html>
", "text/html; charset=utf-8"));

app.MapGet("/api/version", () => new
{
    version,
    framework = ".NET 8",
    hostname,
    timestamp = DateTime.UtcNow.ToString("o")
});

app.MapGet("/health", () => new { status = "healthy", version });

app.MapGet("/ready", () => new { status = "ready", version });

app.Run();
