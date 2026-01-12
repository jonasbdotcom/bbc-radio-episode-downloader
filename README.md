# BBC Radio Episode Downloader

Automatically download BBC Radio episodes with full metadata tagging. Works with any BBC radio programme.

## Features

- 🎵 Downloads all available episodes from any BBC programme
- 📝 Extracts metadata from episode pages (title, description, date, station)
- 🏷️ Tags M4A files with AtomicParsley or ffmpeg
- 📅 Renames files with broadcast date and proper titles
- 🔄 Handles BBC's redirect system automatically
- ✅ Skips already-downloaded episodes (no duplicates)
- 🌐 Decodes HTML entities in titles (e.g., `&#039;` → `'`)

## Requirements

- `curl` - For fetching episode metadata
- `yt-dlp` - For downloading audio
- `AtomicParsley` OR `ffmpeg` - For tagging M4A files

### Installation (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt update
sudo apt install curl yt-dlp atomicparsley

# Or if you prefer ffmpeg for tagging
sudo apt install curl yt-dlp ffmpeg
```

### Installation (macOS)

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install yt-dlp atomicparsley

# Or if you prefer ffmpeg for tagging
brew install yt-dlp ffmpeg

# curl is already included in macOS
```

### Installation (Windows)

**Option 1: WSL (Windows Subsystem for Linux) - Recommended**

```bash
# Install WSL first (PowerShell as Administrator):
wsl --install

# Then inside WSL, follow the Ubuntu/Debian instructions above
```

**Option 2: Git Bash + Manual Installation**

