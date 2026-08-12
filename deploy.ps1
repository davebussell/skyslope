# deploy.ps1 — re-encrypt the hub + brand guidelines and publish the password-gated site.
# Run from this folder after editing SkySlope-Social-Hub.html, brand-guidelines.html,
# or the landing page (gate-template.html / gate-404.html):
#   powershell -ExecutionPolicy Bypass -File .\deploy.ps1
# The password you enter is what visitors will type to open the site.
# It is never stored in this repo — only a salted hash goes into the build.
$ErrorActionPreference = 'Stop'
$pw = Read-Host 'Site password'
$env:STATICRYPT_PASSWORD = $pw
$tmp = Join-Path $env:TEMP ("hub-deploy-" + [guid]::NewGuid())
npx staticrypt SkySlope-Social-Hub.html brand-guidelines.html -d $tmp -t gate-template.html --short --remember 30 --template-title "SkySlope Social Hub" --template-instructions "Enter the shared team password to open the workspace." --template-placeholder "Team password" --template-button "Enter the Hub" --template-error "That password didn't unlock it - check with Dave and try again." --template-remember "Keep me signed in on this device (30 days)"
if ($LASTEXITCODE -ne 0) { throw 'staticrypt failed' }
$site = Join-Path $tmp 'site'
New-Item -ItemType Directory -Force $site | Out-Null
Copy-Item (Join-Path $tmp 'SkySlope-Social-Hub.html') (Join-Path $site 'index.html')
Copy-Item (Join-Path $tmp 'brand-guidelines.html') (Join-Path $site 'brand-guidelines.html')
Copy-Item favicon.svg (Join-Path $site 'favicon.svg')
Copy-Item gate-404.html (Join-Path $site '404.html')
Set-Content -Encoding utf8 (Join-Path $site 'CNAME') 'skyslope.soldonsocial.com'
Push-Location $site
git init -b gh-pages -q
git add -A
git commit -q -m "Deploy password-gated hub"
git push -f https://github.com/davebussell/skyslope.git gh-pages
Pop-Location
Remove-Item -Recurse -Force $tmp
Write-Host 'Deployed. Live in about a minute at https://skyslope.soldonsocial.com'
