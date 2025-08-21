# SL-NIC-Bridge Flutter Application

A production-quality Flutter application designed to streamline the Sri Lankan National Identity Card (NIC) application process. Built with modern Flutter architecture, Material 3 design system, and comprehensive state management.

## 🏗️ Architecture Overview

The application follows a feature-first architecture with clean separation of concerns:

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root MaterialApp configuration
└── src/
    ├── core/                 # Core app logic
    │   ├── config/           # Configuration management
    │   ├── constants/        # App constants and routes
    │   ├── networking/       # API client and networking
    │   ├── router/           # Navigation configuration
    │   └── theme/            # Theme management
    ├── features/             # Feature modules
    │   ├── auth/             # Authentication (login/register)
    │   ├── application/      # NIC application management
    │   └── settings/         # User settings
    └── shared/               # Shared components
        ├── screens/          # Common screens
        └── widgets/          # Reusable widgets
```

## 🚀 Key Features

### 🔐 Authentication System
- **JWT-based authentication** with secure token storage
- **Registration** with full name, email, password, and Grama Niladari Division
- **Login** with email and password
- **Automatic token refresh** and error handling
- **Secure storage** using flutter_secure_storage

### 📋 Dynamic Multi-Step Application Form
- **Configuration-driven** form structure loaded from backend
- **Multi-step wizard** interface with progress indicators
- **Comprehensive validation** with custom validation rules
- **Multiple field types**: text, email, date, radio, checkbox, file, signature
- **Custom signature component** with draw and upload capabilities
- **Real-time validation** with user-friendly error messages

### 📊 Application Status & Dashboard
- **Intelligent dashboard** showing application status
- **Workflow visualization** with progress tracking
- **Conditional UI** based on application state:
  - No application: Start new application button
  - Pending: View status card with disabled new application
  - Rejected: Show rejection details with retry option
  - Approved: Success confirmation
- **Application workflow** with step-by-step progress tracking

### ⚙️ Settings & Profile Management
- **Theme management** (Light, Dark, System) with persistence
- **Profile editing** capabilities
- **Password change** functionality
- **App information** display
- **Privacy policy** and Terms of Service links
- **Secure logout** with token cleanup

## 🎨 Design System

### Material 3 Implementation
- **Seed color theming** from configuration file
- **Dynamic color schemes** for light and dark modes
- **Consistent component styling** across the app
- **Accessible color contrasts** and typography
- **Smooth animations** and micro-interactions

### Theme Features
- **Configuration-driven** seed colors
- **Automatic theme switching** based on system settings
- **Persistent theme selection** stored locally
- **Consistent spacing** using 8px grid system
- **Modern card designs** with appropriate elevation

## 🛠️ Technical Implementation

### State Management
- **Riverpod** for dependency injection and state management
- **Async state handling** with proper loading and error states
- **Provider-based architecture** for scalable state management
- **Automatic state persistence** for user preferences

### Networking
- **Dio HTTP client** with interceptors
- **Automatic JWT token injection** for authenticated requests
- **Comprehensive error handling** with user-friendly messages
- **Request/response logging** for development
- **Base response models** for consistent API communication

### Navigation
- **go_router** for type-safe navigation
- **Route guards** for authentication protection
- **Deep linking** support
- **Programmatic navigation** with proper state management

### Data Persistence
- **flutter_secure_storage** for sensitive data (tokens)
- **shared_preferences** for user preferences
- **JSON serialization** with code generation
- **Type-safe data models** with proper validation

## 📦 Dependencies

### Core Dependencies
```yaml
flutter_riverpod: ^2.4.9          # State management
go_router: ^12.1.3                # Navigation
dio: ^5.4.0                       # HTTP client
flutter_secure_storage: ^9.0.0    # Secure storage
shared_preferences: ^2.2.2        # Local preferences
json_annotation: ^4.8.1           # JSON serialization
```

### UI & Media Dependencies
```yaml
signature: ^5.4.0                 # Signature capture
image_picker: ^1.0.4              # Image selection
package_info_plus: ^4.2.0         # App information
material_symbols_icons: ^4.2719.3 # Extended icons
intl: ^0.18.1                     # Internationalization
```

### Development Dependencies
```yaml
build_runner: ^2.4.7              # Code generation
json_serializable: ^6.7.1         # JSON code generation
flutter_lints: ^3.0.0             # Linting rules
```

## 🏃‍♂️ Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio or VS Code with Flutter extensions
- iOS development setup (for iOS deployment)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sl_nic_bridge
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate required files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure the application**
   - Update `assets/config/config.json` with your API endpoints
   - Ensure proper API backend is configured and running

5. **Run the application**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Development Commands

```bash
# Generate code files
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch for changes and auto-generate
flutter packages pub run build_runner watch

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .
```

## 🔧 Configuration

### App Configuration (`assets/config/config.json`)
```json
{
  "apiBaseUrl": "https://your-api-endpoint.com/v1",
  "jwtStorageKey": "sl_nic_bridge_auth_token",
  "theme": {
    "seedColorLight": "#1A5A96",
    "seedColorDark": "#5E9ED6"
  },
  "appVersion": "1.0.0",
  "supportEmail": "support@yourapp.com",
  "privacyPolicyUrl": "https://yourapp.com/privacy",
  "termsOfServiceUrl": "https://yourapp.com/terms"
}
```

### Environment Setup
- **Development**: Uses configuration from `assets/config/config.json`
- **Production**: Same configuration file with production API endpoints
- **Theme**: Configurable seed colors for brand customization

## 🧪 Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Business logic validation
- Provider state management
- Utility functions

### Widget Tests
- Form validation logic
- UI component behavior
- Navigation flows
- State changes

### Integration Tests
- End-to-end user flows
- Authentication processes
- Form submission workflows
- API integration

## 📱 Platform Support

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest
- Supports all screen sizes and densities
- Material 3 design implementation

### iOS
- Minimum iOS version: 12.0
- Supports iPhone and iPad
- Adaptive UI for different screen sizes
- Follows iOS design guidelines while maintaining Material 3 aesthetics

## 🔒 Security Features

### Data Protection
- **JWT tokens** stored in secure storage
- **Password hashing** on backend
- **Input validation** and sanitization
- **Secure HTTP** communication only

### Authentication Security
- **Token expiration** handling
- **Automatic logout** on token expiry
- **Secure password requirements**
- **Session management** with proper cleanup

## 📊 Performance Optimization

### App Performance
- **Lazy loading** of screens and resources
- **Efficient state management** with Riverpod
- **Optimized builds** with proper widget rebuilds
- **Memory management** with proper disposal

### Network Optimization
- **Request/response caching** where appropriate
- **Efficient JSON serialization**
- **Proper error handling** and retry mechanisms
- **Network-aware UI** with loading states

## 🤝 Contributing

### Development Guidelines
1. Follow the established architecture patterns
2. Maintain consistent code formatting
3. Write comprehensive tests for new features
4. Update documentation for API changes
5. Follow Material 3 design guidelines

### Code Style
- Use `flutter format` for consistent formatting
- Follow Dart naming conventions
- Maintain proper documentation comments
- Keep functions focused and single-purpose

## 🐛 Troubleshooting

### Common Issues

**Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**State Management Issues**
- Ensure providers are properly scoped
- Check for memory leaks with provider disposal
- Verify async state handling

**Navigation Problems**
- Confirm route definitions in app_router.dart
- Check authentication guards
- Verify context usage in navigation calls

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- Riverpod for powerful state management
- Material 3 design system for modern UI guidelines
- Open source community for valuable packages

---

**Built with ❤️ using Flutter**