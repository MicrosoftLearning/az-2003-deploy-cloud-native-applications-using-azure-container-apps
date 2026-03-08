# Hello API Dockerfile
# Multi-stage build for .NET 8

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY HelloApi.csproj .
RUN dotnet restore

# Copy source and build
COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Production image
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# Copy published application
COPY --from=build /app/publish .

# Version can be set at runtime
ENV APP_VERSION=v1
EXPOSE 3000
ENV ASPNETCORE_URLS=http://+:3000

ENTRYPOINT ["dotnet", "HelloApi.dll"]
