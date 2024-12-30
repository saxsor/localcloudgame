#!/bin/bash

# Asociación entre contenedores y sus scripts de actualización
declare -A container_scripts=(
    ["ID DEL CONTENEDOR"]="/usr/local/bin/update_user#saves.sh"
    ["ID DEL CONTENEDOR"]="/usr/local/bin/update_user#saves.sh"
    ["ID DEL CONTENEDOR"]="/usr/local/bin/update_user#saves.sh"
    ["ID DEL CONTENEDOR"]="/usr/local/bin/update_user#saves.sh"
    ["ID DEL CONTENEDOR"]="/usr/local/bin/update_user#saves.sh"
)

# Directorio para guardar el histórico de sesiones procesadas por contenedor
TEMP_DIR="/tmp/container_sessions"
mkdir -p "$TEMP_DIR"

# Función para verificar si un ID ya ha sido procesado
session_already_processed() {
    local container=$1
    local session_id=$2
    local history_file="$TEMP_DIR/${container}_session_history"

    # Crear el archivo si no existe
    if [[ ! -f "$history_file" ]]; then
        touch "$history_file"
    fi

    # Verificar si el ID ya está en el histórico
    grep -q "^$session_id$" "$history_file"
}

# Función para agregar un ID al histórico
add_session_to_history() {
    local container=$1
    local session_id=$2
    local history_file="$TEMP_DIR/${container}_session_history"

    # Agregar el ID al histórico
    echo "$session_id" >> "$history_file"
}

# Función para monitorear un contenedor
monitor_container() {
    local container=$1
    local update_script=${container_scripts[$container]}
    echo "Monitorizando logs del contenedor $container..."

    # Verifica si el script de actualización existe
    if [[ ! -f $update_script ]]; then
        echo "Error: No se encontró el script de actualización para $container en $update_script"
        return
    fi

    # Monitorear logs en tiempo real
    docker logs -f "$container" 2>&1 | while read -r line; do
        # Limpiar caracteres de control y códigos de escape
        clean_line=$(echo "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' | tr -d '[:cntrl:]')

        if echo "$clean_line" | grep -q "Received room response"; then
            echo "Procesando línea limpia: $clean_line"

            # Extraer el ID de sesión hasta antes de los "___"
            session_id=$(echo "$clean_line" | grep -oP '(?<=id=")[^_]*(?=___)')

            if [[ -n $session_id ]]; then
                if session_already_processed "$container" "$session_id"; then
                    echo "ID de sesión ya procesado anteriormente para $container: $session_id"
                else
                    echo "Nuevo ID de sesión detectado para $container: $session_id"
                    add_session_to_history "$container" "$session_id"

                    # Ejecutar el script de actualización solo para este contenedor
                    bash "$update_script" "$session_id"
                fi
            else
                echo "Error: No se pudo extraer un session_id válido. Línea limpia: $clean_line"
            fi
        fi
    done
}

# Monitorear cada contenedor en segundo plano
for container in "${!container_scripts[@]}"; do
    monitor_container "$container" &
done

# Esperar a que todos los procesos terminen
wait
