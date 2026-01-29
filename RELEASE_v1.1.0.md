# Better GNOME Clocks v1.1.0 - Multiple Timers Release

**Release Date:** January 29, 2026

## 🎉 What's New

This release brings the most requested feature: **Multiple Timers Support**! You can now create and manage multiple timers simultaneously, just like the alarm functionality.

## ✨ Major Features

### Multiple Timers
- Create unlimited timers running at the same time
- Each timer operates independently
- Clean list-based UI showing all your timers
- Empty state with helpful "Add Timer" prompt

### Named Timers
- Give each timer a custom name (optional)
- Names appear when timer is running or paused
- Easily identify what each timer is for
- Edit names anytime from the edit dialog or inline

### Smart Timer Queue
- Timers ring sequentially, one at a time
- Automatic queue processing
- No overlapping sounds or notifications
- Next timer starts ringing after you stop the current one

### Background Operation
- Timers continue running when app is closed
- System notifications appear with Stop button
- State persists across app restarts
- Never lose track of your timers

### Enhanced Editing
- Click any stopped timer to edit it
- Edit duration, name, and settings
- Delete button in edit dialog
- Inline name editing with Enter key support

### Better UX
- Hover effects on timer rows
- Keyboard shortcuts (Enter to save)
- Proper spacing and modern design
- Distinct timer icon (not alarm icon)
- Click handling that respects buttons

## 🔧 Technical Improvements

- Queue-based timer management using GLib.Queue
- Enhanced serialization for state persistence
- Smart click detection with widget ancestry checking
- EventControllerKey with CAPTURE phase for reliable Enter key handling
- Property binding with infinite loop prevention
- Hold/release pattern for background app operation

## 📦 Installation

### From Source
```bash
git clone https://github.com/yourusername/better-gnome-clocks.git
cd better-gnome-clocks
meson build
ninja -C build
sudo ninja -C build install
```

### Dependencies
- GTK 4.5+
- Libadwaita 1.0+
- GLib 2.68+
- GSound 0.98+
- Vala compiler

## 🐛 Bug Fixes

- Fixed: Button clicks no longer trigger edit dialog
- Fixed: Timer names now update correctly after editing
- Fixed: Infinite loop when changing timer names
- Fixed: Enter key now works reliably in all dialogs
- Fixed: Title field spacing in dialog
- Fixed: Timer name visibility in different states

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete details.

## 🙏 Credits

Based on GNOME Clocks 42.0 by the GNOME Team.

## 📄 License

GPL-2.0-or-later

---

**Previous Release:** [v1.0.0](https://github.com/yourusername/better-gnome-clocks/releases/tag/v1.0.0) - Custom Sounds
