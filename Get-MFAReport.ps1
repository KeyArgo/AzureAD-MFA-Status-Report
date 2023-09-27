# Check if running as Administrator, if not, show a warning message and prompt for elevation
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "************************************************************" -ForegroundColor Yellow
    Write-Host "WARNING: This script requires administrator privileges to retrieve MFA status information" -ForegroundColor Yellow
    Write-Host "for each user within the organization. You will be prompted to elevate." -ForegroundColor Yellow
    Write-Host "Please read and understand the reason for elevation before proceeding." -ForegroundColor Yellow
    Write-Host "************************************************************" -ForegroundColor Yellow
    Write-Host ""
    
    # Prompt to continue
    $confirmElevation = Read-Host "Do you want to continue and elevate to run the script? (Y/N)"
    
    if ($confirmElevation -eq "Y" -or $confirmElevation -eq "y") {
        # Relaunch the script with elevated privileges
        Write-Host "Relaunching the script with elevated privileges..."
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
        Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
        exit
    } else {
        Write-Host "Script execution cancelled." -ForegroundColor Red
        exit
    }
}

# Display a warning message at the beginning of the script
Write-Host "************************************************************" -ForegroundColor Yellow
Write-Host "WARNING: This script is designed to retrieve MFA status information" -ForegroundColor Yellow
Write-Host "for each user within the organization. It will NOT make any changes" -ForegroundColor Yellow
Write-Host "to your Office 365 accounts." -ForegroundColor Yellow
Write-Host "Use this script responsibly and ensure you have the necessary permissions." -ForegroundColor Yellow
Write-Host "You will find the MFA Status Report within the export directory." -ForegroundColor Yellow
Write-Host "************************************************************" -ForegroundColor Yellow
Write-Host ""

# List of required modules
$requiredModules = @("AzureAD", "MSOnline")

# Check if all required modules are installed
$missingModules = $requiredModules | Where-Object { -not (Get-Module -ListAvailable -Name $_) }

# If there are missing modules, prompt the user to install them
if ($missingModules.Count -gt 0) {
    Write-Host "The following required modules are missing: $($missingModules -join ', ')" -ForegroundColor Red
    $installModules = Read-Host "Do you want to install the missing modules? (Y/N)"

    if ($installModules -eq "Y" -or $installModules -eq "y") {
        $missingModules | ForEach-Object {
            Install-Module -Name $_ -Force -Scope CurrentUser | Out-Null
        }
        Write-Host "Modules installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Required modules not installed. Some functionalities may not work." -ForegroundColor Yellow
    }
}

# Initialize log file directory and file
$LogDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory
}
$LogPath = Join-Path $LogDir "Git-MFAReport.log"

# Function to log messages with timestamps
function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    $logEntry | Out-File $LogPath -Append
    Write-Host $logEntry
}

$continue = $true

# Loop to retrieve information for multiple accounts
do {
    # Prompt for email address or label
    $Email = Read-Host -Prompt "Please enter the Office365 email address or a name you would like to label this export"

    # Connect to Azure AD
    Try {
        Connect-MsolService
    } Catch {
        Log-Message "Failed to connect to Azure AD: $_"
        Write-Host "Failed to connect to Azure AD: $_" -ForegroundColor Red
        $continueResponse = Read-Host "Do you want to try another email? (Y/N)"

        if ($continueResponse -ne "Y" -and $continueResponse -ne "y") {
            $continue = $false
        }

        # Continue to the next iteration of the loop
        continue
    }

    Try {
        Log-Message "Searching for Azure AD User Accounts..."

        # Fetch users
        $AllUsers = Get-MsolUser -All
        if ($AllUsers -eq $null) {
            Log-Message "No users found."
            continue
        }

        $FilteredUsers = $AllUsers | Where-Object {$_.UserType -ne "Guest"}
        if ($FilteredUsers.Count -eq 0) {
            Log-Message "No non-guest users found."
            continue
        }

        # Initialize empty array for report
        $UserReport = @()
        Log-Message ("Found {0} user accounts. Starting to process..." -f $FilteredUsers.Count)

        # Loop through each user
        foreach ($UserObj in $FilteredUsers) {
            # Your loop code here
            $MFAInfo = if ($UserObj.StrongAuthenticationRequirements -ne $null) { $UserObj.StrongAuthenticationRequirements } else { @() }
            $MFACurrentStatus = if ($MFAInfo) { $MFAInfo.State } else { "Disabled" }

            $AuthMethods = if ($UserObj.StrongAuthenticationMethods -ne $null) { $UserObj.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq $true } } else { @() }
            $DefaultMFA = if ($AuthMethods) { $AuthMethods.MethodType } else { "Not enabled" }

            # Extract email addresses
            $MainEmailAddress = $UserObj.ProxyAddresses | Where-Object {$_ -clike "SMTP*"} | ForEach-Object {$_ -replace "SMTP:", ""}
            $EmailAliases = $UserObj.ProxyAddresses | Where-Object {$_ -clike "smtp*"} | ForEach-Object {$_ -replace "smtp:", ""}

            # Create custom PowerShell object
            $UserRecord = [PSCustomObject] @{
                "UserPrincipalName" = $UserObj.UserPrincipalName
                "DisplayName" = $UserObj.DisplayName
                "MFAStatus" = $MFACurrentStatus
                "PreferredMFA" = $DefaultMFA
                "PhoneNumber" = $UserObj.StrongAuthenticationUserDetails.PhoneNumber
                "MainEmailAddress" = ($MainEmailAddress -join ',')
                "EmailAliases" = ($EmailAliases -join ',')
            }

            # Append to report array
            $UserReport += $UserRecord
        }

        # Check if the export folder exists; create it if it doesn't
        $ExportFolder = Join-Path $PSScriptRoot "export"
        if (-not (Test-Path $ExportFolder)) {
            New-Item -Path $ExportFolder -ItemType Directory
        }

        # Set the export path
        $ExportFileName = "${Email}_MFAStatusReport.csv"
        $ExportPath = Join-Path $ExportFolder $ExportFileName
        $UserReport | Sort-Object UserPrincipalName | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

        Log-Message "Report has been saved to $ExportPath"

    } Catch {
        Log-Message "An error occurred: $_"
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }

    # Ask if the user wants to run the script for another account
    $continueResponse = Read-Host "Do you want to retrieve information for another account? (Y/N)"

    if ($continueResponse -ne "Y" -and $continueResponse -ne "y") {
        $continue = $false
    }
} while ($continue)
