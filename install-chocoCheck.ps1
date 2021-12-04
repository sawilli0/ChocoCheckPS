
$InstallPath = "C:\ChocoCheckPS\"
$ChocoFileName = "check-choco.ps1"

Add-Type -AssemblyName PresentationFramework


# Check if admin and request elevation if not
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit $LASTEXITCODE
}

# Check if ChocoCheck files exist
$alreadyInstalled = Test-Path -Path $InstallPath
if ($alreadyInstalled) {
    # ChocoCheck appears to be installed so ask user for what to do

     $msgBoxResult = [System.Windows.MessageBox]::Show('ChocoCheckPS files found already.  Replace old files?', 'ChocoCheckPS Installer', 'YesNoCancel', 'Exclamation')
     if ( $msgBoxResult -eq 2) {
        # Cancel button - Exit program immediately
        Write-Host "Exitting immediately"
        exit 0
     } elseif ($msgBoxResult -eq 6) {
        # Yes button - Delete old file
        (Get-ChildItem -Path $InstallPath$ChocoFileName -File).Delete()
        Copy-Item .\$ChocoFileName $InstallPath$ChocoFileName
        Write-Host "Previously installed files deleted.  ChocoCheckPS successfully installed to $InstallPath"
     } elseif ($msgBoxResult -eq 7) {
        # No button - Proceed without creating files (allows reinstall of task)
        Write-Host "Continuing install without new files"
     } else {
        Write-Error "Unknown return code from file install message box. Exitting"
        exit 0
     }
} else {
    # ChocoCheck is not installed... so install
    New-Item -Path $InstallPath -ItemType "directory"
    Copy-Item .\$ChocoFileName $InstallPath$ChocoFileName
    Write-Host "ChocoCheckPS successfully installed to $InstallPath"
}

#### Set ACLs for installed files

$facl = Get-Acl $InstallPath
$facl.SetAccessRuleProtection($true, $false)

# Make folder under full control of Admins
$ace = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "Allow")
$facl.SetAccessRule($ace)  

# Allow authenticated users to read and execute files

# Set ACLs for folder
$authUsersSID = New-Object System.Security.Principal.SecurityIdentifier ( "S-1-5-11" );  
$ace = New-Object System.Security.AccessControl.FileSystemAccessRule($authUsersSID, "ReadAndExecute", "Allow")
$facl.SetAccessRule($ace)  
$facl | Set-Acl $InstallPath

# Set ACLs for file
$ACL = Get-Acl -Path $InstallPath$ChocoFileName
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT Authority\Authenticated Users","ReadAndExecute, Synchronize","Allow")
$ACL.SetAccessRule($AccessRule) | Out-Null
$ACL | Set-Acl -Path $InstallPath$ChocoFileName


$facl = Get-Acl -Path $InstallPath
if(!($facl.Access | Where-Object {( $_.IdentityReference -eq "BUILTIN\Administrators") -and ($_.FileSystemRights -eq "FullControl") })) {
    write-error "Error with the ACLs set on the folder: $InstallPath"
    exit 0
}

$acl = Get-Acl -Path $InstallPath$ChocoFileName
if(!($acl.Access | Where-Object {( $_.IdentityReference -eq "NT AUTHORITY\Authenticated Users") -and ($_.FileSystemRights -eq "ReadAndExecute, Synchronize") })) {
    write-error "Error with the ACLs set on the : $InstallPath$ChocoFileName"
    exit 0
}

# Setting for scheduled task
$taskName = "Check choco for outdated packages"
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable  
$action = New-ScheduledTaskAction -Execute "powershell.exe" –Argument “-Hidden -File $InstallPath$ChocoFileName”
$trigger = New-ScheduledTaskTrigger -Daily -At “10:00”
$Principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users"
$registerTask = $true

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if($task) {
    $msgBoxResult = [System.Windows.MessageBox]::Show('ChocoCheckPS scheduled tasks already exists.  Replace old scheduled task?', 'ChocoCheckPS Installer', 'YesNoCancel', 'Exclamation')
    if($msgBoxResult -eq 2) {
        # Cancel button - Exit immediately
        write-host "Exitting immediately"
        exit 0   
    } elseif($msgBoxResult -eq 6) {
        # Yes button - replace old task
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if($task) {
            # Check if successful
            Write-Error "Exitting.  Could not remove old scheduled task (Task Name: $taskName)"
            exit
        }
    } elseif ($msgBoxResult -eq 7) {
        # No button - Skip installation of task
        write-host "Skipping installation of task"
        $registerTask = $false
    } else {
        Write-Error "Unknown return code from scheduled task message box. Exitting"
        exit 0
    }
}

if($registerTask) {
    
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $Principal
    Register-ScheduledTask –TaskName $taskName -InputObject $task | Out-Null

    $taskRes = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if($taskRes) {
        # Check if successful
        Write-Host "Successfully registered ChocoCheck task"
    } else {
        Write-Error "Unsuccessful at registering ChocoCheck task"
        exit 0
    }
}

write-host "install-chocoCheck finished running. Meow."

