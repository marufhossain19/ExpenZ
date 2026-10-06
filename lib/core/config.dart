/// Configuration file for external API keys and service URLs.
/// Replace placeholder values with your actual credentials.
library;

class AppConfig {
  // ── Supabase ──────────────────────────────────────────────
  /// Supabase project URL
  static const String supabaseUrl = 'https://fqowzxffpwgdtplzjkbs.supabase.co';

  /// Supabase anon/public key (JWT format starting with eyJ...)
  /// Get this from: Supabase Dashboard → Settings → API → anon public key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxb3d6eGZmcHdnZHRwbHpqa2JzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NjY5NzUsImV4cCI6MjA5NDI0Mjk3NX0.ASLiLSg1mE9_wIPn3lAwZTqS9sNnKqviC_iZ_17et4c';

  // ── OpenWeather API ───────────────────────────────────────
  /// TODO: Replace with your OpenWeatherMap API key
  static const String openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';

  /// Base URL for OpenWeather API
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // ── Feature Flags ─────────────────────────────────────────
  /// Set to true once Supabase credentials are configured
  static const bool isSupabaseEnabled = true;

  /// Set to true once OpenWeather API key is configured
  static const bool isWeatherEnabled = false;
}
