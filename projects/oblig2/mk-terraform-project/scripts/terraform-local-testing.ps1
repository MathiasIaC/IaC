# Local Terraform Helper for oblig2
# Usage:
#   .\terraform-local-testing.ps1 -Environment <environment> -Action <action> [-AutoApprove]
param(
    [ValidateSet('dev','test','prod')]
    [string]$Environment = 'dev',

    [ValidateSet('fmt','init','validate','plan','apply','destroy','all')]
    [string]$Action = 'plan',

    # Optional: Azure subscription id or name to target
    [string]$Subscription,

    [switch]$AutoApprove
)

$ErrorActionPreference = 'Stop'

Write-Host "Terraform local helper" -ForegroundColor Cyan
Write-Host "Env: $Environment | Action: $Action" -ForegroundColor Gray

# Resolve key paths relative to this script
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir     = Split-Path -Parent $scriptDir
$terraformDir = Join-Path $rootDir 'terraform'
$envDir       = Join-Path $rootDir 'environments'
$backendFile  = Join-Path $rootDir 'shared' 'backend.hcl'

if (-not (Test-Path $terraformDir)) { throw "Terraform folder not found: $terraformDir" }
if (-not (Test-Path $envDir)) { throw "Environments folder not found: $envDir" }
if (-not (Test-Path $backendFile)) { throw "backend.hcl not found: $backendFile" }

$envVarsFile = Join-Path $envDir ("{0}.tfvars" -f $Environment)
if (-not (Test-Path $envVarsFile)) { throw "Missing environment tfvars: $envVarsFile" }

# Ensure Azure CLI login
try {
    $null = az account show 2>$null
} catch {
    Write-Host "Logging into Azure..." -ForegroundColor Yellow
}

if ($LASTEXITCODE -ne 0) {
    az login | Out-Null
}

# Ensure correct subscription is selected and export ARM_* for Terraform
if ($Subscription) {
    az account set --subscription $Subscription | Out-Null
}

# Try current account
$account = $null
$accountJson = az account show --output json 2>$null
if ($accountJson) {
    try { $account = $accountJson | ConvertFrom-Json } catch { $account = $null }
}

# If no current account or missing ID, require login and stop
if (-not $account -or -not $account.id) {
    Write-Host "No Azure account found. Please run 'az login' to authenticate and then re-run this script." -ForegroundColor Yellow
    exit 1
}

$env:ARM_SUBSCRIPTION_ID = $account.id
if ($account.tenantId) { $env:ARM_TENANT_ID = $account.tenantId }
Write-Host ("Using Azure subscription: {0} ({1})" -f $account.name, $account.id) -ForegroundColor Gray

Push-Location $terraformDir
try {
    switch ($Action) {
        'fmt' {
            terraform fmt -recursive
            break
        }
        'init' {
            $initArgs = @(
                'init',
                ('-backend-config={0}' -f $backendFile),
                ('-backend-config=key={0}/{0}.tfstate' -f $Environment),
                '-input=false'
            )
            terraform @initArgs
            break
        }
        'validate' {
            terraform validate -no-color
            break
        }
        'plan' {
            $initArgs = @(
                'init',
                ('-backend-config={0}' -f $backendFile),
                ('-backend-config=key={0}/{0}.tfstate' -f $Environment),
                '-input=false'
            )
            terraform @initArgs | Out-Null

            terraform validate -no-color | Out-Null

            $planOut = ('plan-{0}.tfplan' -f $Environment)
            terraform plan -var-file $envVarsFile -out $planOut
            break
        }
        'apply' {
            $initArgs = @(
                'init',
                ('-backend-config={0}' -f $backendFile),
                ('-backend-config=key={0}/{0}.tfstate' -f $Environment),
                '-input=false'
            )
            terraform @initArgs | Out-Null

            terraform validate -no-color | Out-Null

            $applyArgs = @('-var-file', $envVarsFile)
            if ($AutoApprove) { $applyArgs += '-auto-approve' }
            terraform apply @applyArgs
            break
        }
        'destroy' {
            $initArgs = @(
                'init',
                ('-backend-config={0}' -f $backendFile),
                ('-backend-config=key={0}/{0}.tfstate' -f $Environment),
                '-input=false'
            )
            terraform @initArgs | Out-Null

            $destroyArgs = @('-var-file', $envVarsFile)
            if ($AutoApprove) { $destroyArgs += '-auto-approve' }
            terraform destroy @destroyArgs
            break
        }
        'all' {
            terraform fmt -recursive | Out-Null
            $initArgs = @(
                'init',
                ('-backend-config={0}' -f $backendFile),
                ('-backend-config=key={0}/{0}.tfstate' -f $Environment),
                '-input=false'
            )
            terraform @initArgs | Out-Null
            terraform validate -no-color | Out-Null
            $planOut = ('plan-{0}.tfplan' -f $Environment)
            terraform plan -var-file $envVarsFile -out $planOut | Out-Null
            $applyArgs = @('-var-file', $envVarsFile)
            if ($AutoApprove) { $applyArgs += '-auto-approve' }
            terraform apply @applyArgs
            break
        }
        default { throw "Unknown action: $Action" }
    }
}
finally {
    Pop-Location
}

Write-Host "Done." -ForegroundColor Green
