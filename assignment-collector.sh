#!/bin/zsh

# ==============================================================================
# GLR ASSIGNMENT COLLECTOR - GUI EDITION (v15 - Bulletproof ZIP Extraction)
# --- LOGGING ---
LOG_FILE="$HOME/Library/Logs/GLR_Collector.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=============================================================================="
echo "GLR ASSIGNMENT COLLECTOR STARTED AT $(date)"
echo "=============================================================================="

# ==============================================================================

cd "$(dirname "$0")"

# --- CONFIG ---
DEFAULT_TARGET_BASE="$HOME/Downloads/GLR_NAKIJKEN"

# --- GUI FUNCTIES ---

gui_choose_folder() {
    local prompt="$1"
    osascript -e "on run argv" -e "return POSIX path of (choose folder with prompt (item 1 of argv))" -e "end run" "$prompt" 2>/dev/null
}

gui_choose_from_list() {
    local prompt="$1"
    local title="$2"
    shift 2
    local options=("$@")
    
    osascript -e "on run argv" \
              -e "tell application \"System Events\" to activate" \
              -e "choose from list (items 3 thru -1 of argv) with title (item 2 of argv) with prompt (item 1 of argv)" \
              -e "end run" \
              "$prompt" "$title" "${options[@]}" 2>/dev/null
}

gui_alert() {
    local msg="$(printf "%b" "$1")"
    osascript -e "on run argv" -e "display dialog (item 1 of argv) buttons {\"OK\"} default button \"OK\" with icon note" -e "end run" "$msg" >/dev/null
}

