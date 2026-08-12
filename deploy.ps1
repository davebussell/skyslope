# deploy.ps1 — re-encrypt the hub and publish the password-gated site.
# Run from this folder after editing SkySlope-Social-Hub.html:
#   powershell -ExecutionPolicy Bypass -File .\deploy.ps1
# The password you enter is what visitors will type to open the site.
# It is never stored in this repo — only a salted hash goes into the build.
$ErrorActionPreference = 'Stop'
$pw = Read-Host 'Site password'
$env:STATICRYPT_PASSWORD = $pw
$tmp = Join-Path $env:TEMP ("hub-deploy-" + [guid]::NewGuid())
npx staticrypt SkySlope-Social-Hub.html -d $tmp --short --remember 30 --template-title "SkySlope Social Hub" --template-instructions "Team access - enter the shared password." --template-color-primary "#2a78d6"
if ($LASTEXITCODE -ne 0) { throw 'staticrypt failed' }
$site = Join-Path $tmp 'site'
New-Item -ItemType Directory -Force $site | Out-Null
Copy-Item (Join-Path $tmp 'SkySlope-Social-Hub.html') (Join-Path $site 'index.html')
Set-Content -Encoding utf8 (Join-Path $site 'CNAME') 'skyslope.soldonsocial.com'
Set-Content -Encoding utf8 (Join-Path $site '404.html') '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta http-equiv="refresh" content="0; url=/"><title>SkySlope Social Hub</title></head><body><p><a href="/">Enter the SkySlope Social Hub</a></p></body></html>'
Push-Location $site
git init -b gh-pages -q
git add -A
git commit -q -m "Deploy password-gated hub"
git push -f https://github.com/davebussell/skyslope.git gh-pages
Pop-Location
Remove-Item -Recurse -Force $tmp
Write-Host 'Deployed. Live in about a minute at https://skyslope.soldonsocial.com'
