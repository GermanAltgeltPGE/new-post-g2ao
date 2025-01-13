# Removes existing HTTPS listeners (some builds have broken existing listeners)
Get-ChildItem -Path WSMan:\localhost\listener | Where-Object { $_.Keys -Contains "transport=HTTPS" } | Remove-Item -Recurse -Force
# Create new HTTPS listener with appropriate cert
winrm quickconfig -transport:HTTPS -quiet