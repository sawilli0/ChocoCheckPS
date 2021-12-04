# ChocoCheckPS

ChocoCheckPS is a PowerShell script to check for outdated Chocolatey packages using a Scheduled Task.  It will popup a dialog box with whether there are no new updates or updates are available.  If there are updates, the user will have to upgrade separately.

Install the script and the task by running "install-ChocoCheck.ps1" as an Administrator.  It will install the script to "C:\ChocoCheckPS\" and restrict write privileges to Administrators and Execute privileges to Authenticated Users.  The script also creates a scheduled task to run the script daily at 1000.
