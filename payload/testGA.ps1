$env:computername
$env:username
write-host "Hello World"
write-host ()"I am {0}" -f ($env:computername))
"Bye world"