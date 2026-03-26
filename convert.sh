#!/bin/bash

############################################
# 1.0 Eingangspfad eingeben
############################################
echo "Insert Source Path (where to search for files):"
read sourcepath

# Falls leer → aktuelles Verzeichnis verwenden
if [ -z "$sourcepath" ]; then
    sourcepath="."
fi

# Absoluten Pfad daraus machen
sourcepath="$(cd "$sourcepath" && pwd)"
echo "Source: ${sourcepath}" >> "$logfile"

############################################
# 1.1 Zielpfad + Ordnername eingeben
############################################

echo "Insert Target Base Path (where to save PDFs):"
read targetpath

# Falls leer → aktuelles Verzeichnis
if [ -z "$targetpath" ]; then
    targetpath="."
fi

# Absoluten Pfad daraus machen
targetpath="$(cd "$targetpath" && pwd)"

echo "Insert Folder Name To Save The PDFs In:"
read folder

# Finaler Zielordner
outdir="${targetpath}/${folder}"

mkdir -p "$outdir"

logfile="${outdir}/convert.log"
touch "$logfile"

echo "==== Convert-Log ====" >> "$logfile"
echo "Start: $(date +"%Y-%m-%d_%H-%M-%S")" >> "$logfile"
echo "Target: ${outdir}" >> "$logfile"
echo "" >> "$logfile"

############################################
# 2. Unterordner für Pages und Numbers anlegen
############################################
subfolderPages="${outdir}/pages"
subfolderNumbers="${outdir}/numbers"
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
    convert_pages "$f"
done < <(find "$sourcepath" -type f -name "*.pages")

# Numbers-Dateien rekursiv
while IFS= read -r f; do
    convert_numbers "$f"
done < <(find "$sourcepath" -type f -name "*.numbers")

############################################
# 5. Abschluss
############################################
echo "" >> "$logfile"
echo "Finished: $(date +"%Y-%m-%d_%H-%M-%S")" >> "$logfile"

echo "Done! Log saved: ${logfile}"
