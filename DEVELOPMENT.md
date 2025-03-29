# Development Guidelines

## SwiftUI Best Practices

### Colors and Styling
- Use `NSColor` for macOS apps, not `UIColor`
- Always use the full namespace: `Color(NSColor.windowBackgroundColor)` instead of `.systemBackground`
- For custom colors, define them in a dedicated Color extension

### Views and Data Flow
- Use `Identifiable` for list/grid items to ensure stable identifiers
- Prefer `@StateObject` for view models that should persist
- Use `@Published` for observable properties
- Always handle potential nil/error cases in bindings
- Use `@FocusState` for managing text field focus
- Handle keyboard shortcuts at the root view level

### File Operations
- Always use security-scoped resource access
- Use `defer` for cleanup of security-scoped resources
- Handle all potential file operation errors
- Validate file contents before processing
- Set hasUnsavedChanges flag when modifying document

## Project Structure

### Models
- Keep models in separate files under Models directory
- Models should be immutable where possible
- Use value types (structs) for data models
- Use reference types (classes) for shared state

### Views
- Keep view files focused on a single responsibility
- Extract reusable components into separate views
- Use extensions to organize view code
- Follow consistent naming: `ComponentNameView`

### Testing
- Write unit tests for all model logic
- Test edge cases and error conditions
- Use meaningful test names that describe the scenario
- Mock file operations and heavy I/O in tests
- Test keyboard shortcuts and user interactions

## Error Handling
- Define custom errors in an extension of `LocalizedError`
- Provide meaningful error messages
- Handle all potential error cases
- Use `Result` type for complex operations

## Code Style
- Use clear, descriptive variable names
- Keep functions small and focused
- Document complex logic or business rules
- Use Swift's type inference where appropriate

## Common Types and Constants

### Color References
```swift
extension Color {
    static let background = Color(NSColor.windowBackgroundColor)
    static let text = Color(NSColor.labelColor)
    static let accent = Color(NSColor.controlAccentColor)
    static let border = Color(NSColor.separatorColor)
}
```

### View Constants
```swift
enum ViewConstants {
    static let defaultPadding: CGFloat = 8
    static let cellMinWidth: CGFloat = 100
    static let borderWidth: CGFloat = 0.5
}
```

### File Types
```swift
extension UTType {
    static var commaSeparatedText: UTType {
        UTType.types(tag: "csv",
                    tagClass: .filenameExtension,
                    conformingTo: .text).first ?? .plainText
    }
}
```

## Common Issues and Solutions

1. **SwiftUI View Updates**
   - Problem: Views not updating when data changes
   - Solution: Ensure proper use of @Published and ObservableObject
   - Solution: Set hasUnsavedChanges when modifying document state

2. **File Access**
   - Problem: File permission errors
   - Solution: Always use security-scoped resource access
   - Solution: Handle file access errors gracefully

3. **Memory Management**
   - Problem: Memory leaks with closures
   - Solution: Use [weak self] in closures where appropriate
   - Solution: Properly clean up event monitors and observers

4. **Performance**
   - Problem: Slow updates with large datasets
   - Solution: Use LazyVStack/LazyHStack for large tables
   - Solution: Batch updates when modifying multiple cells

5. **Keyboard Shortcuts**
   - Problem: Shortcuts not working consistently
   - Solution: Use .keyboardShortcut for menu items
   - Solution: Add NSEvent monitor for global shortcuts
   - Solution: Handle shortcut conflicts properly

6. **Text Field Focus**
   - Problem: Text fields not getting focus
   - Solution: Use @FocusState to manage focus
   - Solution: Handle focus changes in onAppear/onDisappear

## Building and Releasing

### Development Build
1. Open project in Xcode
2. Select "Debug" configuration
3. Build and run (Cmd + R)

### Automated Release Process
The project uses GitHub Actions for automated releases. Here's how it works:

1. Push your changes to the main branch
2. Create and push a new version tag:
   ```bash
   git tag v1.0.0  # Use semantic versioning
   git push origin v1.0.0
   ```
3. The GitHub Action will automatically:
   - Run all tests
   - If tests pass:
     - Build the app without code signing
     - Create a GitHub release
     - Generate release notes
     - Upload the built app as SimpleCSV-[version].zip
   - If tests fail:
     - The workflow stops
     - No release is created

### Managing Release Tags
If tests fail or you need to update the release:

1. Delete the local tag:
   ```bash
   git tag -d v1.0.0
   ```

2. Delete the remote tag:
   ```bash
   git push --delete origin v1.0.0
   ```

3. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Fix tests"
   ```

4. Create and push a new tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

### Manual Release (if needed)
1. Run tests:
   ```bash
   xcodebuild test -scheme simple-csv -destination 'platform=macOS'
   ```

2. If tests pass, build without code signing:
   ```bash
   xcodebuild -scheme simple-csv -configuration Release build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
   ```

3. The app will be in `build/Release/simple-csv.app`

### Installation Instructions
1. Download SimpleCSV-[version].zip from the latest GitHub release
2. Unzip the file
3. Move SimpleCSV.app to Applications folder
4. Right-click and select Open (first time only)
5. If you see a security warning, go to System Settings > Privacy & Security and click 'Open Anyway'

### System Requirements
- macOS 11.0 or later
- 64-bit processor
- 50MB disk space

### Release Workflow Details
The automated release process is configured in `.github/workflows/release.yml` and includes:
- Triggers on version tags (v*)
- Uses macos-latest runner
- Updates version from git tag
- Builds app without code signing
- Creates GitHub release with release notes
- Uploads the app bundle

To modify the release process:
1. Edit `.github/workflows/release.yml`
2. Commit and push changes
3. Create a new tag to test the workflow

### Security Note
The app is distributed without code signing, which means:
- Users will need to right-click and select "Open" on first launch
- macOS will show a security warning
- This is normal for open-source apps without Apple Developer accounts
- The source code is available for verification
