# deploy.ps1 — re-encrypt the hub + brand guidelines and publish the password-gated site.
# Run from this folder after editing SkySlope-Social-Hub.html or brand-guidelines.html:
#   powershell -ExecutionPolicy Bypass -File .\deploy.ps1
# The password you enter is what visitors will type to open the site.
# It is never stored in this repo — only a salted hash goes into the build.
$ErrorActionPreference = 'Stop'
$pw = Read-Host 'Site password'
$env:STATICRYPT_PASSWORD = $pw
$tmp = Join-Path $env:TEMP ("hub-deploy-" + [guid]::NewGuid())
npx staticrypt SkySlope-Social-Hub.html brand-guidelines.html -d $tmp --short --remember 30 --template-title "SkySlope Social Hub" --template-instructions "Team access - enter the shared password." --template-color-primary "#0059DA"
if ($LASTEXITCODE -ne 0) { throw 'staticrypt failed' }
$site = Join-Path $tmp 'site'
New-Item -ItemType Directory -Force $site | Out-Null
# gate pages get the brand favicon injected into their <head>
$fav = '<link rel="icon" type="image/svg+xml" href="favicon.svg">'
$hub = Get-Content (Join-Path $tmp 'SkySlope-Social-Hub.html') -Raw
Set-Content -Encoding utf8 (Join-Path $site 'index.html') ($hub -replace '<head>', ('<head>' + $fav))
$guide = Get-Content (Join-Path $tmp 'brand-guidelines.html') -Raw
Set-Content -Encoding utf8 (Join-Path $site 'brand-guidelines.html') ($guide -replace '<head>', ('<head>' + $fav))
Copy-Item favicon.svg (Join-Path $site 'favicon.svg')
Set-Content -Encoding utf8 (Join-Path $site 'CNAME') 'skyslope.soldonsocial.com'
Set-Content -Encoding utf8 (Join-Path $site '404.html') ('<!DOCTYPE html><html lang="en"><head>' + $fav + '<meta charset="utf-8"><meta http-equiv="refresh" content="0; url=/"><title>SkySlope Social Hub</title></head><body><p><a href="/">Enter the SkySlope Social Hub</a></p></body></html>')
Push-Location $site
git init -b gh-pages -q
git add -A
git commit -q -m "Deploy password-gated hub"
git push -f https://github.com/davebussell/skyslope.git gh-pages
Pop-Location
Remove-Item -Recurse -Force $tmp
Write-Host 'Deployed. Live in about a minute at https://skyslope.soldonsocial.com'
