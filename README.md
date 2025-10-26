# MovieMemo iOS App

A comprehensive personal movie tracking application built with SwiftUI and SwiftData, allowing users to log watched movies, manage a watchlist, and view detailed statistics about their viewing habits.

## 🎯 Features

### Core Functionality
- **Watched Movies Management**: Log movies with detailed information including ratings, spending, location, companions, and more
- **Watchlist Management**: Keep track of movies you want to watch with priority levels and target dates
- **Comprehensive Statistics**: View analytics about your viewing habits, spending patterns, and preferences
- **Data Import/Export**: Backup and restore your data with JSON import/export functionality

### Key Capabilities
- **Multi-language Support**: Support for English and 10 Indian languages (Telugu, Hindi, Tamil, Kannada, Malayalam, Bengali, Marathi, Gujarati, Punjabi)
- **Advanced Filtering & Sorting**: Filter by location type, sort by various criteria
- **Rich Analytics**: Track spending, viewing habits, genre preferences, and more
- **Intuitive UI**: Clean, modern interface following iOS design guidelines

## 🏗️ Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture with the following components:

### Models
- `WatchedEntry`: Core model for logged movies
- `WatchlistItem`: Model for watchlist items
- `Genre`: Model for movie genres
- Supporting enums: `LocationType`, `TimeOfDay`, `Language`

### Views
- `MainTabView`: Main navigation container
- `WatchedMoviesView`: Movies list and management
- `WatchlistView`: Watchlist management
- `StatisticsView`: Analytics dashboard
- `SettingsView`: App settings and data management
- `AddEditMovieView`: Form for adding/editing movies
- `AddEditWatchlistItemView`: Form for watchlist items

### ViewModels
- `WatchedMoviesViewModel`: Manages watched movies state and operations
- `WatchlistViewModel`: Handles watchlist functionality
- `StatisticsViewModel`: Calculates and manages statistics

### Repository
- `MovieRepository`: Data access layer using SwiftData

## 📱 Screenshots

The app features a clean, intuitive interface with:
- Tab-based navigation (Watched, Watchlist, Statistics, Settings)
- Search and filtering capabilities
- Rich movie entry forms with all required and optional fields
- Comprehensive statistics dashboard with visual charts
- Data management tools for import/export

## 🛠️ Technical Details

### Requirements
- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

### Dependencies
- SwiftUI for UI
- SwiftData for data persistence
- Combine for reactive programming

### Data Storage
- Uses SwiftData with SQLite backend
- Automatic data migration support
- Efficient querying and filtering

## 🚀 Getting Started

1. Open `MovieMemo.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

## 📊 Data Models

### WatchedEntry
Tracks comprehensive movie viewing information:
- Basic info: title, watch date, rating, language
- Location details: type, notes, theater name, city
- Personal details: companions, notes, genre
- Financial: amount spent (stored in cents)
- Technical: duration, poster URI

### WatchlistItem
Manages movies to watch:
- Title and language
- Priority level (High/Medium/Low)
- Optional target date and notes

## 🎨 UI/UX Features

- **Material Design 3** principles adapted for iOS
- **Dark/Light mode** support
- **Accessibility** compliance
- **Responsive design** for different screen sizes
- **Emoji-based icons** for visual appeal
- **Smooth animations** and transitions

## 📈 Statistics & Analytics

The app provides comprehensive analytics including:
- Total movies watched and monthly trends
- Spending analysis (total, monthly, average theater spend)
- Viewing habits (weekday vs weekend, time of day)
- Content analysis (genres, languages, companions)
- Location preferences and patterns

## 🔧 Data Management

- **Export**: Complete data export in JSON format
- **Import**: Restore data from JSON files
- **Clear Data**: Options to clear watched movies or watchlist
- **Data Validation**: Ensures data integrity during import/export

## 🧪 Testing

The app is designed with testability in mind:
- MVVM architecture enables easy unit testing
- Repository pattern allows for mock data testing
- ViewModels can be tested independently
- SwiftData models support in-memory testing

## 📝 License

This project is created for personal use and learning purposes.

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

---

Built with ❤️ using SwiftUI and SwiftData

