using Velopack;
using Velopack.Sources;

namespace BlazorBlankTemplate.Services;

/// <summary>
/// GitHub Releases auto-update via Velopack. Updates download in the
/// background and apply silently: no wizard, no confirmation prompts,
/// no admin rights (per-user install). The Velopack Setup.exe also
/// installs silently with --silent.
/// </summary>
public sealed class UpdateService
{
    private const string RepoUrl =
        "https://github.com/kaua-silbershlach-parodes/platform-blank-template";

    private readonly UpdateManager _manager = new(new GithubSource(RepoUrl, null, false));

    /// <summary>True when running from a Velopack install (not a loose build).</summary>
    public bool IsInstalled => _manager.IsInstalled;

    public string CurrentVersion =>
        _manager.CurrentVersion?.ToString()
        ?? typeof(UpdateService).Assembly.GetName().Version?.ToString(3)
        ?? "dev";

    public Task<UpdateInfo?> CheckForUpdatesAsync() => _manager.CheckForUpdatesAsync();

    public Task DownloadUpdatesAsync(UpdateInfo update, Action<int> progress) =>
        _manager.DownloadUpdatesAsync(update, progress);

    public void ApplyUpdatesAndRestart(UpdateInfo update) =>
        _manager.ApplyUpdatesAndRestart(update);
}
