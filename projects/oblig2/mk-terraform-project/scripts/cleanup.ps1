# Terraform Cleanup Script - PowerShell Version
$ErrorActionPreference = "Stop"

Write-Host "🧹 Cleanup Script for Terraform Demo" -ForegroundColor Cyan
Write-Host ""

# Function to destroy environment
function Remove-TerraformEnvironment {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("dev", "test", "prod")]
        [string]$Environment
    )
    
    $workspace = "workspace-$Environment"
    
    Write-Host "───────────────────────────────────────" -ForegroundColor Gray
    Write-Host "Cleaning up: $Environment environment" -ForegroundColor Yellow
    Write-Host "───────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
    
    if (-not (Test-Path $workspace)) {
        Write-Host "⚠️  Workspace not found: $workspace" -ForegroundColor Yellow
        Write-Host "   Skipping terraform destroy (use Azure cleanup if needed)" -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    # Get subscription ID
    try {
        $subscriptionId = az account show --query id -o tsv 2>$null
        
        if ([string]::IsNullOrEmpty($subscriptionId) -or $LASTEXITCODE -ne 0) {
            Write-Host "❌ Error: Not logged in to Azure" -ForegroundColor Red
            Write-Host "   Please run: az login" -ForegroundColor Gray
            return
        }
        
        $env:ARM_SUBSCRIPTION_ID = $subscriptionId
        
    } catch {
        Write-Host "❌ Error: Azure CLI not available" -ForegroundColor Red
        return
    }
    
    $terraformPath = Join-Path $workspace "terraform"
    Push-Location $terraformPath
    
    try {
        # Initialize if needed
        if (-not (Test-Path ".terraform")) {
            Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
            $backendConfig = Join-Path ".." "backend-configs" "backend-$Environment.tfvars"
            terraform init -backend-config=$backendConfig
            Write-Host ""
        }
        
        # Show what will be destroyed
        Write-Host "📋 Planning destruction..." -ForegroundColor Yellow
        $envVarsFile = Join-Path ".." "environments" "$Environment.tfvars"
        terraform plan -destroy -var-file=$envVarsFile
        Write-Host ""
        
        # Confirm
        $confirm = Read-Host "❓ Destroy $Environment environment? (yes/no)"
        
        if ($confirm -ne "yes") {
            Write-Host "⏭️  Skipped $Environment" -ForegroundColor Gray
            Pop-Location
            Write-Host ""
            return
        }
        
        # Destroy
        Write-Host ""
        Write-Host "💥 Destroying infrastructure..." -ForegroundColor Red
        terraform destroy -var-file=$envVarsFile -auto-approve
        
        Pop-Location
        Write-Host ""
        Write-Host "✅ $Environment environment destroyed" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host ""
        Write-Host "❌ Error destroying environment: $_" -ForegroundColor Red
        Pop-Location
        Write-Host ""
    }
}

# Function to clean local files
function Clear-LocalFiles {
    Write-Host "🧹 Cleaning local files..." -ForegroundColor Yellow
    Write-Host ""
    
    $cleaned = $false
    
    # Remove workspaces
    $workspaces = Get-ChildItem -Directory -Filter "workspace-*" -ErrorAction SilentlyContinue
    if ($workspaces) {
        Write-Host "  Removing workspaces..." -ForegroundColor Gray
        $workspaces | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force
        }
        Write-Host "  ✅ Workspaces removed" -ForegroundColor Green
        $cleaned = $true
    }
    
    # Remove artifacts (both .tar.gz and .zip)
    $artifacts = Get-ChildItem -File -Filter "terraform-*.*" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Extension -in @(".gz", ".zip") -or $_.Name -like "*.tar.gz" }
    
    if ($artifacts) {
        Write-Host "  Removing artifacts..." -ForegroundColor Gray
        $artifacts | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
        }
        Write-Host "  ✅ Artifacts removed" -ForegroundColor Green
        $cleaned = $true
    }
    
    if (-not $cleaned) {
        Write-Host "  No local files to clean" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "✅ Local cleanup complete" -ForegroundColor Green
    Write-Host ""
}