gui_notification() {
    local msg="$1"
    local title="$2"
    osascript -e "on run argv" -e "display notification (item 1 of argv) with title (item 2 of argv)" -e "end run" "$msg" "$title" 2>/dev/null
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

if [ $# -gt 0 ]; then
    BATCH_MODE=true
    SOURCES=()
    for arg in "$@"; do
        SOURCES+=("$(clean_path "$arg")")
    done
else
    BATCH_MODE=false
    GUI_SOURCE=$(gui_choose_folder "Selecteer de map 'Submitted files' van de klas:")
    
    if [ -z "$GUI_SOURCE" ]; then exit 0; fi
    SOURCES=("$GUI_SOURCE")
fi

CURRENT_TARGET="$DEFAULT_TARGET_BASE"

for CURRENT_SOURCE in "${SOURCES[@]}"; do
    if [ ! -d "$CURRENT_SOURCE" ]; then
        gui_alert "❌ Fout: De gekozen map '$CURRENT_SOURCE' bestaat niet of is onleesbaar."
        continue
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
        if [ "$BATCH_MODE" = false ]; then
            gui_alert "❌ Geen opdrachten gevonden in deze map.\n\nCheck of je de 'Submitted files' map hebt gekozen."
        fi
        continue
    fi

    # ==============================================================================
    # SELECTIE
    # ==============================================================================

    ASSIGNMENTS_TO_PROCESS=""

    if [ "$BATCH_MODE" = true ]; then
        ASSIGNMENTS_TO_PROCESS="$ASSIGNMENT_LIST_RAW"
    else
        ASSIGNMENT_ARRAY=("${(@f)ASSIGNMENT_LIST_RAW}")
        CHOICE=$(gui_choose_from_list "Welke opdracht wil je ophalen?" "GLR Collector" "${ASSIGNMENT_ARRAY[@]}")
        
        if [ "$CHOICE" = "false" ] || [ -z "$CHOICE" ]; then continue; fi
        ASSIGNMENTS_TO_PROCESS="$CHOICE"
    fi

    # ==============================================================================
    # VERWERKING (Kopiëren, Samenvoegen & Uitpakken)
    # ==============================================================================

    if [ "$BATCH_MODE" = false ]; then
        gui_notification "Bestanden worden verzameld..." "GLR Collector"
    fi

echo "PROGRESS: 0"
echo "DETAILS: Lijsten inlezen..."

ASSIGNMENT_LINES=("${(@f)ASSIGNMENTS_TO_PROCESS}")
TOTAL_ASSIGNMENTS=0
for a in "${ASSIGNMENT_LINES[@]}"; do
    [ -n "$a" ] && ((TOTAL_ASSIGNMENTS++))
done

FIND_OUTPUT=$(find "$CURRENT_SOURCE" -maxdepth 1 -mindepth 1 -type d)
STUDENT_LINES=("${(@f)FIND_OUTPUT}")
TOTAL_STUDENTS=0
for s in "${STUDENT_LINES[@]}"; do
    [ -n "$s" ] && ((TOTAL_STUDENTS++))
done

TOTAL_STEPS=$(( TOTAL_ASSIGNMENTS * TOTAL_STUDENTS ))
if [ "$TOTAL_STEPS" -eq 0 ]; then
    TOTAL_STEPS=1
fi

CURRENT_STEP=0

for ASSIGNMENT_NAME in "${ASSIGNMENT_LINES[@]}"; do
    [ -z "$ASSIGNMENT_NAME" ] && continue

    DESTINATION="$CURRENT_TARGET/$ASSIGNMENT_NAME"
    mkdir -p "$DESTINATION"
    
    for STUDENT_DIR in "${STUDENT_LINES[@]}"; do
        [ -z "$STUDENT_DIR" ] && continue

        STUDENT_NAME=$(basename "$STUDENT_DIR")
        
        ((CURRENT_STEP++))
        PCT=$(( 100 * CURRENT_STEP / TOTAL_STEPS ))
        echo "PROGRESS: $PCT"
        echo "DETAILS: $ASSIGNMENT_NAME ($STUDENT_NAME)"

        ASSIGNMENT_PATH="$STUDENT_DIR/$ASSIGNMENT_NAME"

            if [ -d "$ASSIGNMENT_PATH" ]; then
                STUDENT_TARGET="$DESTINATION/$STUDENT_NAME"
                mkdir -p "$STUDENT_TARGET"

                # STAP 1: Kopieer de basisbestanden (maar negeer Version/Versie mappen nog even)
                rsync -a \
                    --exclude 'node_modules' --exclude '.git' --exclude '.DS_Store' --exclude '__MACOSX' \
                    --exclude 'Version*' --exclude 'Versie*' \
                    "$ASSIGNMENT_PATH/" "$STUDENT_TARGET/"

                # STAP 2: Zoek alle versie mappen, sorteer op versie-nummer (met de Zsh 'n' glob qualifier), en kopieer ze eroverheen.
                for VERSION_DIR in "$ASSIGNMENT_PATH"/(Version*|Versie*)(Nn/); do
                    rsync -a \
                        --exclude 'node_modules' --exclude '.git' --exclude '.DS_Store' --exclude '__MACOSX' \
                        "$VERSION_DIR/" "$STUDENT_TARGET/"
                done

                # STAP 3: Bulletproof ZIP uitpakken (-iname negeert .ZIP hoofdletters, -print0 snapt spaties)
                find "$STUDENT_TARGET" -type f -iname "*.zip" -print0 | while IFS= read -r -d '' ZIPFILE; do
                    ZIPDIR="$(dirname "$ZIPFILE")"
                    unzip -q -o "$ZIPFILE" -d "$ZIPDIR" && rm "$ZIPFILE"
                done
                
            fi
    done
done
done

echo "PROGRESS: 100"
echo "DETAILS: Klaar!"

# ==============================================================================
# KLAAR
# ==============================================================================

if [ "$BATCH_MODE" = false ]; then
    # Native popup
    BUTTON=$(osascript -e "on run argv" -e "display dialog (item 1 of argv) buttons {\"Open Map\", \"OK\"} default button \"OK\" with icon note" -e "end run" "✅ Klaar! De bestanden staan in Downloads.")
    
    # Check of ze op "Open Map" klikten
    if [[ "$BUTTON" == *"Open Map"* ]]; then
        open "$CURRENT_TARGET"
    fi
else
    open "$CURRENT_TARGET"
fi