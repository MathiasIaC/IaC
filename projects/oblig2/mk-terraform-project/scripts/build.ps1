# Build script for Windows (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "📦 Building Terraform Artifact..." -ForegroundColor Green
Write-Host ""

# Generate version
if (Get-Command git -ErrorAction SilentlyContinue) {
    $VERSION = git rev-parse --short HEAD
} else {
    $VERSION = Get-Date -Format "yyyyMMdd-HHmmss"
}

Write-Host "Version: $VERSION" -ForegroundColor Cyan
Write-Host ""

# Validate Terraform
Write-Host "1️⃣ Validating Terraform..." -ForegroundColor Yellow
Set-Location terraform
terraform fmt -check -recursive
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Run 'terraform fmt -recursive' to fix formatting" -ForegroundColor Red
    exit 1
}
terraform init -backend=false
terraform validate
Set-Location ..

Write-Host "✅ Validation complete!" -ForegroundColor Green
Write-Host ""

# Create artifact
Write-Host "2️⃣ Creating artifact..." -ForegroundColor Yellow
$ARTIFACT_NAME = "terraform-$VERSION.tar.gz"

tar -czf $ARTIFACT_NAME terraform/ environments/ backend-configs/

Write-Host "✅ Artifact created: $ARTIFACT_NAME" -ForegroundColor Green
Write-Host ""

# Show artifact info
Write-Host "📊 Artifact Information:" -ForegroundColor Cyan
Get-Item $ARTIFACT_NAME | Select-Object Name, Length, LastWriteTime
Write-Host ""
Write-Host "🎯 Next steps:" -ForegroundColor Yellow
Write-Host "  - Deploy to dev:  .\scripts\deploy.ps1 dev $ARTIFACT_NAME"
Write-Host "  - Deploy to test: .\scripts\deploy.ps1 test $ARTIFACT_NAME"
