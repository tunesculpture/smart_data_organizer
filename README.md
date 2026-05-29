# Smart Data Organizer v3

## What Changed in This Version

### Bug Fixes
| Bug | Fix |
|---|---|
| Data going into one cell | Parser fully rewritten — proper separator scoring + Key\|Value extraction |
| Paste text stuck on loading | `PopScope(canPop:false)` + correct `didChangeDependencies` listener |
| Can't go back from some pages | All screens use standard AppBar back button; parsing uses PopScope |
| Theme not changing | `Consumer<SettingsProvider>` wraps `MaterialApp` directly |
| App not saving to storage | Saves to `Downloads/SmartDataOrganizer/` with permission request |

### New Features
| Feature | Detail |
|---|---|
| No built-in API key | User must set their own OpenAI key in Settings |
| Smart AI — minimal tokens | AI receives only 5 sample rows, detects schema, applies locally to ALL rows |
| API key warning | Home screen banner + import/paste warning when key not set |
| Custom API key UI | Prominent Settings section with show/hide toggle |
| City detection | Delhi/Mumbai/Kolkata correctly detected as City, not Name |
| Unique headers | Duplicate column types get numbered (Name 1, Name 2) |
| Excel cell types | Handles Text, Int, Double, Bool Excel cells properly |

## Setup
```bash
flutter pub get
flutter run
```

## Add Your OpenAI API Key
Open app → Settings → AI Parser → **Add API Key**  
Get your key from: https://platform.openai.com/api-keys

## How AI Works (Minimal Token Usage)
1. Sends only **5 sample rows** to OpenAI
2. AI detects: separator, column names, column types
3. Schema applied **locally** to all rows — no more API calls
4. Result: same quality, fraction of the cost

## Replace AdMob Test IDs
In `lib/core/constants/app_constants.dart`:
```dart
static const String admobAppId           = 'YOUR_REAL_APP_ID';
static const String bannerAdUnitId       = 'YOUR_REAL_BANNER_ID';
static const String interstitialAdUnitId = 'YOUR_REAL_INTERSTITIAL_ID';
```
And in `android/app/src/main/AndroidManifest.xml` update the AdMob meta-data value.

## Parser Examples
```
Input:  Rahul Sharma, Delhi, 9876543210, rahul@gmail.com
Output: Name | City | Phone | Email

Input:  B001~Rahul~Delhi~CheckIn|01-03-2026~CheckOut|03-03-2026~Guests|2~4500~Confirmed
Output: ID | Name | City | Check In | Check Out | Guests | Amount | Status
```
