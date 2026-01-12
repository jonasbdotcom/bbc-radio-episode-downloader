#!/bin/bash

# BBC Episode Downloader
# Version: 2.6.0
# Last updated: 2026-01-12
# Fixed: Decodes HTML entities in titles and metadata

set -e

VERSION="2.6.0"

if [ -z "$1" ]; then
    echo "BBC Episode Downloader v${VERSION}"
    echo ""
    echo "Usage: $0 <programme_id>"
    echo "Example: $0 b01q9qgc"
    exit 1
fi

PROGRAMME_ID="$1"
DOWNLOAD_DIR="."

# Function to decode HTML entities
decode_html() {
    local text="$1"
    # Common HTML entities
    text="${text//&quot;/\"}"
    text="${text//&apos;/\'}"
    text="${text//&#039;/\'}"
    text="${text//&lt;/<}"
    text="${text//&gt;/>}"
    text="${text//&amp;/&}"
    text="${text//&#8217;/\'}"
    text="${text//&#8216;/\'}"
    text="${text//&nbsp;/ }"
    text="${text//&#x27;/\'}"
    echo "$text"
}

# Check dependencies
for cmd in curl yt-dlp; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd not found"
        exit 1
    fi
done

# Check for tagging tool
if command -v AtomicParsley &> /dev/null; then
    TAGGER="atomicparsley"
elif command -v ffmpeg &> /dev/null; then
    TAGGER="ffmpeg"
else
    echo "Error: Need AtomicParsley or ffmpeg"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "BBC Episode Downloader v${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get episode list
echo "[1/3] Fetching episode list..."
EPISODE_LIST_HTML=$(curl -s "https://www.bbc.co.uk/programmes/${PROGRAMME_ID}/episodes/player")
EPISODE_IDS=$(echo "$EPISODE_LIST_HTML" | grep -o 'sounds/play/[a-z0-9]*' | sed 's/sounds\/play\///' | sort -u)

if [ -z "$EPISODE_IDS" ]; then
    echo "      No episodes found"
    exit 0
fi

TOTAL_EPISODES=$(echo "$EPISODE_IDS" | wc -l)
echo "      Found $TOTAL_EPISODES episode(s)"
echo ""

# Build a map of LISTED_ID -> ACTUAL_ID
echo "[2/3] Resolving actual episode IDs..."
declare -A ID_MAP
ACTUAL_IDS=""

for LISTED_ID in $EPISODE_IDS; do
    echo -n "      Checking $LISTED_ID... "
    ACTUAL_ID=$(yt-dlp --get-filename -o "%(id)s" "https://www.bbc.co.uk/programmes/${LISTED_ID}" 2>/dev/null)
    
    if [ -z "$ACTUAL_ID" ]; then
        echo "failed to resolve"
        continue
    fi
    
    # Store the mapping: ACTUAL_ID -> LISTED_ID
    ID_MAP[$ACTUAL_ID]=$LISTED_ID
    
    if [ "$LISTED_ID" != "$ACTUAL_ID" ]; then
        echo "→ $ACTUAL_ID"
    else
        echo "OK"
    fi
    
    ACTUAL_IDS="${ACTUAL_IDS}${ACTUAL_ID}"$'\n'
done

# Remove empty lines
ACTUAL_IDS=$(echo "$ACTUAL_IDS" | grep -v '^$')

if [ -z "$ACTUAL_IDS" ]; then
    echo "      No valid episodes found"
    exit 0
fi

echo ""
echo "[3/3] Downloading new episodes..."
NEW_COUNT=0
SKIPPED_COUNT=0

