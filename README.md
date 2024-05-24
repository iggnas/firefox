# Firefox

> [!IMPORTANT]
> Auto-update capabilities are not available as updates are disabled after installing Firefox with the script. Alternatively, you can run the script at startup with task scheduler to check for updates when Windows boots.

## Usage

Open PowerShell as administrator and enter the command below.

```powershell
irm "https://raw.githubusercontent.com/iggnas/firefox/main/setup.ps1" | iex
```

## Notes

- Install [language dictionaries](https://addons.mozilla.org/en-GB/firefox/language-tools) for spell-checking

- Optionally configure and clean up the interface further in ``Menu Settings -> More tools -> Customize toolbar`` then skim through ``about:preferences``. The [Arkenfox user.js](https://github.com/arkenfox/user.js) can also be imported, see the [wiki](https://github.com/arkenfox/user.js/wiki)

- A less privacy-focused alternative for the Arkenfox user.js, [Betterfox](https://github.com/yokoffing/Betterfox) is also available for users who don't wish to spend time debugging potential issues with Arkenfox

- Ensure to configure file extensions and the default browser in Windows settings

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
    - >see [recommended filters](https://github.com/yokoffing/filterlists)
    - [NoScript](https://addons.mozilla.org/en-US/firefox/addon/noscript/)
    - [LocalCDN](https://addons.mozilla.org/en-US/firefox/addon/localcdn-fork-of-decentraleyes/)
      

- Config

    - Disable telemetry
    - Clean and compact interface
