# Astrotools

`Astrotools` is a small iPhone app for practical astronomy helpers.

Current tools:
- `Collimation`: live camera view with draggable concentric-circle overlay for Newtonian telescope collimation.
- `Flat Panel`: full-screen light panel for capturing flats, with brightness control and a few simple color presets.

## Features

- Native iOS app built with `SwiftUI` and `AVFoundation`
- Adjustable collimation overlay with draggable center and circle radius sliders
- Flat panel brightness control that also drives device screen brightness
- Simple flat-panel presets: white, light gray, mid gray, warm white
- Tap anywhere on the flat panel to hide or show the interface
- Keeps the screen awake while the flat panel tool is active

## Project Layout

- `NewtonianCollimator/`: app source files
- `NewtonianCollimator.xcodeproj/`: Xcode project

## Running

1. Open `NewtonianCollimator.xcodeproj` in Xcode.
2. Select an iPhone simulator or a real iPhone.
3. Build and run.

For the collimation tool on a real device, camera permission is required.

## Notes

- The flat panel tool reapplies the chosen brightness while active and restores the previous brightness when you leave the tool.
- iOS does not provide a hard disable for system auto-brightness behavior, so screen brightness holding is best-effort from within the app.
