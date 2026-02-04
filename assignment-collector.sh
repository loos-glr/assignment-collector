#!/bin/zsh

# ==============================================================================
# GLR ASSIGNMENT COLLECTOR - GUI EDITION (v11)
# Uses 'osascript' to generate native macOS dialogs
# ==============================================================================

cd "$(dirname "$0")"

# --- CONFIG ---
DEFAULT_TARGET_BASE="$HOME/Downloads/GLR_NAKIJKEN"
ICON_NOTE="📝"
ICON_ALERT="⚠️"
ICON_ERROR="❌"

# --- GUI FUNCTIES (APPLE SCRIPT WRAPPERS) ---

# 1. Toon een Finder kies-venster voor mappen
gui_choose_folder() {
    local prompt="$1"
    # We vragen System Events om de focus te pakken, anders opent het venster achter de huidige app
    osascript -e "tell application \"System Events\" to activate" \
              -e "tell application \"System Events\" to return POSIX path of (choose folder with prompt \"$prompt\")" 2>/dev/null
}

# 2. Toon een lijst waaruit gekozen moet worden
gui_choose_from_list() {
    local prompt="$1"
    local title="$2"
    shift 2
    local options=("$@")
    
    # Zsh array omzetten naar AppleScript string: {"Optie 1", "Optie 2"}
    # We escapen dubbele quotes in de opties voor de zekerheid
    local applescript_list="{"
    for opt in "${options[@]}"; do
        # Escape quotes inside option
        clean_opt="${opt//\"/\\\"}"
        applescript_list="$applescript_list\"$clean_opt\","
    done
    # Verwijder laatste komma en sluit af
    applescript_list="${applescript_list%,}}"
    
    osascript -e "tell application \"System Events\" to activate" \
              -e "choose from list $applescript_list with title \"$title\" with prompt \"$prompt\"" 2>/dev/null
}

# 3. Simpele alert / notificatie
gui_alert() {
    local msg="$1"
    osascript -e "display dialog \"$msg\" buttons {\"OK\"} default button \"OK\" with icon note" >/dev/null
}

gui_notification() {
    local msg="$1"
    local title="$2"
    osascript -e "display notification \"$msg\" with title \"$title\""
}

# --- HULPFUNCTIE: PAD SCHOONMAKEN ---
clean_path() {
    local input_path="$1"
    input_path="${input_path/#\~/$HOME}" 
    input_path="${input_path//\\/}"      
    input_path="${input_path//\"/}"        
    input_path="${input_path//\'/}"
    input_path="${input_path## }" 
    input_path="${input_path%% }" 
    echo "$input_path"
}

# ==============================================================================
# START LOGICA
# ==============================================================================

# CHECK 1: Drag & Drop (Argument Modus)
if [ -n "$1" ]; then
    # BATCH MODUS (Geen GUI vragen, gewoon gaan)
    CURRENT_SOURCE=$(clean_path "$1")
    CURRENT_TARGET="$DEFAULT_TARGET_BASE"
    BATCH_MODE=true
else
    # GUI MODUS
    BATCH_MODE=false
    
    # Stap A: Vraag Bronmap
    CURRENT_SOURCE=$(gui_choose_folder "Selecteer de map 'Submitted files' van de klas:")
    
    if [ -z "$CURRENT_SOURCE" ]; then
        # Gebruiker drukte op Annuleren
        exit 0
    fi
    
    # Stap B: Vraag Doelmap (Optioneel, we kunnen ook default pakken om clicks te besparen)
    # Laten we voor idiot-proof de default pakken, maar wel melden.
    CURRENT_TARGET="$DEFAULT_TARGET_BASE"
fi

# Validatie
if [ ! -d "$CURRENT_SOURCE" ]; then
    gui_alert "❌ Fout: De gekozen map bestaat niet of is onleesbaar."
    exit 1
fi

# ==============================================================================
# SCANNEN
# ==============================================================================

# Scan opdrachten (find command blijft hetzelfde)
ASSIGNMENT_LIST_RAW=$(find "$CURRENT_SOURCE" -mindepth 2 -maxdepth 2 -type d \
    -not -name "Version*" \
    -not -name "Versie*" \
    -not -name "RecycleBin" \
    -not -path '*/.*' \
    -exec basename {} \; | sort | uniq)

