Install the github cli

Start-Transcript github-access.txt

Write-Output "I've already authenticated to the GitHub site as john-vantuyl-pemco so each of these will use my admin credentials.`n"

Write-Output "Click the export button then CSV to get a list of our members.  The SAML name ID field has the email of each user.`n"
start https://github.com/orgs/pemcoins/people

Write-Output "Now we'll fetch the list of repositories using the GitHub CLI then download the csv list of people along with their access.`n"
(&gh repo list pemcoins --limit 100 --json name | ConvertFrom-Json).name | % {"https://github.com/pemcoins/$_/people/export"} | % { start $_ }


Write-Output "Copy those files from the download folder to this folder then press any key to unpause.`n"

&pause

Write-Output "We'll get a collection of pemco employees.`n"

$members = Get-Content export-pemcoins*.csv | ConvertFrom-Csv | sort saml_name_id

Write-Output "All of those repositories get loaded into one big collection in memory.`n"

$repoCollaborators = Get-Item *-collaborators.csv |
ForEach-Object {
    $repo = $_.Name.Replace('-collaborators.csv', '') # get the repo name from the csv file name
    $csv = Get-Content $_ | ConvertFrom-Csv
    $csv | ForEach-Object {
        $row = $_
        $email = ($members | ? { $_.login -eq $row.login } | select -first 1).saml_name_id;
        [PSCustomObject]@{
            Repository = $repo;
            Email      = "$email".Trim() -eq "" ? "$($row.login) (Outside Collaborator)" : $email;
            Permission = $row.permission;
        }
    }
}

Write-Output "We pick out the users so we can make them into columns.`n"

$collaborators = $repoCollaborators.Email | select -Unique | sort

Write-Output "Last, we write out one row per repository with the user's permissions in the column cells.`n"

$repoCollaborators.Repository | select -Unique | sort |
ForEach-Object {
    $repo = $_
    $hash = [Ordered]@{
        Repository = $repo
    }
    $collaborators | ForEach-Object {
        $collaborator = $_
        $permission = ""
        $permission = ($repoCollaborators | ? { $_.Repository -eq $repo -and $_.Email -eq $collaborator } | select -First 1).Permission
        $hash.Add($collaborator, $permission -eq $null ? "" : $permission)
    }
    $result = [PSCustomObject]$hash
    $result
} |
ConvertTo-Csv | Out-File github-access.csv -Encoding utf8BOM

Stop-Transcript