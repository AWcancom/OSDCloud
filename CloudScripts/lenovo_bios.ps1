Install-Module lsuclient -Force -Scope CurrentUser -SkipPublisherCheck
$updates = get-lsupdate
$updates | where-object {$_.type -eq 'BIOS'} | Install-LSUpdate -Verbose
   