#!/bin/zsh

# ==============================================================================
# GLR ASSIGNMENT COLLECTOR - GUI EDITION (v13 - Smart Merge & Overwrite)
# ==============================================================================

cd "$(dirname "$0")"

# --- CONFIG ---
DEFAULT_TARGET_BASE="$HOME/Downloads/GLR_NAKIJKEN"

# --- GUI FUNCTIES ---

gui_choose_folder() {
    local prompt="$1"
    osascript -e "return POSIX path of (choose folder with prompt \"$prompt\")" 2>/dev/null
}

gui_choose_from_list() {
    local prompt="$1"
    local title="$2"
    shift 2
    local options=("$@")
    
    local applescript_list="{"
    for opt in "${options[@]}"; do
        clean_opt="${opt//\"/\\\"}"
        applescript_list="$applescript_list\"$clean_opt\","
    done
    applescript_list="${applescript_list%,}}"
    
    osascript -e "tell application \"System Events\" to activate" \
              -e "choose from list $applescript_list with title \"$title\" with prompt \"$prompt\"" 2>/dev/null
}

gui_alert() {
    local msg="$1"
    osascript -e "display dialog \"$msg\" buttons {\"OK\"} default button \"OK\" with icon note" >/dev/null
}

gui_notification() {
    local msg="$1"
    local title="$2"
    osascript -e "display notification \"$msg\" with title \"$title\""
}

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

if [ -n "$1" ]; then
    CURRENT_SOURCE=$(clean_path "$1")
    CURRENT_TARGET="$DEFAULT_TARGET_BASE"
    BATCH_MODE=true
else
    BATCH_MODE=false
    CURRENT_SOURCE=$(gui_choose_folder "Selecteer de map 'Submitted files' van de klas:")
    
    if [ -z "$CURRENT_SOURCE" ]; then exit 0; fi
    CURRENT_TARGET="$DEFAULT_TARGET_BASE"
fi

if [ ! -d "$CURRENT_SOURCE" ]; then
    gui_alert "❌ Fout: De gekozen map bestaat niet of is onleesbaar."
    exit 1
fi

# ==============================================================================
# SCANNEN
# ==============================================================================

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
# SELECTIE
# ==============================================================================

ASSIGNMENTS_TO_PROCESS=""

if [ "$BATCH_MODE" = true ]; then
    ASSIGNMENTS_TO_PROCESS="$ASSIGNMENT_LIST_RAW"
else
    IFS=$'\n' read -d '' -r -A ASSIGNMENT_ARRAY <<< "$ASSIGNMENT_LIST_RAW"
    CHOICE=$(gui_choose_from_list "Welke opdracht wil je ophalen?" "GLR Collector" "${ASSIGNMENT_ARRAY[@]}")
    if [ "$CHOICE" = "false" ] || [ -z "$CHOICE" ]; then exit 0; fi
    ASSIGNMENTS_TO_PROCESS="$CHOICE"
fi

# ==============================================================================
# VERWERKING (Kopiëren, Samenvoegen & Uitpakken)
# ==============================================================================

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

            # STAP 1: Kopieer de basisbestanden (maar negeer Version/Versie mappen nog even)
            rsync -a \
                --exclude 'node_modules' --exclude '.git' --exclude '.DS_Store' --exclude '__MACOSX' \
                --exclude 'Version*' --exclude 'Versie*' \
                "$ASSIGNMENT_PATH/" "$STUDENT_TARGET/"

            # STAP 2: Zoek alle versie mappen, sorteer op versie-nummer (-V), en kopieer ze eroverheen.
            # Oudere bestanden worden zo automatisch overschreven door de nieuwere bestanden.
            find "$ASSIGNMENT_PATH" -maxdepth 1 -type d \( -name "Version*" -o -name "Versie*" \) | sort -V | while read VERSION_DIR; do
                [ -z "$VERSION_DIR" ] && continue
                
                rsync -a \
                    --exclude 'node_modules' --exclude '.git' --exclude '.DS_Store' --exclude '__MACOSX' \
                    "$VERSION_DIR/" "$STUDENT_TARGET/"
            done

            # STAP 3: Zips uitpakken in deze samengevoegde map (overschrijft zonder te vragen)
            find "$STUDENT_TARGET" -type f -name "*.zip" | while read ZIPFILE; do
                ZIPDIR="$(dirname "$ZIPFILE")"
                unzip -q -o "$ZIPFILE" -d "$ZIPDIR" && rm "$ZIPFILE"
            done
            
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