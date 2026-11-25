import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.aeliteestrangeira.capacitorblanktemplate',
  appName: 'Capacitor Blank Template',
  webDir: 'www',
  plugins: {
    CapacitorHttp: {
      // Route fetch/XHR through the native HTTP stack. Required: the
      // update manifest is served from GitHub's asset host, which sends
      // no CORS headers, so a WebView fetch() is blocked ("Failed to
      // fetch"). Native HTTP has no CORS.
      enabled: true,
    },
    CapacitorUpdater: {
      // Manual mode: the app itself checks GitHub Releases
      // (releases/latest/download/latest.json) and drives the plugin's
      // download/set API. No update server, no cloud account.
      autoUpdate: false,
      appId: 'com.aeliteestrangeira.capacitorblanktemplate',
      statsUrl: '',
    },
  },
};

export default config;
