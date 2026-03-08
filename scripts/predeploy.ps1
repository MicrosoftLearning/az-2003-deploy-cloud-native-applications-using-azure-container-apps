# Pre-deploy script to build and push the demo-job image to ACR
# This runs before azd provision to ensure the image exists

Write-Host "Building and pushing demo-job image..." -ForegroundColor Cyan

# Get environment values
$acr = $env:AZURE_CONTAINER_REGISTRY_ENDPOINT
$envName = $env:AZURE_ENV_NAME

if (-not $acr) {
    Write-Host "Container registry not yet provisioned. Skipping demo-job build." -ForegroundColor Yellow
    exit 0
}

# Construct the image name (lowercase for Docker compatibility)
$envNameLower = $envName.ToLower()
$imageName = "$acr/contoso-analytics/demo-job-$($envNameLower):latest"

Write-Host "Building image: $imageName" -ForegroundColor Gray

# Build and push the image
Push-Location "$PSScriptRoot/../src/demo-job"
try {
    docker build -t $imageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build demo-job image" -ForegroundColor Red
        exit 1
    }
    
    # Login to ACR
    az acr login --name ($acr -replace '\.azurecr\.io$', '')
    
    docker push $imageName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to push demo-job image" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ demo-job image built and pushed successfully!" -ForegroundColor Green
} finally {
    Pop-Location
}
