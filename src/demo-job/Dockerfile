# Demo Job Dockerfile
# Multi-stage build for .NET 8

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY DemoJob.csproj .
RUN dotnet restore

# Copy source and build
COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Production image - use runtime image for smaller size
FROM mcr.microsoft.com/dotnet/runtime:8.0

WORKDIR /app

# Copy published application
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "DemoJob.dll"]
