#!/bin/bash

############################################
# 1. Ordnername eingeben
############################################
echo "Insert Folder Name To Save The PDFs In:"
read folder

mkdir -p "${folder}"

logfile="${folder}/convert.log"
touch "$logfile"

echo "==== Convert-Log ====" >> "$logfile"
echo "Start: $(date +"%Y-%m-%d_%H-%M-%S")" >> "$logfile"
echo "Target: ${folder}" >> "$logfile"
echo "" >> "$logfile"

############################################
# 2. Unterordner für Pages und Numbers anlegen
############################################
subfolderPages="$(pwd)/${folder}/pages"
subfolderNumbers="$(pwd)/${folder}/numbers"
mkdir -p "$subfolderPages"
mkdir -p "$subfolderNumbers"

############################################
# 3. Funktionen: Datei in PDF exportieren
############################################
convert_pages() {
    file="$1"
    out="${subfolderPages}/$(basename "${file%.pages}.pdf")"

    echo "Pages → PDF: $file → $out" >> "$logfile"

    osascript <<EOF >> "$logfile" 2>&1
    tell application "Pages"
        set theDoc to open POSIX file "$file"
        export theDoc to POSIX file "$out" as PDF
        close theDoc saving no
    end tell
EOF
}

convert_numbers() {
    file="$1"
    out="${subfolderNumbers}/$(basename "${file%.numbers}.pdf")"

    echo "Numbers → PDF: $file → $out" >> "$logfile"

    osascript <<EOF >> "$logfile" 2>&1
    tell application "Numbers"
        set theDoc to open POSIX file "$file"
        export theDoc to POSIX file "$out" as PDF
        close theDoc saving no
    end tell
EOF
}

############################################
# 4. Rekursives Durchsuchen
############################################
export IFS=$'\n'

# Pages-Dateien rekursiv
while IFS= read -r f; do
    f="$(pwd)/${f#./}"   # Absoluter Pfad
    convert_pages "$f"
done < <(find . -type f -name "*.pages")

# Numbers-Dateien rekursiv
while IFS= read -r f; do
    f="$(pwd)/${f#./}"   # Absoluter Pfad
    convert_numbers "$f"
done < <(find . -type f -name "*.numbers")

############################################
# 5. Abschluss
############################################
echo "" >> "$logfile"
echo "Finished: $(date +"%Y-%m-%d_%H-%M-%S")" >> "$logfile"

echo "Done! Log saved: ${logfile}"
