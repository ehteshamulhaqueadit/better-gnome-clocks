# Release Preparation Checklist for v1.1.0

## ✅ Pre-Release Steps (Complete These Before Pushing)

### 1. Clean Build Environment
```bash
# Remove old build artifacts
rm -rf build _build

# Rebuild from scratch to verify everything compiles
meson build
ninja -C build

# Test the application
./build/src/gnome-clocks
```

### 2. Verify Version Numbers
- [x] VERSION file: 1.1.0
- [x] CHANGELOG.md: v1.1.0 entry added
- [ ] meson.build: Still shows 42.0 (GNOME version - OK to keep)
- [x] README.md: Updated with v1.1.0 features

### 3. Test All New Features
- [ ] Create multiple timers
- [ ] Edit timer (check name updates)
- [ ] Delete timer from edit dialog
- [ ] Test Enter key in dialogs
- [ ] Test inline title editing with Enter
- [ ] Start multiple timers and verify queue
- [ ] Close app and verify timers continue
- [ ] Check notifications appear
- [ ] Hover over timers (visual feedback)
- [ ] Verify timer icon (not alarm icon)

### 4. Review Code Quality
- [ ] No debug print statements
- [ ] All comments are clear
- [ ] No TODO comments left unresolved
- [ ] Code follows existing style

### 5. Documentation Check
- [x] README.md updated
- [x] CHANGELOG.md updated
- [x] RELEASE_v1.1.0.md created
- [x] .gitignore updated

## 📦 Release Build Process

### Option 1: Manual Git Release (Recommended for First Time)

```bash
# 1. Check git status
git status

# 2. Stage all changes
git add .

# 3. Review what will be committed
git diff --staged

# 4. Commit with descriptive message
git commit -m "Release v1.1.0: Multiple timers support

- Add multiple timer functionality
- Implement timer queue system
- Add named timers with editing
- Enhance keyboard shortcuts
- Improve UI/UX with hover effects
- Fix various bugs

See CHANGELOG.md for full details"

# 5. Create annotated tag
git tag -a v1.1.0 -m "Release v1.1.0 - Multiple Timers

Major new feature: Multiple timers support with queue system, named timers, 
background operation, and enhanced editing capabilities."

# 6. Push to GitHub
git push origin main

# 7. Push tags
git push origin v1.1.0
```

### Option 2: Build Release Binaries (Optional)

If you want to provide pre-built binaries:

```bash
# Create release directory
mkdir -p releases/v1.1.0

# Create source tarball
git archive --format=tar.gz --prefix=better-gnome-clocks-1.1.0/ v1.1.0 > releases/v1.1.0/better-gnome-clocks-1.1.0.tar.gz

# Generate checksum
cd releases/v1.1.0
sha256sum better-gnome-clocks-1.1.0.tar.gz > better-gnome-clocks-1.1.0.tar.gz.sha256
cd ../..
```

## 🚀 GitHub Release Steps

### After Pushing Code:

1. **Go to GitHub Repository**
   - Navigate to: `https://github.com/yourusername/better-gnome-clocks/releases`

2. **Create New Release**
   - Click "Draft a new release"
   - Choose tag: `v1.1.0`
   - Release title: `v1.1.0 - Multiple Timers Support`

3. **Release Description**
   - Copy content from `RELEASE_v1.1.0.md`
   - Add screenshots if you have them
   - Highlight breaking changes (if any - none in this release)

4. **Attach Binaries (if built)**
   - Source tarball
   - SHA256 checksum file
   - Any other pre-built packages

5. **Publish**
   - Mark as "Latest release"
   - Click "Publish release"

## ⚠️ Important Notes

### Files NOT to Push to GitHub:
These are already in .gitignore:
- `build/` - Build directory
- `releases/` - Release binaries directory  
- `*.deb`, `*.rpm`, `*.flatpak` - Package files
- `*.tar.gz`, `*.tar.xz` - Archive files (except in releases)
- `*.sha256` - Checksum files
- `CLEANUP_NOTES.md`, `IMPLEMENTATION_SUMMARY.md` - Dev notes
- `GITHUB_READY.txt`, `GITHUB_RELEASE_DESCRIPTION.md` - Old files
- Build scripts: `build-*.sh`, `setup.sh`

### Files TO Push to GitHub:
- All source code (`src/`, `data/`, `po/`, `help/`)
- `README.md` - Updated with new features
- `CHANGELOG.md` - Version history
- `VERSION` - Current version
- `LICENSE.md` - License file
- `meson.build`, `meson_options.txt` - Build configuration
- `.gitignore` - Git ignore rules
- `RELEASE_v1.1.0.md` - Release notes

## 🔍 Pre-Push Verification

Run these commands before pushing:

```bash
# Check what will be committed
git status

# Check what files are tracked
git ls-files

# Verify .gitignore is working
git check-ignore -v build/
git check-ignore -v releases/

# See what would be pushed
git log origin/main..HEAD

# Verify no sensitive or binary files
git diff --stat origin/main..HEAD
```

## 📋 Post-Release Tasks

After successful release:

1. [ ] Update project website/documentation (if any)
2. [ ] Announce on social media/forums
3. [ ] Update package manager listings (AUR, Flathub, etc.)
4. [ ] Close related GitHub issues
5. [ ] Start planning next release features

## 🆘 If Something Goes Wrong

### If you pushed something by mistake:

```bash
# Remove last commit (before push)
git reset --soft HEAD~1

# Remove file from staging
git reset HEAD <file>

# Remove last tag
git tag -d v1.1.0

# Force push to remote (USE CAREFULLY!)
git push origin main --force
git push origin :v1.1.0  # Delete remote tag
```

### If build fails on clean system:

1. Check all dependencies are listed in README
2. Test on a clean VM or container
3. Update documentation with missing deps

---

## 🎯 Recommended Workflow

**For your situation, I recommend:**

1. ✅ Complete the testing checklist above
2. ✅ Review all changed files with `git diff`
3. ✅ Stage and commit with descriptive message
4. ✅ Create git tag for v1.1.0
5. ✅ Push to GitHub (main branch + tags)
6. ✅ Create GitHub release using the web interface
7. ✅ Use RELEASE_v1.1.0.md as release description
8. ⚠️ Skip building binaries for now (do manually if users request)

This way:
- No build artifacts get pushed
- Clean git history
- Professional release notes
- Easy for users to clone and build
- You can always add binaries later
