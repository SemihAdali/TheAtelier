# Setup GitHub Repo
git init
git add .
git commit -m "initial commit"
Write-Host "Please provide your GitHub Repository URL:"
$repoUrl = Read-Host
git remote add origin $repoUrl
git push -u origin main
Write-Host "Done!"
