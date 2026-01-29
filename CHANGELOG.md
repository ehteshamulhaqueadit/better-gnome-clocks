# Changelog

All notable changes to Better GNOME Clocks will be documented in this file.

## [1.1.0] - 2026-01-29

### Added
- **Multiple Timers**: Create and manage multiple timers simultaneously, similar to alarm functionality
- **Timer Queue System**: Timers ring sequentially one at a time, with automatic queue processing
- **Named Timers**: Optional custom names for each timer for easy identification
- **Empty State UI**: Clean "No Timers" message with Add Timer button when no timers exist
- **Timer Editing**: Click on any stopped timer to edit its duration and name
- **Inline Title Editing**: Edit timer names directly in the timer list view
- **Delete from Edit Dialog**: Remove timers via delete button in edit dialog
- **Keyboard Shortcuts**: Press Enter to save in timer/alarm creation and editing dialogs
- **Hover Effects**: Visual feedback when hovering over timer rows
- **Timer Icon**: Distinct timer-symbolic icon in ringing modal (different from alarm icon)

### Changed
- **Timer Persistence**: Enhanced serialization to save timer state and remaining time
- **Background Operation**: Timers continue running when app is closed using hold/release pattern
- **Notification System**: System notifications appear when window is closed, with Stop button
- **Timer UI**: Redesigned timer tab with list-based layout supporting multiple timers
- **Dialog Sizing**: Compact timer dialog (480x420) with proper spacing and margins
- **Click Handling**: Smart click detection excluding buttons and entry fields from edit trigger
- **Name Display**: Timer names shown when running/paused, editable when stopped

### Fixed
- Button clicks triggering edit dialog (now properly excluded)
- Timer names not updating after editing
- Infinite loop when changing timer names
- Enter key not working in timer setup dialog
- Title field not maintaining proper spacing from dialog top
- Timer name visibility logic for different timer states

### Technical Details
- GLib.Queue for sequential timer ringing
- GLib.HashTable for duplicate timer prevention in queue
- Widget ancestry checking for proper click event filtering
- EventControllerKey with CAPTURE phase for Enter key handling
- Property binding with cycle prevention for name synchronization
- State-aware UI updates (reset/start/pause/ring states)

---

## [1.0.0] - 2026-01-28

### Added
- **Custom Timer Sounds**: Users can now select custom audio files for timer completion
- **Custom Alarm Sounds**: Users can now select custom audio files for alarms
- **Continuous Sound Looping**: Both timer and alarm sounds now loop continuously until manually stopped
- **Timer Ringing Modal**: Full-screen modal panel appears when timer completes, matching alarm UX
- **Sound Preferences UI**: New preferences dialog with Sound tab for managing custom sounds
- **Sound Preview**: Preview custom sounds before applying them
- **Sound Manager**: New backend component for managing custom sound paths via GSettings
- **Timer Ringing Panel**: New UI component matching alarm ringing panel design

### Changed
- **Sound Playback Backend**: Switched from GSound async to direct `paplay` system calls for reliability
- **Non-blocking Audio**: Implemented background thread playback to prevent UI freezing
- **Bell Class**: Enhanced with custom sound support and continuous looping capability
- **Timer Face**: Integrated sound manager and ringing panel signals
- **Window**: Added timer ringing panel display logic and signal handling
- **Project Name**: Renamed from "GNOME Clocks" to "Better GNOME Clocks"
- **Desktop Entry**: Updated application name and description

### Fixed
- Timer sound not playing when timer elapses
- UI freezing during sound playback
- Sounds stopping prematurely due to state changes
- Timer modal not appearing correctly
- Single-play timer sounds (now loops continuously)

### Technical Details
- Sound fallback chain: Custom Sound → System Sound → GSound
- Thread-safe cancellable for clean sound termination
- Process management with pkill for paplay cleanup
- Signal flow: timer-item → timer-face → window → modal display
- GSettings schema for persistent sound preferences

---

## Based on GNOME Clocks 42.0

This fork is based on GNOME Clocks version 42.0, which includes:
- GTK 4 and Libadwaita codebase
- World clocks with timezone support
- Alarms with snooze/ring duration settings
- Stopwatch with lap tracking
- Timer functionality

### Enhancements Over Original
1. Custom sound file support for both timers and alarms
2. Continuous looping sounds until user dismissal
3. Full-screen timer completion modal (like alarms)
4. Sound preferences UI with file picker and preview
5. Background thread audio playback
6. Improved reliability with direct system calls