for ACTUAL_ID in $ACTUAL_IDS; do
    # Check if already downloaded (using ACTUAL ID in filename)
    if ls "$DOWNLOAD_DIR"/*"[${ACTUAL_ID}]"*.m4a 2>/dev/null | grep -q .; then
        echo "      ⊘ $ACTUAL_ID - Already downloaded"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi
    
    # Get the LISTED ID for downloading
    DOWNLOAD_ID=${ID_MAP[$ACTUAL_ID]}
    
    NEW_COUNT=$((NEW_COUNT + 1))
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Episode $NEW_COUNT: $ACTUAL_ID"
    if [ "$DOWNLOAD_ID" != "$ACTUAL_ID" ]; then
        echo "(Download URL: $DOWNLOAD_ID)"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get episode page HTML (use ACTUAL ID for metadata)
    echo "  → Getting episode metadata..."
    EPISODE_HTML=$(curl -sL "https://www.bbc.co.uk/programmes/${ACTUAL_ID}")
    
    # Check if we got a redirect message
    if echo "$EPISODE_HTML" | grep -q "Redirecting to"; then
        REDIRECT_ID=$(echo "$EPISODE_HTML" | grep -o 'Redirecting to /programmes/[a-z0-9]*' | sed 's/Redirecting to \/programmes\///')
        if [ -n "$REDIRECT_ID" ]; then
            echo "  → Following HTML redirect to $REDIRECT_ID..."
            EPISODE_HTML=$(curl -sL "https://www.bbc.co.uk/programmes/${REDIRECT_ID}")
        fi
    fi
    
    # Extract metadata
    PAGE_TITLE=$(echo "$EPISODE_HTML" | grep -o '<title>[^<]*</title>' | sed 's/<title>\(.*\)<\/title>/\1/')
    SHOW_TITLE=$(echo "$PAGE_TITLE" | sed 's/^[^-]* - \([^,]*\),.*/\1/')
    EPISODE_TITLE=$(echo "$PAGE_TITLE" | sed 's/^[^,]*, \(.*\)/\1/')
    DESCRIPTION=$(echo "$EPISODE_HTML" | grep -o '<meta name="description" content="[^"]*"' | sed 's/.*content="\([^"]*\)".*/\1/')
    STATION=$(echo "$EPISODE_HTML" | grep -o '<meta property="article:author" content="[^"]*"' | sed 's/.*content="\([^"]*\)".*/\1/')
    if [ -z "$STATION" ]; then
        STATION="BBC"
    fi
    BROADCAST_DATE=$(echo "$EPISODE_HTML" | grep -o 'content="[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T' | head -1 | sed 's/content="\([^T]*\)T/\1/')
    if [ -z "$BROADCAST_DATE" ]; then
        BROADCAST_DATE=$(date +%Y-%m-%d)
    fi
    
    # Decode HTML entities
    SHOW_TITLE=$(decode_html "$SHOW_TITLE")
    EPISODE_TITLE=$(decode_html "$EPISODE_TITLE")
    DESCRIPTION=$(decode_html "$DESCRIPTION")
    STATION=$(decode_html "$STATION")
    
    echo "  → Show: $SHOW_TITLE"
    echo "  → Episode: $EPISODE_TITLE"
    echo "  → Description: $DESCRIPTION"
    echo "  → Station: $STATION"
    echo "  → Date: $BROADCAST_DATE"
    
    # Download audio using the LISTED ID (not the actual ID)
    echo "  → Downloading audio..."
    if ! yt-dlp -f bestaudio \
           --extract-audio \
           --audio-format m4a \
           --audio-quality 0 \
           --no-playlist \
           --quiet \
           --progress \
           -o "%(title)s [%(id)s].%(ext)s" \
           "https://www.bbc.co.uk/programmes/${DOWNLOAD_ID}"; then
        echo "  ✗ Download failed"
        continue
    fi
    
    # Find the file - use ls instead of find (more reliable with special chars)
    # Give it a moment to finish writing
    sleep 1
    
    AUDIO_FILE=""
    for file in "$DOWNLOAD_DIR"/*"[$ACTUAL_ID]".m4a; do
        if [ -f "$file" ]; then
            AUDIO_FILE="$file"
            break
        fi
    done
    
    if [ -z "$AUDIO_FILE" ] || [ ! -f "$AUDIO_FILE" ]; then
        echo "  ✗ File not found"
        echo "  ✗ Looking for: *[${ACTUAL_ID}].m4a"
        echo "  ✗ Files in directory:"
        ls -1 "$DOWNLOAD_DIR"/*.m4a 2>/dev/null | tail -3
        continue
    fi
    
    echo "  → Downloaded: $(basename "$AUDIO_FILE")"
    
    # Create clean filename
    CLEAN_NAME="${BROADCAST_DATE}_${SHOW_TITLE// /_}_${EPISODE_TITLE// /_}"
    CLEAN_NAME=$(echo "$CLEAN_NAME" | sed 's/[^A-Za-z0-9_-]/_/g' | sed 's/__*/_/g')
    FINAL_FILE="${CLEAN_NAME}_[${ACTUAL_ID}].m4a"
    
    # Handle existing file
    if [ -f "$FINAL_FILE" ]; then
        FINAL_FILE="${CLEAN_NAME}_$(date +%H%M%S)_[${ACTUAL_ID}].m4a"
    fi
    
    # Rename
    echo "  → Renaming to: $(basename "$FINAL_FILE")"
    mv "$AUDIO_FILE" "$FINAL_FILE"
    
    # Tag
    echo "  → Tagging..."
    if [ "$TAGGER" = "atomicparsley" ]; then
        AtomicParsley "$FINAL_FILE" \
          --artist "$SHOW_TITLE" \
          --title "$EPISODE_TITLE" \
          --comment "$DESCRIPTION" \
          --year "${BROADCAST_DATE:0:4}" \
          --album "$SHOW_TITLE" \
          --albumArtist "$STATION" \
          --stik "Podcast" \
          --overWrite >/dev/null 2>&1
        rm -f "${FINAL_FILE}-temp"
    else
        TEMP_FILE="temp_${ACTUAL_ID}.m4a"
        ffmpeg -i "$FINAL_FILE" \
          -metadata artist="$SHOW_TITLE" \
          -metadata title="$EPISODE_TITLE" \
          -metadata comment="$DESCRIPTION" \
          -metadata date="${BROADCAST_DATE:0:4}" \
          -metadata album="$SHOW_TITLE" \
          -metadata album_artist="$STATION" \
          -codec copy \
          -loglevel error \
          "$TEMP_FILE" 2>/dev/null
        mv "$TEMP_FILE" "$FINAL_FILE"
    fi
    
    echo "  ✓ Complete!"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total: $TOTAL_EPISODES | Downloaded: $NEW_COUNT | Skipped: $SKIPPED_COUNT"
echo ""
