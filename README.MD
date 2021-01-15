# Chromium SecretManagement Extension

For use with Microsoft.Powershell.SecretManagement

Inspired by ReallySimpleDatabase Module and  https://jhoneill.github.io/powershell/2020/11/23/Chrome-Passwords.html


### Get-SecretInfo Filter
Secrets are presented in username|domain format, because usernames can contain @,\, and whitespace symbols, hence the somewhat unusual naming format.

You can search in the following ways:

1. User + Domain Explicit Search (`myuser|https://www.twitter.com/`)
1. Explicit URL (`https://www.twitter.com/`). All components, including trailing backspaces, are required!
1. Wildcard URL Search (`*twitter*`)
1. Explcit User search (`myuser|`)
1. Wildcard User Search (`my*|`) - Note the trailing | to indicate you want to search user and not URL 
1. User + Domain Wildcard Search (`*m*|*tw*`)