1. Install [Git for Windows](https://git-scm.com/download/win) (includes Git Bash)
2. Download [yt-dlp.exe](https://github.com/yt-dlp/yt-dlp/releases/latest) and add to PATH
3. Download [AtomicParsley.exe](https://github.com/wez/atomicparsley/releases) and add to PATH
4. Use Git Bash to run the script

**Note:** The script works best on Linux/macOS or Windows WSL. Native Windows support via Git Bash may have limitations.

## Quick Start

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/yourusername/bbc-radio-downloader/main/bbc_auto_download.sh
   chmod +x bbc_auto_download.sh
   ```

2. **Find your programme ID:**
   - Go to the BBC programme page, e.g., https://www.bbc.co.uk/programmes/b01q9qgc
   - The ID is the part after `/programmes/` (in this case: `b01q9qgc`)

3. **Run the script:**
   ```bash
   ./bbc_auto_download.sh b01q9qgc
   ```

## Usage

### Basic Usage

```bash
./bbc_auto_download.sh <programme_id>
```

**Example:**
```bash
# David Rodigan (Radio 1Xtra)
./bbc_auto_download.sh b01q9qgc

# Desert Island Discs (Radio 4)
./bbc_auto_download.sh b006qnmr

# Any BBC programme
./bbc_auto_download.sh <programme_id>
```

### Output

The script will:
1. Fetch the list of available episodes
2. Resolve actual episode IDs (BBC sometimes redirects)
3. Check which episodes you already have
4. Download only new episodes
5. Tag each file with full metadata
6. Rename files to: `YYYY-MM-DD_ShowName_EpisodeTitle_[episode_id].m4a`

**Example output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BBC Episode Downloader v2.6.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/3] Fetching episode list...
      Found 6 episode(s)

[2/3] Resolving actual episode IDs...
      Checking m002pfyr... → m002pfyq
      Checking m002p8g8... OK

[3/3] Downloading new episodes...
      ⊘ m002pfyq - Already downloaded
      
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Episode 1: m002p8g7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  → Getting episode metadata...
  → Show: David Rodigan
  → Episode: The Hottest Reggae Tunes
  → Description: The best Sunday reggae vibes
  → Station: BBC Radio 1Xtra
  → Date: 2026-01-11
  → Downloading audio...
  → Downloaded: David Rodigan, The Hottest... [m002p8g7].m4a
  → Renaming to: 2026-01-11_David_Rodigan_The_Hottest_Reggae_Tunes_[m002p8g7].m4a
  → Tagging...
  ✓ Complete!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 6 | Downloaded: 1 | Skipped: 5
```

### File Output

**Filename format:**
```
2026-01-11_David_Rodigan_The_Hottest_Reggae_Tunes_[m002p8g7].m4a
```

**Metadata tags:**
- Artist: David Rodigan
- Title: The Hottest Reggae Tunes
- Album: David Rodigan
- Album Artist: BBC Radio 1Xtra
- Comment: The best Sunday reggae vibes. @1Xtra on social
- Year: 2026
- Genre: Podcast

## Automation with Cron

To automatically download new episodes every week:

```bash
# Edit your crontab
crontab -e

# Add this line to run every Monday at 6 AM
0 6 * * 1 cd /path/to/download/directory && /path/to/bbc_auto_download.sh b01q9qgc >> download.log 2>&1
```

**Cron schedule examples:**
```bash
# Every Monday at 6 AM
0 6 * * 1

# Every day at 3 PM
0 15 * * *

# Every Sunday at midnight
0 0 * * 0

# Multiple times on Mondays (7 AM, 12 PM, 4 PM, 9 PM)
0 7,12,16,21 * * 1
```

## How It Works

### BBC's Redirect System

BBC sometimes uses a complex redirect system where:
1. The episode listing page shows one ID (e.g., `m002mxyk`)
2. yt-dlp resolves it to a different ID (e.g., `m002mxyj`)
3. The HTML page might redirect again to yet another ID

This script handles all these redirects automatically by:
- Resolving the actual episode ID before checking if it exists
- Downloading using the correct URL
- Tracking files using the final episode ID in the filename

### Metadata Extraction

The script fetches the episode page HTML and extracts:
- **Show title**: From the page `<title>` tag
- **Episode title**: From the page `<title>` tag
- **Description**: From the `<meta name="description">` tag
- **Station**: From the `<meta property="article:author">` tag
- **Broadcast date**: From structured data in the HTML

### HTML Entity Decoding

The script automatically decodes HTML entities in titles:
- `&#039;` → `'`
- `&apos;` → `'`
- `&quot;` → `"`
- `&amp;` → `&`
- And more...

## Troubleshooting

### "curl returns no data"

If curl is blocked or rate-limited by BBC:
- Try adding a delay between requests
- Use a VPN if accessing from outside the UK
- Check your network's firewall settings

### "File not found after download"

This usually means the episode ID changed during download. The script handles this automatically, but if you see this error:
- Check that yt-dlp is up to date: `yt-dlp -U`
- Make sure the episode is still available on BBC

### "Download failed - 404 Not Found"

The episode might no longer be available. BBC typically keeps episodes available for 30 days after broadcast.

### AtomicParsley not tagging

Make sure AtomicParsley is installed:
```bash
which AtomicParsley
# Should return: /usr/bin/AtomicParsley (or similar)
```

If not installed:
```bash
sudo apt install atomicparsley
```

## Finding Programme IDs

1. Go to the BBC programme page
2. Look at the URL: `https://www.bbc.co.uk/programmes/PROGRAMME_ID`
3. Use the `PROGRAMME_ID` part

**Popular programmes:**
- David Rodigan: `b01q9qgc`
- Desert Island Discs: `b006qnmr`
- In Our Time: `b006qykl`
- The Archers: `b006qpgr`
- Woman's Hour: `b007qlvb`

## Version History

### v2.6.0 (2026-01-12)
- Added HTML entity decoding for titles and metadata
- Fixes apostrophes and other special characters in filenames and tags

### v2.5.1 (2026-01-12)
- Fixed file finding with better glob pattern matching
- Added sleep to ensure file write completion

### v2.5.0 (2026-01-12)
- Fixed redirect handling: downloads with listed ID, tracks with actual ID
- Added ID mapping system to handle BBC's redirect system

### v2.4.0 (2026-01-12)
- Added HTML redirect detection and following
- Improved error handling for redirect chains

### v2.3.0 (2026-01-12)
- Resolves all actual episode IDs upfront before downloading
- Handles BBC's unpredictable redirect system reliably

### v2.0.0 (2026-01-12)
- Initial release with yt-dlp metadata extraction

## License

MIT License - See LICENSE file for details

## Contributing

Issues and pull requests welcome! Please ensure:
- Test with at least 2 different BBC programmes
- Follow existing code style
- Update version number in the script

## Authors

- **Jonas** - Initial concept, requirements, and testing
- **Claude (Anthropic)** - Code implementation and development

This project was developed through an iterative collaboration, with Jonas providing real-world testing and feedback on BBC's systems, and Claude implementing the solutions.

## Acknowledgments

- Built with `yt-dlp` for downloading
- Uses `AtomicParsley` for M4A tagging
- Inspired by the need to archive BBC Radio shows
