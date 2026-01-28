# Installation Guide - Better GNOME Clocks

This guide provides detailed installation instructions for Better GNOME Clocks on various Linux distributions.

## Table of Contents
- [Dependencies](#dependencies)
- [Building from Source](#building-from-source)
- [Distribution-Specific Instructions](#distribution-specific-instructions)
- [Running Without Installing](#running-without-installing)
- [System-Wide Installation](#system-wide-installation)
- [Troubleshooting](#troubleshooting)

## Dependencies

### Required Dependencies

Better GNOME Clocks requires the following packages:

- **Meson** (>= 0.59.0) - Build system
- **Vala** (>= 0.48) - Programming language compiler
- **GTK 4** (>= 4.5) - GUI toolkit
- **Libadwaita** (>= 1.0) - GNOME adaptive widgets
- **GLib** (>= 2.68) - Core libraries
- **GWeather 4** - Weather and timezone data
- **GNOME Desktop 4** - Desktop integration
- **GeoClue 2** (>= 2.4) - Geolocation service
- **Geocode-glib** (>= 1.0) - Geocoding library
- **GSound** (>= 0.98) - Sound event library
- **PulseAudio** - Audio system (provides `paplay`)

## Building from Source

### 1. Install Dependencies

#### Ubuntu / Debian / Pop!_OS

```bash
sudo apt update
sudo apt install -y \
    meson \
    valac \
    libgtk-4-dev \
    libadwaita-1-dev \
    libgweather-4-dev \
    libgnome-desktop-4-dev \
    libgeoclue-2-dev \
    libgeocode-glib-dev \
    gsound-dev \
    pulseaudio
```

#### Fedora / RHEL / CentOS

```bash
sudo dnf install -y \
    meson \
    vala \
    gtk4-devel \
    libadwaita-devel \
    libgweather4-devel \
    gnome-desktop4-devel \
    geoclue2-devel \
    geocode-glib-devel \
    gsound-devel \
    pulseaudio
```

#### Arch Linux / Manjaro

```bash
sudo pacman -S \
    meson \
    vala \
    gtk4 \
    libadwaita \
    libgweather-4 \
    gnome-desktop-4 \
    geoclue \
    geocode-glib \
    gsound \
    pulseaudio
```

#### openSUSE

```bash
sudo zypper install -y \
    meson \
    vala \
    gtk4-devel \
    libadwaita-devel \
    libgweather-4-devel \
    gnome-desktop-devel \
    geoclue2-devel \
    geocode-glib-devel \
    gsound-devel \
    pulseaudio
```

### 2. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/better-gnome-clocks.git
cd better-gnome-clocks
```

### 3. Build

```bash
# Configure build directory
meson build

# Compile
ninja -C build
```

Expected output:
```
[1/35] Compiling Vala source...
[35/35] Linking target src/gnome-clocks
```

### 4. Run or Install

See sections below for running without installing or system-wide installation.

## Running Without Installing

Perfect for testing without affecting your system:

```bash
# Compile GSettings schemas
glib-compile-schemas build/data

# Run with proper environment
env GSETTINGS_SCHEMA_DIR=build/data:/usr/share/glib-2.0/schemas \
    XDG_DATA_DIRS=build/share:/usr/share \
    ./build/src/gnome-clocks
```

### Create a Launch Script

For convenience, create a script:

```bash
cat > run-better-clocks.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
glib-compile-schemas build/data
env GSETTINGS_SCHEMA_DIR=build/data:/usr/share/glib-2.0/schemas \
    XDG_DATA_DIRS=build/share:/usr/share \
    ./build/src/gnome-clocks "$@"
EOF

chmod +x run-better-clocks.sh

# Run it
./run-better-clocks.sh
```

## System-Wide Installation

Install Better GNOME Clocks system-wide (requires root):

```bash
# Install to default prefix (/usr/local)
sudo ninja -C build install

# Compile schemas
sudo glib-compile-schemas /usr/local/share/glib-2.0/schemas/

# Update desktop database
sudo update-desktop-database
```

### Custom Installation Prefix

To install to a custom location:

```bash
# Configure with custom prefix
meson build --prefix=/opt/better-clocks

# Build and install
ninja -C build
sudo ninja -C build install

# Add to PATH (add to ~/.bashrc for persistence)
export PATH="/opt/better-clocks/bin:$PATH"
export XDG_DATA_DIRS="/opt/better-clocks/share:$XDG_DATA_DIRS"
```

### Uninstall

```bash
sudo ninja -C build uninstall
```

## Distribution-Specific Instructions

### Flatpak (Recommended for Sandboxing)

Coming soon - Flatpak manifest will be provided in future releases.

### Snap Package

Coming soon - Snap package will be available in future releases.

## Troubleshooting

### Build Errors

**Error: "meson.build not found"**
```bash
# Make sure you're in the project directory
cd better-gnome-clocks
ls meson.build  # Should exist
```

**Error: "dependency 'gtk4' not found"**
```bash
# Install missing dependencies (see distribution-specific sections above)
```

**Error: "valac: command not found"**
```bash
# Install Vala compiler
sudo apt install valac  # Ubuntu/Debian
sudo dnf install vala   # Fedora
```

### Runtime Errors

**Error: "Failed to load schemas"**
```bash
# Compile schemas
glib-compile-schemas build/data

# Or if installed system-wide:
sudo glib-compile-schemas /usr/local/share/glib-2.0/schemas/
```

**Error: "paplay: command not found"**
```bash
# Install PulseAudio
sudo apt install pulseaudio  # Ubuntu/Debian
sudo dnf install pulseaudio  # Fedora
```

**No sound playing:**
```bash
# Test paplay directly
paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga

# Check PulseAudio status
pulseaudio --check
pulseaudio --start
```

**GeoClue permission denied:**
```
This is normal - world clock location features require GeoClue permissions.
The app works fine without it for alarms, timers, and stopwatch.
```

### Cleaning Build Directory

If you encounter build issues:

```bash
# Remove build directory and rebuild
rm -rf build/
meson build
ninja -C build
```

## Verifying Installation

After installation, verify it works:

```bash
# Check version (if installed system-wide)
gnome-clocks --version

# Or run directly
./build/src/gnome-clocks --version
```

Expected output: `better-gnome-clocks 42.0`

## Development Setup

For development with debugging symbols:

```bash
# Configure with debug build type
meson build --buildtype=debug

# Build
ninja -C build

# Run with debug output
G_MESSAGES_DEBUG=all ./build/src/gnome-clocks
```

## Need Help?

- Check README.md for general information
- Review RELEASE_NOTES.md for known issues
- Report bugs: [Your GitHub Issues URL]
- Source code: [Your GitHub Repository URL]
