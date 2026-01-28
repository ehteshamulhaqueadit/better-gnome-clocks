# Better GNOME Clocks v1.0.0 Release Notes

**Release Date:** January 28, 2026

## Overview

Better GNOME Clocks is an enhanced fork of GNOME Clocks 42.0 that adds custom sound support, continuous looping audio, and improved timer notifications. This release brings a more personalized and reliable alarm/timer experience to GNOME users.

## Highlights

### 🎵 Custom Sounds
Set your own audio files (.ogg, .mp3, .wav) for both timers and alarms. No more being limited to system sounds!

### 🔄 Continuous Looping
Both alarm and timer sounds now loop continuously until you manually stop them. No more missing alarms because the sound only played once.

### ⏲️ Timer Modal Panel
Timers now show a full-screen modal panel (like alarms) when they complete, making it impossible to miss a finished timer.

### ⚙️ Easy Configuration
New Sound preferences tab with file picker and preview functionality. Test your custom sounds before applying them.

## What's New

### Features
- **Custom Timer Sounds** with file browser
- **Custom Alarm Sounds** with file browser  
- **Sound Preview** in preferences
- **Continuous Audio Looping** for both timers and alarms
- **Timer Ringing Modal** with Stop button
- **Non-blocking Audio** using background threads

### User Experience
- Consistent UX between alarms and timers (both show modal panels)
- No more UI freezing during sound playback
- Reliable sound playback using direct system calls
- Automatic fallback to system sounds if custom sound unavailable

### Technical Improvements
- Background thread audio playback
- Direct `paplay` integration for reliability
- Thread-safe cancellation for clean shutdown
- Proper process cleanup
- GSettings integration for persistent preferences

## Installation

### From Source

```bash
# Install dependencies
sudo apt install meson valac libgtk-4-dev libadwaita-1-dev \
    libgweather-4-dev libgnome-desktop-4-dev libgeoclue-2-dev \
    libgeocode-glib-dev gsound-dev

# Build
meson build
ninja -C build

# Run
glib-compile-schemas build/data
env GSETTINGS_SCHEMA_DIR=build/data:/usr/share/glib-2.0/schemas \
    XDG_DATA_DIRS=build/share:/usr/share \
    ./build/src/gnome-clocks

# Install system-wide (optional)
sudo ninja -C build install
```

## Quick Start

1. **Open Better GNOME Clocks**
2. **Set Custom Sound:**
   - Click menu (⋮) → Preferences
   - Go to Sound tab
   - Choose file for Timer/Alarm
   - Click Preview to test
3. **Create Timer/Alarm:**
   - Set up timer or alarm as usual
   - When it triggers, your custom sound loops continuously
4. **Stop Sound:**
   - Click Stop button in modal panel

## System Requirements

- GTK 4.5 or later
- Libadwaita 1.0 or later
- GLib 2.68 or later
- GWeather 4.0
- GNOME Desktop 4.0
- PulseAudio (for `paplay` command)

## Known Issues

- None at this time

## Upgrading from GNOME Clocks

Better GNOME Clocks uses the same settings schema as GNOME Clocks, so your existing alarms, timers, and world clocks will be preserved. Custom sound preferences are stored separately.

## Credits

- **Original GNOME Clocks**: GNOME Project
- **Better GNOME Clocks Enhancements**: Custom sound support and improved UX

## Support

- Report issues: [Your GitHub Issues URL]
- Source code: [Your GitHub Repository URL]

## License

GPL-2.0-or-later (same as GNOME Clocks)

---

Thank you for trying Better GNOME Clocks! We hope these enhancements improve your GNOME experience.
