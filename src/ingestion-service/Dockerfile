# Ingestion Service Dockerfile
# Multi-stage build for .NET 8

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY IngestionService.csproj .
RUN dotnet restore

# Copy source and build
COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Production image
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# Copy published application
COPY --from=build /app/publish .

# Expose port for Container Apps
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Run the application
ENTRYPOINT ["dotnet", "IngestionService.dll"]