if [ -z "$ASSIGNMENT_LIST_RAW" ]; then
    gui_alert "❌ Geen opdrachten gevonden in deze map.\n\nCheck of je de 'Submitted files' map hebt gekozen."
    exit 1
fi

# ==============================================================================
# SELECTIE & VERWERKING
# ==============================================================================

ASSIGNMENTS_TO_PROCESS=""

if [ "$BATCH_MODE" = true ]; then
    # Batch: Alles verwerken
    ASSIGNMENTS_TO_PROCESS="$ASSIGNMENT_LIST_RAW"
else
    # GUI: Laat lijst zien
    # We moeten de newline-separated string omzetten naar een array voor onze functie
    IFS=$'\n' read -d '' -r -A ASSIGNMENT_ARRAY <<< "$ASSIGNMENT_LIST_RAW"
    
    CHOICE=$(gui_choose_from_list "Welke opdracht wil je ophalen?" "GLR Collector" "${ASSIGNMENT_ARRAY[@]}")
    
    if [ "$CHOICE" = "false" ] || [ -z "$CHOICE" ]; then
        exit 0 # Annuleren
    fi
    
    ASSIGNMENTS_TO_PROCESS="$CHOICE"
fi

# ==============================================================================
# DE LOOP (Kopiëren)
# ==============================================================================

# Feedback tijdens processen is lastig met AppleScript dialogs (die blokkeren).
# We sturen een notificatie dat we begonnen zijn.
if [ "$BATCH_MODE" = false ]; then
    gui_notification "Bestanden worden verzameld..." "GLR Collector"
fi

echo "$ASSIGNMENTS_TO_PROCESS" | while read ASSIGNMENT_NAME; do
    [ -z "$ASSIGNMENT_NAME" ] && continue

    DESTINATION="$CURRENT_TARGET/$ASSIGNMENT_NAME"
    mkdir -p "$DESTINATION"
    
    find "$CURRENT_SOURCE" -maxdepth 1 -mindepth 1 -type d | while read STUDENT_DIR; do
        STUDENT_NAME=$(basename "$STUDENT_DIR")
        ASSIGNMENT_PATH="$STUDENT_DIR/$ASSIGNMENT_NAME"

        if [ -d "$ASSIGNMENT_PATH" ]; then
            STUDENT_TARGET="$DESTINATION/$STUDENT_NAME"
            mkdir -p "$STUDENT_TARGET"

            # Versie logic
            LATEST_VERSION_DIR=$(find "$ASSIGNMENT_PATH" -maxdepth 1 -type d \( -name "Version*" -o -name "Versie*" \) | sort -V | tail -n 1)
            if [ -n "$LATEST_VERSION_DIR" ]; then SRC_PATH="$LATEST_VERSION_DIR/"; else SRC_PATH="$ASSIGNMENT_PATH/"; fi

            rsync -a \
                --exclude 'node_modules' --exclude '.git' --exclude '.DS_Store' --exclude '__MACOSX' \
                "$SRC_PATH" "$STUDENT_TARGET/"

            ZIPFILE=$(find "$STUDENT_TARGET" -maxdepth 1 -name "*.zip" | head -n 1)
            if [ -n "$ZIPFILE" ]; then
                unzip -q -o "$ZIPFILE" -d "$STUDENT_TARGET" && rm "$ZIPFILE"
            fi
        fi
    done
done

# ==============================================================================
# KLAAR
# ==============================================================================

if [ "$BATCH_MODE" = false ]; then
    # Native popup
    BUTTON=$(osascript -e "display dialog \"✅ Klaar! De bestanden staan in Downloads.\" buttons {\"Open Map\", \"OK\"} default button \"OK\" with icon note")
    
    # Check of ze op "Open Map" klikten (AppleScript output is: button returned:Open Map)
    if [[ "$BUTTON" == *"Open Map"* ]]; then
        open "$CURRENT_TARGET"
    fi
else
    # In batch mode (drag drop) openen we gewoon
    open "$CURRENT_TARGET"
fi