# Function for force cleanup via Azure CLI
function Remove-AzureResourcesForce {
    Write-Host "💥 Force cleanup via Azure CLI" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  WARNING: This will delete resource groups directly!" -ForegroundColor Yellow
    Write-Host "   Use this only if terraform destroy fails." -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "Continue? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Host "Cancelled" -ForegroundColor Gray
        return
    }
    
    try {
        Write-Host ""
        Write-Host "Available resource groups:" -ForegroundColor Cyan
        
        $resourceGroups = az group list --query "[?starts_with(name, 'rg-demo-')]" | ConvertFrom-Json
        
        if ($resourceGroups.Count -eq 0) {
            Write-Host "No resource groups found with prefix 'rg-demo-'" -ForegroundColor Gray
            return
        }
        
        $resourceGroups | Format-Table -Property name, location -AutoSize
        
        Write-Host ""
        $rgName = Read-Host "Enter resource group name to delete (or 'all' for all demo groups)"
        
        if ($rgName -eq "all") {
            Write-Host ""
            Write-Host "🔥 Deleting all demo resource groups..." -ForegroundColor Red
            
            foreach ($rg in $resourceGroups) {
                Write-Host "  Deleting: $($rg.name)" -ForegroundColor Gray
                az group delete --name $rg.name --yes --no-wait | Out-Null
            }
            
            Write-Host ""
            Write-Host "✅ Deletion initiated (running in background)" -ForegroundColor Green
            Write-Host "   Check status: az group list -o table" -ForegroundColor Gray
            
        } elseif (-not [string]::IsNullOrWhiteSpace($rgName)) {
            Write-Host ""
            Write-Host "🔥 Deleting: $rgName" -ForegroundColor Red
            az group delete --name $rgName --yes --no-wait | Out-Null
            Write-Host ""
            Write-Host "✅ Deletion initiated" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Main menu
Write-Host "Select cleanup option:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1) Destroy DEV environment" -ForegroundColor White
Write-Host "  2) Destroy TEST environment" -ForegroundColor White
Write-Host "  3) Destroy PROD environment" -ForegroundColor White
Write-Host "  4) Destroy ALL environments" -ForegroundColor White
Write-Host "  5) Clean local files only (workspaces, artifacts)" -ForegroundColor White
Write-Host "  6) Force cleanup via Azure CLI (if terraform fails)" -ForegroundColor White
Write-Host "  7) Full cleanup (everything)" -ForegroundColor White
Write-Host "  0) Cancel" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice [0-7]"

switch ($choice) {
    "1" {
        Remove-TerraformEnvironment -Environment "dev"
    }
    "2" {
        Remove-TerraformEnvironment -Environment "test"
    }
    "3" {
        Remove-TerraformEnvironment -Environment "prod"
    }
    "4" {
        Remove-TerraformEnvironment -Environment "dev"
        Remove-TerraformEnvironment -Environment "test"
        Remove-TerraformEnvironment -Environment "prod"
    }
    "5" {
        Clear-LocalFiles
    }
    "6" {
        Remove-AzureResourcesForce
    }
    "7" {
        Write-Host "🔥 FULL CLEANUP - Everything will be removed!" -ForegroundColor Red
        Write-Host ""
        $confirm = Read-Host "Are you sure? (yes/no)"
        
        if ($confirm -eq "yes") {
            # Destroy all environments
            Remove-TerraformEnvironment -Environment "dev"
            Remove-TerraformEnvironment -Environment "test"
            Remove-TerraformEnvironment -Environment "prod"
            
            # Clean local files
            Clear-LocalFiles
            
            Write-Host ""
            Write-Host "✅ Full cleanup complete!" -ForegroundColor Green
        }
        Write-Host ""
    }
    "0" {
        Write-Host "Cancelled" -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host "───────────────────────────────────────" -ForegroundColor Gray
Write-Host "Cleanup script finished" -ForegroundColor Green
Write-Host "───────────────────────────────────────" -ForegroundColor Gray
