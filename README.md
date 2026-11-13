# CountDay

CountDay is a simple iPhone app for recording daily counts. It is free, local-only, and designed for small day-by-day records such as work counts, practice counts, or checks.

[Download on the App Store](https://apps.apple.com/jp/app/countday/id6781284432)

## Features

- Today's count with increase and decrease buttons, with a lower bound of 0
- Reset today's count, with confirmation
- Daily history of days with a positive count
- About / Privacy screen
- Delete all saved count data, with confirmation
- Layout that adapts to narrow screens and landscape orientation

## Privacy

No network communication, no account, no ads, no in-app purchases, no analytics SDKs, no tracking. Counts are stored on the device in `UserDefaults`.

The privacy policy is published at https://tkdmix.com/apps/countday/support/#privacy.

## Build and Run

Requires Xcode and iOS 17.0 or later. iPhone only.

### Signing

The development team is not stored in the project. To run on a physical iPhone or archive, copy the template and set your own Apple Developer Team ID:

```sh
cp Config/Developer.xcconfig.example Config/Developer.xcconfig
```

Then edit `DEVELOPMENT_TEAM` in `Config/Developer.xcconfig`. That file is ignored by Git. To build for the iOS Simulator only, you can skip this step.

You will also need to change `PRODUCT_BUNDLE_IDENTIFIER` in the project settings to an identifier your team can use.

### Build

Open the project, select the `CountDay` scheme, and run it on an iPhone simulator or a physical iPhone:

```sh
open CountDay.xcodeproj
```

Build for the iOS Simulator from the command line:

```sh
xcodebuild -project CountDay.xcodeproj -scheme CountDay -destination 'generic/platform=iOS Simulator' build
```

## File Structure

- `CountDay/CountDayApp.swift`: SwiftUI app entry point
- `CountDay/ContentView.swift`: Main count screen, history sheet, about/privacy sheet, and persistence logic
- `CountDay/Assets.xcassets/`: App icon and accent color assets
- `Config/`: Build configuration; `Developer.xcconfig.example` is the template for local signing settings
- `web/index.html`: Support and privacy page
- `CountDay_requirements.md`: Scope, design decisions, and non-functional requirements (Japanese)

## Support

Issues and pull requests are not accepted. For support, contact support@tkdmix.com or see the [support page](https://tkdmix.com/apps/countday/support/).

## License

This project is released under the [MIT License](LICENSE).
