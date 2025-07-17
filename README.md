# ClaudNotes

<div align="center">
  <img src="ClaudNotes/Assets.xcassets/AppIcon.appiconset/Icon-1024.png" alt="ClaudNotes Logo" width="200"/>
  <h3>AI-Powered Note-Taking for iOS</h3>
</div>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#roadmap">Roadmap</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

ClaudNotes is a modern, AI-powered note-taking app for iOS built with SwiftUI. It combines the simplicity and elegance of Apple Notes with powerful AI features and YouTube content extraction. Perfect for students, professionals, and anyone who wants to take their note-taking to the next level.

## Features

### Core Note-Taking
- Create and edit notes with a clean, intuitive interface
- Organize notes with folders and tags
- Pin important notes for quick access
- Search across all your notes

### AI-Powered Features
- Generate summaries from your notes
- Create flashcards for studying
- Generate quizzes to test your knowledge
- Format notes in Cornell Notes style
- Create Q&A pairs from your content

### YouTube Integration
- Extract transcripts from YouTube videos
- Automatically create notes from video content
- Process video content with AI features

### Modern UI
- Beautiful glassmorphic design
- Dark mode support
- Grid and list views for notes
- Smooth animations and transitions
- Apple Human Interface Guidelines compliant

### Data Insights
- View statistics about your notes
- Track your note-taking habits
- See content type distribution
- Get tag recommendations

## Screenshots

<div align="center">
  <table>
    <tr>
      <td><img src="Screenshots/screenshot1.png" alt="Notes List" width="250"/></td>
      <td><img src="Screenshots/screenshot2.png" alt="Note Detail" width="250"/></td>
      <td><img src="Screenshots/screenshot3.png" alt="AI Features" width="250"/></td>
    </tr>
    <tr>
      <td align="center">Notes List</td>
      <td align="center">Note Detail</td>
      <td align="center">AI Features</td>
    </tr>
    <tr>
      <td><img src="Screenshots/screenshot4.png" alt="YouTube Integration" width="250"/></td>
      <td><img src="Screenshots/screenshot5.png" alt="Insights" width="250"/></td>
      <td><img src="Screenshots/screenshot6.png" alt="Tags & Folders" width="250"/></td>
    </tr>
    <tr>
      <td align="center">YouTube Integration</td>
      <td align="center">Insights</td>
      <td align="center">Tags & Folders</td>
    </tr>
  </table>
</div>

> Note: You'll need to add actual screenshots to the Screenshots folder after pushing to GitHub.

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `ClaudNotes.xcodeproj` in Xcode
3. Build and run the app on your device or simulator

## Configuration

### API Keys
To use all features, you'll need to configure the following API keys:

1. **Gemini API Key**: For AI-powered features
   - Get a key from [Google AI Studio](https://ai.google.dev/)
   - Add it in the app settings

2. **YouTube API Key**: For YouTube transcript extraction
   - Get a key from [Google Cloud Console](https://console.cloud.google.com/)
   - Enable the YouTube Data API v3
   - Add it in the app settings

## Architecture

ClaudNotes follows the MVVM (Model-View-ViewModel) architecture:

- **Models**: Data structures for notes, blocks, folders, and tags
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and data management

### Project Structure

```
ClaudNotes/
├── Model.swift                 # Core data models
├── ViewModels/
│   └── NotesViewModel.swift    # Main view model
├── Views/
│   ├── MainTabView.swift       # Main navigation structure
│   ├── NotesListView.swift     # List of notes
│   ├── NoteDetailView.swift    # Note editing view
│   ├── FoldersView.swift       # Folder management
│   ├── TagsView.swift          # Tag management
│   ├── InsightsView.swift      # Analytics and insights
│   ├── YouTubeInputView.swift  # YouTube integration
│   └── ...                     # Other view components
├── Services/
│   ├── GeminiService.swift     # AI service integration
│   └── YouTubeService.swift    # YouTube API integration
└── Extensions/
    └── ColorExtension.swift    # Utility extensions
```

## Roadmap

- [ ] **Cloud Sync**: Implement iCloud sync for notes across devices
- [ ] **Collaboration**: Add sharing and collaboration features
- [ ] **Web Clipper**: Create a Safari extension for saving web content
- [ ] **Advanced AI**: Implement more AI-powered features
- [ ] **Widgets**: Add home screen widgets for quick access
- [ ] **Shortcuts Integration**: Add support for Siri Shortcuts
- [ ] **macOS Version**: Create a macOS companion app

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Google Gemini API](https://ai.google.dev/)
- [YouTube Data API](https://developers.google.com/youtube/v3)