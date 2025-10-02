# Atmos Weather App 🌤️

A beautiful, feature-rich weather application built with Flutter that provides current weather conditions, forecasts, and Android home screen widgets.

## ✨ Features

- **Current Weather**: Real-time weather conditions with detailed information
- **Weather Forecast**: 3-day weather forecast with hourly breakdowns
- **Location Search**: Search for weather in any location worldwide
- **Temperature Units**: Switch between Celsius and Fahrenheit
- **Android Widgets**: Home screen widgets for quick weather access
- **Responsive Design**: Optimized for both mobile and tablet devices
- **Dark/Light Theme**: Automatic theme switching based on system preferences

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- WeatherAPI.com account and API key

### 1. Clone the Repository

```bash
git clone <repository-url>
cd atmos
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Key

#### Get Your WeatherAPI.com API Key

1. Visit [WeatherAPI.com](https://www.weatherapi.com/)
2. Sign up for a free account
3. Navigate to your dashboard and copy your API key

#### Configure Environment Variables

1. Open the `.env` file in the project root
2. Replace `YOUR_API_KEY_HERE` with your actual WeatherAPI.com API key:

```env
WEATHER_API_KEY=your_actual_api_key_here
WEATHER_API_BASE_URL=https://api.weatherapi.com/v1
```

### 4. Run the Application

#### Android

```bash
flutter run
```

#### iOS

```bash
flutter run --device-id <iOS-device-id>
```

#### Web (if supported)

```bash
flutter run -d web
```

## ⚙️ Configuration

### Environment Variables

The `.env` file contains all configurable settings:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `WEATHER_API_KEY` | Your WeatherAPI.com API key | Required |
| `WEATHER_API_BASE_URL` | WeatherAPI base URL | `https://api.weatherapi.com/v1` |
| `APP_NAME` | Application name | `Atmos Weather App` |
| `DEFAULT_TEMPERATURE_UNIT` | Default temperature unit | `celsius` |
| `DEFAULT_UPDATE_INTERVAL_MINUTES` | Weather update interval | `30` |
| `DEFAULT_LOCATION` | Default location | `Current Location` |
| `WIDGET_UPDATE_INTERVAL_MINUTES` | Widget update interval | `60` |
| `DEBUG_MODE` | Enable debug logging | `false` |

### App Configuration

The app uses a centralized configuration system located in `lib/core/config/app_config.dart`. Key settings include:

- **Weather Settings**: Cache duration, request timeout, forecast days
- **Widget Settings**: Update intervals, display options
- **UI Settings**: Animation durations, theme preferences
- **Debug Settings**: Logging levels, debug mode

## 🛠️ Development

### Project Structure

```
lib/
├── core/
│   ├── config/          # App configuration
│   └── network/         # API client and networking
├── data/
│   ├── models/          # Data models
│   ├── repositories/    # Data repositories
│   ├── services/        # Business logic services
│   └── storage/         # Local storage
├── providers/           # State management
├── ui/
│   ├── screens/         # UI screens
│   └── widgets/         # Reusable widgets
└── main.dart           # App entry point
```

### Key Components

- **WeatherProvider**: Manages weather data state
- **SettingsProvider**: Handles user preferences
- **WeatherService**: API communication layer
- **AppConfig**: Centralized configuration management

### Android Widget Setup

The app includes Android home screen widgets. To enable widgets:

1. Ensure the following permissions are in `AndroidManifest.xml`:
   - Widget provider registration
   - Widget configuration activity
   - Widget update service

2. The widget files are located in:
   - `android/app/src/main/kotlin/com/example/atmos/WeatherWidgetProvider.kt`
   - `android/app/src/main/res/xml/weather_widget_info.xml`

## 🔧 API Integration

### WeatherAPI.com Endpoints

The app uses the following WeatherAPI.com endpoints:

- **Current Weather**: `/current.json`
- **Forecast**: `/forecast.json`
- **Search**: `/search.json`

### API Key Security

- API keys are stored in environment variables
- Never commit API keys to version control
- Use `.gitignore` to exclude `.env` files
- Consider using secure storage for production apps

## 📱 Android Widgets

### Widget Features

- **4x2 Grid Size**: Default widget size
- **Current Weather**: Temperature and condition
- **Location Display**: Configurable location name
- **Auto Updates**: Background weather updates
- **Tap Actions**: Launch app from widget

### Widget Configuration

Widgets can be configured through the widget configuration activity:

- Select location for weather display
- Customize display options
- Set update preferences

## 🧪 Testing

### Running Tests

```bash
flutter test
```

### Widget Tests

The project includes widget tests for UI components:

```bash
flutter test test/
```

## 📦 Build and Release

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS Archive

```bash
flutter build ios --release
```

## 🔒 Security Considerations

- Store API keys securely using environment variables
- Implement proper error handling for API failures
- Validate user input for location searches
- Use HTTPS for all API communications
- Implement rate limiting for API calls

## 🐛 Troubleshooting

### Common Issues

1. **API Key Issues**
   - Verify API key is correct in `.env` file
   - Check WeatherAPI.com account status
   - Ensure API key has proper permissions

2. **Location Issues**
   - Check location permissions in device settings
   - Verify GPS/Network location is enabled
   - Try searching for a different location

3. **Widget Issues**
   - Ensure widget permissions are granted
   - Check AndroidManifest.xml configuration
   - Verify widget provider registration

### Debug Mode

Enable debug logging by setting `DEBUG_MODE=true` in `.env`:

```env
DEBUG_MODE=true
LOG_LEVEL=debug
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [WeatherAPI.com](https://www.weatherapi.com/) for weather data
- [Flutter](https://flutter.dev/) for the amazing framework
- Open source community for contributions and inspiration

---

**Made with ❤️ for weather enthusiasts everywhere!**
