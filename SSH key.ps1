#Run in ConEmu !!!

# Permanently add C:\Program Files\Git\usr\bin to machine Path variable
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Git\usr\bin", "Machine")

# Generate the key and put into the your user profile .ssh directory
#ssh-keygen -t rsa -b 4096 -C "jakubvonsyrek@gmail.com" -f $env:USERPROFILE\ssH\id_rsa.pub

# Copy the public key. Be sure to copy the .pub for the public key
#Get-Content $env:USERPROFILE\ssH\id_rsa.pub | clip
Start-SshAgent
Add-SshKey $env:USERPROFILE\ssh\id_rsa.pub

git config --global user.email "jakubvonsyrek@gmail.com"
git config --global user.name "Jakub-Syrek"
git config --global push.default simple
git config --global core.ignorecase false

# Configure line endings for windows
git config --global core.autocrlf true