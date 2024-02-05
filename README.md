# Firefox

## Usage

Open PowerShell as administrator and enter the command below.

```powershell
irm "https://raw.githubusercontent.com/amitxv/firefox/main/setup.ps1" | iex
```

## Features

- Similar to [Librewolf](https://librewolf.net), removes files

    - ``crashreporter.exe``
    - ``crashreporter.ini``
    - ``defaultagent.ini``
    - ``defaultagent_localized.ini``
    - ``default-browser-agent.exe``
    - ``maintenanceservice.exe``
    - ``maintenanceservice_installer.exe``
    - ``pingsender.exe``
    - ``updater.exe``
    - ``updater.ini``
    - ``update-settings.ini``

- Automatically install recommended extensions

    - [uBlock Origin](https://addons.mozilla.org/en-GB/firefox/addon/ublock-origin)
    - [FastForward](https://addons.mozilla.org/en-GB/firefox/addon/fastforwardteam)
    - [ClearURLs](https://addons.mozilla.org/en-GB/firefox/addon/clearurls)

- Config

    - Disable telemetry
    - Clean and compact interface
