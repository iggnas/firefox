param(
    [switch]$force,
    [switch]$skip_hash_check,
    [string]$lang = "en-GB",
    [string]$version
)

function Is-Admin() {
    $current_principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $current_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enforce-Tls() {
    try {
        # not available on Windows 7 by default
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls2
    } catch {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls
        } catch {
            # ignore
        }
    }
}

function Fetch-SHA512($source, $file_name) {
    $response = Invoke-WebRequest $source -UseBasicParsing

    $data = $response.Content.split("`n")

    foreach ($line in $data) {
        $split_line = $line.Split(" ", 2)
        $hash = $split_line[0]
        $current_file_name = $split_line[1].Trim()

        if ($null -ne $hash -and $null -ne $current_file_name) {
            if ($current_file_name -eq $file_name) {
                return $hash
            }
        }
    }
    return $null
}

function main() {
    if (-not (Is-Admin)) {
        Write-Host "error: administrator privileges required"
        return 1
    }

    # disable progress bar
    # https://github.com/PowerShell/PowerShell/issues/2138
    $ProgressPreference = 'SilentlyContinue'

    # silently try to enforce Tls
    Enforce-Tls

    try {
        $response = Invoke-WebRequest "https://product-details.mozilla.org/1.0/firefox_versions.json" -UseBasicParsing
    } catch [System.Net.WebException] {
        Write-Host "error: failed to fetch json data, check internet connection and try again"
        return 1
    }

    $firefox_versions = ConvertFrom-Json $response.Content
    $setup_file = "$($env:temp)\FirefoxSetup.exe"
    $remote_version = if ($version) { $version } else { $firefox_versions.LATEST_FIREFOX_VERSION }
    $download_url = "https://releases.mozilla.org/pub/firefox/releases/$($remote_version)/win64/$($lang)/Firefox%20Setup%20$($remote_version).exe"
    $install_dir = "C:\Program Files\Mozilla Firefox"
    $hash_source = "https://ftp.mozilla.org/pub/firefox/releases/$($remote_version)/SHA512SUMS"

    # check if currently installed version is already latest
    if (Test-Path "$($install_dir)\firefox.exe") {
        $local_version = (Get-Item "$($install_dir)\firefox.exe").VersionInfo.ProductVersion

        if ($local_version -eq $remote_version) {
            Write-Host "info: Mozilla Firefox $($remote_version) already installed"

            if ($force) {
                Write-Host "warning: -force specified, proceeding anyway"
            } else {
                return 1
            }
        }
    }

    Write-Host "info: downloading firefox $($remote_version) setup"
    Invoke-WebRequest $download_url -OutFile $setup_file

    if (-not (Test-Path $setup_file)) {
        Write-Host "error: failed to download setup file"
        return 1
    }

    if (-not $skip_hash_check) {
        Write-Host "info: checking SHA512"
        $local_SHA512 = (Get-FileHash -Path $setup_file -Algorithm SHA512).Hash
        $remote_SHA512 = Fetch-SHA512 -source $hash_source -file_name "win64/$($lang)/Firefox Setup $($remote_version).exe"

        if ($null -eq $remote_SHA512) {
            Write-Host "error: unable to find hash"
            return 1
        }

        if ($local_SHA512 -ne $remote_SHA512) {
            Write-Host "error: hash mismatch"
            return 1
        }
    }

    Write-Host "info: installing firefox"

    # close firefox if it is running
    Stop-Process -Name "firefox" -ErrorAction SilentlyContinue

    # start installation
    Start-Process -FilePath $setup_file -ArgumentList "/S /MaintenanceService=false" -Wait

    # remove installer binary
    Remove-Item $setup_file

    $remove_files = @(
        "crashreporter.exe",
        "crashreporter.ini",
        "defaultagent.ini",
        "defaultagent_localized.ini",
        "default-browser-agent.exe",
        "maintenanceservice.exe",
        "maintenanceservice_installer.exe",
        "pingsender.exe",
        "updater.exe",
        "updater.ini",
        "update-settings.ini"
    )

    # remove files
    foreach ($file in $remove_files) {
        $file = "$($install_dir)\$($file)"
        if (Test-Path $file) {
            Remove-Item $file
        }
    }

    $policies_content = @{
        policies = @{
            DisableAppUpdate     = $true
            OverrideFirstRunPage = ""
            Extensions           = @{
                Install = @(
                    "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/11423598-latest.xpi",
                    "https://addons.mozilla.org/firefox/downloads/latest/fastforwardteam/17032224-latest.xpi",
                    "https://addons.mozilla.org/firefox/downloads/latest/clearurls/13196993-latest.xpi"
                )
            }
        }
    }

    $autoconfig_content = @(
        "pref(`"general.config.filename`", `"firefox.cfg`");",
        "pref(`"general.config.obscure_value`", 0);"
    ) -join "`n"

    $firefox_config_content =
    "`r`ndefaultPref(`"app.shield.optoutstudies.enabled`", false)`
defaultPref(`"datareporting.healthreport.uploadEnabled`", false)`
defaultPref(`"browser.newtabpage.activity-stream.feeds.section.topstories`", false)`
defaultPref(`"browser.newtabpage.activity-stream.feeds.topsites`", false)`
defaultPref(`"dom.security.https_only_mode`", true)`
defaultPref(`"browser.uidensity`", 1)`
defaultPref(`"full-screen-api.transition-duration.enter`", `"0 0`")`
defaultPref(`"full-screen-api.transition-duration.leave`", `"0 0`")`
defaultPref(`"full-screen-api.warning.timeout`", 0)`
defaultPref(`"nglayout.enable_drag_images`", false)`
defaultPref(`"reader.parse-on-load.enabled`", false)`
defaultPref(`"browser.tabs.firefox-view`", false)`
defaultPref(`"browser.tabs.tabmanager.enabled`", false)`
lockPref(`"browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons`", false)`
lockPref(`"browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features`", false)"

    # create "distribution" folder for policies.json
    (New-Item -Path "$($install_dir)" -Name "distribution" -ItemType "directory" -Force) 2>&1 > $null
    # write to policies.json
    Set-Content -Path "$($install_dir)\distribution\policies.json" -Value (ConvertTo-Json -InputObject $policies_content -Depth 10)

    # write to autoconfig.js
    Set-Content -Path "$($install_dir)\defaults\pref\autoconfig.js" -Value $autoconfig_content

    # write to firefox.cfg
    Set-Content -Path "$($install_dir)\firefox.cfg" -Value $firefox_config_content

    Write-Host "info: release notes: https:/www.mozilla.org/en-US/firefox/$($remote_version)/releasenotes"

    return 0
}

$_exit_code = main
Write-Host # new line
exit $_exit_code