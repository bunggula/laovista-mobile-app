class AppConfig {
  // Local development
  static const String devBase = "https://green-partridge-895292.hostingersite.com";

  // Cloudflare Tunnel
  static const String tunnelBase = "https://green-partridge-895292.hostingersite.com";

  // Piliin mo kung alin gagamitin (devBase o tunnelBase)
  static const String base = tunnelBase;

  // API endpoint
  static const String apiBaseUrl = "$base/api";

  // Storage endpoint (for images)
  static const String storageBaseUrl = "$base/storage";
}
