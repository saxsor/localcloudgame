#!/bin/bash

SAVE_DIR="/crear/un/directorio/local/user1saves"  # Ruta al directorio de saves
SESSION_ID="$1"  # Nuevo ID de sesión proporcionado como argumento

if [ -z "$SESSION_ID" ]; then
    echo "Error: No se proporcionó el ID de sesión."
    exit 1
fi

echo "Actualizando archivos de guardado con ID de sesión: $SESSION_ID"

for FILE in "$SAVE_DIR"/*; do
    BASENAME=$(basename "$FILE")
    if [[ "$BASENAME" == *___* ]]; then
        GAME_NAME=$(echo "$BASENAME" | cut -d'_' -f4- | sed 's/\.[^.]*$//')  # Extraer nombre del juego
        EXTENSION="${BASENAME##*.}"  # Extraer extensión
        NEW_NAME="${SESSION_ID}___${GAME_NAME}.${EXTENSION}"

        mv "$FILE" "$SAVE_DIR/$NEW_NAME"
        echo "Renombrado: $BASENAME -> $NEW_NAME"
    fi
done

echo "Actualización completada."
