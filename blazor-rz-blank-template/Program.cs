using BlazorBlankTemplate.Components;
using BlazorBlankTemplate.Services;
using Microsoft.Extensions.DependencyInjection;
using Photino.Blazor;
using Velopack;

namespace BlazorBlankTemplate;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        // Velopack must run first: it handles install/update hooks and
        // exits the process itself when invoked by the installer.
        VelopackApp.Build().Run();

        var builder = PhotinoBlazorAppBuilder.CreateDefault(args);
        builder.Services.AddSingleton<UpdateService>();
        builder.RootComponents.Add<App>("app");

        var app = builder.Build();
        app.MainWindow
            .SetTitle("Blazor Blank Template")
            .SetSize(1100, 760)
            .Center();
        try
        {
            app.MainWindow.SetIconFile("icon.ico");
        }
        catch
        {
            // The icon is cosmetic; never block startup on it.
        }

        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
        {
            app.MainWindow.ShowMessage("Fatal exception", e.ExceptionObject.ToString() ?? "");
        };

        app.Run();
    }
}
