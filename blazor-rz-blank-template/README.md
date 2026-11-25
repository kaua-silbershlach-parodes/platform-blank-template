# Blazor Blank Template with Razor UI and Silent GitHub Auto-Updates

A blank .NET 9 desktop template whose interface is built with **Blazor
and Razor components**, rendered in a lightweight native window
(Photino, on the operating system's WebView). Installed copies keep
themselves current with **silent auto-updates from GitHub Releases**
(Velopack): no wizard, no confirmation prompts, no admin rights.

## How updating works

- The app checks this repository's GitHub releases on startup
  (Velopack `GithubSource`) and downloads new versions in the
  background.
- A downloaded update applies silently on the next start, or at once
  from the **Restart to update** button in the Updates panel. There
  are no prompts at any point.
- First install is silent too: run the release's Setup with
  `--silent`:

  ```text
  BlazorBlankTemplate-win-Setup.exe --silent
  ```

  Installation is per-user (under `%LocalAppData%`), so it never asks
  for elevation.

## What is inside

The folder structure is the official `dotnet new blazor` (.NET 9)
structure, kept whole — `Components/` with layout and sample pages,
`appsettings`, `Properties/launchSettings.json`, Bootstrap under
`wwwroot/lib/` — with the web host swapped for the Photino window and
Velopack wired in.

| Path | What it is |
| --- | --- |
| `Program.cs` | Entry point: Velopack bootstrap first, then the Photino window hosting Blazor. |
| `Components/App.razor` | Root component; renders `Routes`. (In the web template this file is the HTML document; here the document is `wwwroot/index.html`.) |
| `Components/Routes.razor` | The router, with `MainLayout` as the default layout. |
| `Components/Layout/` | `MainLayout` and `NavMenu`, with their scoped CSS — the official shell. |
| `Components/Pages/Home.razor` | The start page: header with version badge, "Start here" card, and the Updates panel (state, progress, check/restart buttons, event log). |
| `Components/Pages/Counter.razor`, `Weather.razor`, `Error.razor` | The official sample pages, verbatim (one line adapted in `Error.razor`: no `HttpContext` exists in WebView hosting). |
| `Services/UpdateService.cs` | The Velopack `UpdateManager` over `GithubSource`, pointed at this repository. |
| `wwwroot/` | Host page (`index.html`), the official `app.css` and Bootstrap library, this template's `css/app.css`, and the app icon. |
| `appsettings.json`, `appsettings.Development.json`, `Properties/launchSettings.json` | The official configuration files. |
| `scripts/` | The from-scratch rebuild kit: prerequisites, clone/build, publish/pack, silent install, smoke tests. |
| `tests/` | Standalone checks for the update feed and the installed layout. |
| `icon.ico` | The application icon (window, executable, and installer). |

## Rebuild from scratch (after a format)

The `scripts/` folder rebuilds everything on a freshly formatted
machine, in the same numbered-step style as an operations kit: each
script verifies its own step and aborts on failure.

**Environment contract:** Windows 10/11 x64, internet access, winget
(App Installer) present, about 3 GB free. No accounts or credentials
are needed — the repository is public.

**Drive choice:** every script takes a mandatory `-Drive` parameter
on purpose — drive letters change per machine. The SDK, the clone,
the builds and the packed releases all live on the chosen drive
(`<Drive>:\dotnet`, `<Drive>:\BlazorTemplate`). Install on an
**internal** disk: on the reference machine that is `F:`, an internal
1 TB HDD that is always attached. One exception, by design: the app
itself installs per-user into `%LocalAppData%\BlazorBlankTemplate` —
Velopack's fixed layout, not drive-selectable.

| Step | Script | What it proves |
| --- | --- | --- |
| 1 | `scripts/01-install-prerequisites.ps1` | Git installs, the .NET 9 SDK lands on the chosen drive (`<Drive>:\dotnet`, with `DOTNET_ROOT` and PATH set at user level), and the Velopack CLI responds. |
| 2 | `scripts/02-clone-and-build.ps1` | The repository clones (or updates) and builds in Release with 0 errors. |
| 3 | `scripts/03-publish-and-pack.ps1` | A self-contained win-x64 publish packs into a full Velopack release; all six output files are present. The version is read from the `.csproj`. |
| 4 | `scripts/04-install-app.ps1` | The Setup installs with `--silent` (no prompts, per-user) and the installed layout is intact, with the version read from the installed executable. |
| 5 | `scripts/05-run-smoke-tests.ps1` | The update feed answers and parses, the app launches and stays up, and a record file lands on the Desktop. |

Standalone checks live in `tests/`: `01-update-feed-check.ps1`
(feed version vs installed version) and
`02-install-integrity-check.ps1` (installed layout).

Honest status: the procedure these scripts encode was executed
interactively end to end when the template was built (SDK install,
build, pack, release, and the app opening on a real machine). The
`.ps1` files are faithful transcriptions of that procedure and have
not yet been executed as files; a full from-format run is the real
test, exactly as with any rebuild kit.

## Run from source

```bash
dotnet run
```

Running unpackaged disables update checks (the Updates panel says
so); updates only exist in a Velopack-installed copy.

## Ship an update

1. Bump `<Version>` in `BlazorBlankTemplate.csproj`.
2. Publish and pack:

   ```bash
   dotnet publish -c Release -r win-x64 --self-contained true -o publish/win-x64
   vpk [win] pack --runtime win-x64 --packId BlazorBlankTemplate \
     --packVersion <version> --packDir publish/win-x64 \
     --mainExe BlazorBlankTemplate.exe --packTitle "Blazor Blank Template" \
     --icon icon.ico --outputDir releases/v<version>
   ```

   The `[win]` directive is what lets the pack run on Linux or macOS
   for a Windows target; on Windows it can be omitted.
3. Create a GitHub release tagged `v<version>` and upload **all**
   files from the pack output (Setup.exe, the `.nupkg`, `RELEASES`,
   `releases.win.json`, `assets.win.json`, the portable zip).
   Velopack reads the release feed from the newest release's assets.

## Requirements

- .NET 9 SDK
- The Velopack CLI: `dotnet tool install -g vpk`

## License

All rights reserved. See [LICENSE](LICENSE).
