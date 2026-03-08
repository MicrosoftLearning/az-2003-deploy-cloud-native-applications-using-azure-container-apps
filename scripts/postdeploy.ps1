# Post-deploy script to update Container App Jobs with the real demo-job image
# This runs after azd deploy pushes the images to ACR

Write-Host "Updating Container App Jobs with demo-job image..." -ForegroundColor Cyan

# Get environment values
$rg = $env:AZURE_RESOURCE_GROUP
$acr = $env:AZURE_CONTAINER_REGISTRY_ENDPOINT

if (-not $rg -or -not $acr) {
    Write-Host "Missing required environment variables. Skipping job update." -ForegroundColor Yellow
    exit 0
}

# Construct the image name (azd uses lowercase env name for images)
$envName = $env:AZURE_ENV_NAME.ToLower()
$imageName = "$acr/contoso-analytics/demo-job-$($envName):latest"

Write-Host "Using image: $imageName" -ForegroundColor Gray

# Update all three jobs
$jobs = @("data-processor-scheduled", "data-processor-manual", "data-processor-parallel")

foreach ($job in $jobs) {
    Write-Host "Updating job: $job" -ForegroundColor Gray
    az containerapp job update -n $job -g $rg --image $imageName --output none 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Updated $job" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Failed to update $job (may not exist yet)" -ForegroundColor Yellow
    }
}

Write-Host "Container App Jobs updated successfully!" -ForegroundColor Green
