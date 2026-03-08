// Container Apps Job Demo - Data Processor
// A simple job that simulates batch processing with visible output.

var jobName = Environment.GetEnvironmentVariable("JOB_NAME") ?? "demo-job";
var executionId = Environment.GetEnvironmentVariable("CONTAINER_APP_JOB_EXECUTION_NAME") ?? "local";
var replicaIndex = Environment.GetEnvironmentVariable("CONTAINER_APP_REPLICA_INDEX") ?? "0";

Console.WriteLine(new string('=', 60));
Console.WriteLine("🚀 Container Apps Job Started");
Console.WriteLine(new string('=', 60));
Console.WriteLine($"  Job Name:      {jobName}");
Console.WriteLine($"  Execution ID:  {executionId}");
Console.WriteLine($"  Replica Index: {replicaIndex}");
Console.WriteLine($"  Framework:     .NET 8");
Console.WriteLine($"  Start Time:    {DateTime.Now:O}");
Console.WriteLine(new string('=', 60));

// Simulate batch processing
var random = new Random();
var totalItems = random.Next(5, 16);
Console.WriteLine($"\n📦 Processing {totalItems} items...\n");

for (int i = 1; i <= totalItems; i++)
{
    // Simulate work
    var processTime = random.NextDouble() * 0.5 + 0.3; // 0.3 to 0.8 seconds
    await Task.Delay(TimeSpan.FromSeconds(processTime));
    
    var status = random.NextDouble() > 0.1 ? "✅" : "⚠️";
    Console.WriteLine($"  {status} Item {i}/{totalItems} processed in {processTime:F2}s");
}

// Summary
Console.WriteLine("\n" + new string('=', 60));
Console.WriteLine("✅ Job Completed Successfully!");
Console.WriteLine($"  End Time:        {DateTime.Now:O}");
Console.WriteLine($"  Items Processed: {totalItems}");
Console.WriteLine(new string('=', 60));
