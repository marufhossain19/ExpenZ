import '../core/config.dart';

/// Placeholder service for OpenWeatherMap API integration.
/// TODO: Add http dependency and implement when ready.
///
/// This service will provide:
/// - Current weather data
/// - Weather-based spending insights (e.g., "Rainy day? Perfect for saving!")
/// - Location-based weather for contextual tips
class WeatherService {
  bool get isEnabled => AppConfig.isWeatherEnabled;

  /// Fetch current weather for a location
  /// Returns a map with weather data or null if disabled/error
  ///
  /// TODO: Implement with:
  /// ```dart
  /// final url = '${AppConfig.openWeatherBaseUrl}/weather'
  ///     '?q=$city&appid=${AppConfig.openWeatherApiKey}&units=metric';
  /// final response = await http.get(Uri.parse(url));
  /// ```
  Future<Map<String, dynamic>?> getCurrentWeather(String city) async {
    if (!isEnabled) return null;
    // TODO: Implement API call
    return null;
  }

  /// Get a spending tip based on current weather
  /// e.g., "It's sunny outside — go for a walk instead of an Uber!"
  String getWeatherSpendingTip(String? weatherCondition) {
    switch (weatherCondition?.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        return '🌧️ Rainy day — perfect excuse to stay home and save money!';
      case 'clear':
      case 'sunny':
        return '☀️ Beautiful day! Walk instead of taking a ride — your wallet will thank you.';
      case 'snow':
        return '❄️ Snowy weather — grab that home-made hot cocoa instead of Starbucks!';
      case 'clouds':
        return '☁️ Cloudy mood? Don\'t let emotional spending cloud your budget too!';
      default:
        return '💡 Track every expense, no matter the weather!';
    }
  }
}
