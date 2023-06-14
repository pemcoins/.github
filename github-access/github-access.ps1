# Install the github cli

Start-Transcript github-access.txt

Write-Output "I've already authenticated to the GitHub site as john-vantuyl-pemco so each of these will use my admin credentials.`n"

Write-Output "Click the export button then CSV to get a list of our members.  The SAML name ID field has the email of each user.`n"
start https://github.com/orgs/pemcoins/people

Write-Output "Now we'll fetch the list of repositories using the GitHub CLI then download the csv list of people along with their access.`n"
(&gh repo list pemcoins --limit 100 --json name | ConvertFrom-Json).name | % {"https://github.com/pemcoins/$_/people/export"} | % { start $_ }

Stop-Transcript