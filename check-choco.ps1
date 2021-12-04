
Add-Type -AssemblyName PresentationFramework

choco outdated

if( $LASTEXITCODE -eq 0 ) {
    # No updates
    [System.Windows.MessageBox]::Show('Choco packages are up-to-date', 'ChocoCheckPS', 'Ok', 'Information')
} elseif ($LASTEXITCODE -eq 1) {
    # Error with choco
    [System.Windows.MessageBox]::Show('Error received from "choco outdated"', 'ChocoCheckPS', 'Ok', 'Error')
} elseif ($LASTEXITCODE -eq 2) {
    # Outdated packages exist
    [System.Windows.MessageBox]::Show('Outdated choco packages have been found', 'ChocoCheckPS', 'Ok', 'Warning')
} else {
    # Unknown exit code returned
    [System.Windows.MessageBox]::Show('Unknown return code from "choco outdated"', 'ChocoCheckPS', 'Ok', 'Error')
}