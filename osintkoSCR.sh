#!/bin/bash 

BASE_DIR="$HOME/OSINTko"
DESKTOP_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"
LOG_DIR="$BASE_DIR/logs"
SUCCESSFUL_TOOLS=()
FAILED_TOOLS=()
ERROR_LOGS=()

# Función para registrar errores
log_error() {
    local tool=$1
    local error_msg=$2
    ERROR_LOGS+=("$tool: $error_msg")
}

# Función para verificar si estamos en Kali Linux
is_kali() {
    if [ -f /etc/os-release ]; then
        if grep -q "Kali" /etc/os-release; then
            return 0
        fi
    fi
    return 1
}

# Función para verificar si una herramienta ya está instalada
check_tool_exists() {
    local tool_name=$1
    if command -v "$tool_name" >/dev/null 2>&1 || \
       python3 -c "import $tool_name" >/dev/null 2>&1 || \
       [ -f "/usr/share/kali-tools/$tool_name" ] || \
       [ -f "/usr/share/$tool_name" ] || \
       [ -f "/usr/bin/$tool_name" ] || \
       [ -f "/usr/local/bin/$tool_name" ]; then
        return 0
    fi
    return 1
}

# Función para verificar si una herramienta funciona correctamente
check_tool_functionality() {
    local tool=$1
    local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    
    case "$tool_lower" in
        "aliens-eye")
            if ! command -v aliens-eye >/dev/null 2>&1 || ! aliens-eye --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "profil3r")
            if ! command -v profil3r >/dev/null 2>&1 || ! profil3r --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "blackbird")
            if ! command -v blackbird >/dev/null 2>&1 || ! blackbird --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "holehe")
            if ! command -v holehe >/dev/null 2>&1 || ! holehe --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "twint")
            if ! command -v twint >/dev/null 2>&1 || ! twint --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "whatsmyname")
            if ! command -v whatsmyname >/dev/null 2>&1 || ! whatsmyname --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "shodan")
            if ! command -v shodan >/dev/null 2>&1 || ! shodan --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
        *)
            if ! command -v "$tool_lower" >/dev/null 2>&1 || ! "$tool_lower" --version >/dev/null 2>&1; then
                return 1
            fi
            ;;
    esac
    return 0
}

# Función para desinstalar una herramienta
uninstall_tool() {
    local tool=$1
    local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    
    echo "Desinstalando $tool..."
    if is_kali && apt-cache show "$tool_lower" >/dev/null 2>&1; then
        sudo apt remove -y "$tool_lower"
    elif command -v pip >/dev/null 2>&1; then
        pip uninstall -y "$tool_lower"
    fi
    rm -rf "$BASE_DIR/$tool"
    rm -f "$DESKTOP_DIR/${tool}.desktop"
    rm -f "$BIN_DIR/$tool"
}

# Función para actualizar una herramienta existente
update_existing_tool() {
    local tool=$1
    local tool_dir="$BASE_DIR/$tool"
    local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    
    echo "Actualizando $tool..."
    if is_kali && apt-cache show "$tool_lower" >/dev/null 2>&1; then
        if ! sudo apt install --only-upgrade "$tool_lower"; then
            log_error "$tool" "Error al actualizar desde apt"
            return 1
        fi
    elif [ -d "$tool_dir/.git" ]; then
        cd "$tool_dir" || return 1
        if ! git pull; then
            log_error "$tool" "Error al actualizar desde git"
            return 1
        fi
        if [ -f "requirements.txt" ]; then
            source "$tool_dir/venv/bin/activate"
            if ! pip install -r requirements.txt --upgrade; then
                log_error "$tool" "Error al actualizar dependencias"
                deactivate
                return 1
            fi
            deactivate
        fi
    elif command -v pip >/dev/null 2>&1; then
        if ! pip install --upgrade "$tool"; then
            log_error "$tool" "Error al actualizar con pip"
            return 1
        fi
    fi
    return 0
}

# Función para probar una herramienta después de la instalación
test_tool_installation() {
    local tool=$1
    local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    local tool_dir="$BASE_DIR/$tool"
    local error_output=""
    
    echo "Probando instalación de $tool..."
    
    case "$tool_lower" in
        "aliens-eye")
            if [ -d "$tool_dir" ]; then
                cd "$tool_dir" || return 1
                source venv/bin/activate
                error_output=$(python3 Aliens_Eye.py --version 2>&1)
                deactivate
                if [ $? -ne 0 ]; then
                    log_error "$tool" "Error al probar instalación: $error_output"
                    return 1
                fi
            fi
            ;;
        "blackbird")
            if [ -d "$tool_dir" ]; then
                cd "$tool_dir" || return 1
                source venv/bin/activate
                error_output=$(python3 blackbird.py --version 2>&1)
                deactivate
                if [ $? -ne 0 ]; then
                    log_error "$tool" "Error al probar instalación: $error_output"
                    return 1
                fi
            fi
            ;;
        "twint")
            error_output=$(twint --version 2>&1)
            if [ $? -ne 0 ]; then
                log_error "$tool" "Error al probar instalación: $error_output"
                return 1
            fi
            ;;
        "whatsmyname")
            error_output=$(whatsmyname --version 2>&1)
            if [ $? -ne 0 ]; then
                log_error "$tool" "Error al probar instalación: $error_output"
                return 1
            fi
            ;;
        "shodan")
            error_output=$(shodan --version 2>&1)
            if [ $? -ne 0 ]; then
                log_error "$tool" "Error al probar instalación: $error_output"
                return 1
            fi
            ;;
        *)
            if [ -d "$tool_dir" ]; then
                cd "$tool_dir" || return 1
                source venv/bin/activate
                error_output=$(python3 "${scripts[$tool]}" --version 2>&1)
                deactivate
                if [ $? -ne 0 ]; then
                    log_error "$tool" "Error al probar instalación: $error_output"
                    return 1
                fi
            fi
            ;;
    esac
    return 0
}

# Crear directorios necesarios
mkdir -p "$BASE_DIR" "$DESKTOP_DIR" "$BIN_DIR" "$LOG_DIR"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    export PATH="$BIN_DIR:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Verificar y actualizar sistema
if is_kali; then
    echo "Detectado Kali Linux. Actualizando sistema..."
    if ! (sudo apt update && sudo apt install -y python3-pip python3-venv pipx git); then
        log_error "Sistema" "Error al actualizar dependencias básicas"
    fi
else
    echo "No se detectó Kali Linux. Instalando dependencias básicas..."
    if ! (sudo apt update && sudo apt install -y python3-pip python3-venv pipx git); then
        log_error "Sistema" "Error al instalar dependencias básicas"
    fi
fi

cd "$BASE_DIR" || exit 1

declare -A urls=(
    ["Blackbird"]="https://github.com/p1ngul1n0/blackbird.git"
    ["AliensEye"]="https://github.com/HACK3RY2J/Aliens-Eye.git"
    ["UserFinder"]="https://github.com/mishakorzik/UserFinder.git"
    ["PhoneInfoga"]="https://github.com/sundowndev/phoneinfoga.git"
    ["Inspector"]="https://github.com/N0rz3/Inspector.git"
    ["Phunter"]="https://github.com/N0rz3/Phunter.git"
    ["Eyes"]="https://github.com/N0rz3/Eyes.git"
    ["Profil3r"]="https://github.com/Greyjedix/Profil3r.git"
    ["Zehef"]="https://github.com/N0rz3/Zehef.git"
    ["GitSint"]="https://github.com/N0rz3/GitSint.git"
    ["Masto"]="https://github.com/C3n7ral051nt4g3ncy/Masto.git"
    ["Osintgram"]="https://github.com/Datalux/Osintgram.git"
    ["Sherlock"]="https://github.com/sherlock-project/sherlock.git"
    ["Maigret"]="https://github.com/soxoj/maigret.git"
    ["TheHarvester"]="https://github.com/laramies/theHarvester.git"
    ["EmailHarvester"]="https://github.com/maldevel/EmailHarvester.git"
    ["H8mail"]="https://github.com/khast3x/h8mail.git"
    ["DNSRecon"]="https://github.com/darkoperator/dnsrecon.git"
    ["Photon"]="https://github.com/s0md3v/Photon.git"
    ["Spiderfoot"]="https://github.com/smicallef/spiderfoot.git"
)

declare -A scripts=(
    ["Blackbird"]="blackbird.py"
    ["AliensEye"]="Aliens_Eye.py"
    ["UserFinder"]="UserFinder.py"
    ["PhoneInfoga"]="phoneinfoga.py"
    ["Inspector"]="core/inspector.py"
    ["Phunter"]="phunter.py"
    ["Eyes"]="eyes.py"
    ["Profil3r"]="profil3r.py"
    ["Zehef"]="zehef.py"
    ["GitSint"]="gitsint.py"
    ["Masto"]="masto.py"
    ["Osintgram"]="main.py"
    ["Sherlock"]="sherlock/sherlock.py"
    ["Maigret"]="maigret.py"
    ["TheHarvester"]="theHarvester.py"
    ["EmailHarvester"]="EmailHarvester.py"
    ["H8mail"]="h8mail/h8mail.py"
    ["DNSRecon"]="dnsrecon.py"
    ["Photon"]="photon.py"
    ["Spiderfoot"]="sf.py"
)

declare -A categories=(
    ["Blackbird"]="osint-username;"
    ["AliensEye"]="osint-username;"
    ["UserFinder"]="osint-username;"
    ["PhoneInfoga"]="osint-phone-number;"
    ["Inspector"]="osint-phone-number;"
    ["Phunter"]="osint-phone-number;"
    ["Eyes"]="osint-email;"
    ["Profil3r"]="osint-email;"
    ["Zehef"]="osint-email;"
    ["GitSint"]="osint-social-media;"
    ["Masto"]="osint-social-media;"
    ["Osintgram"]="osint-social-media;"
    ["Sherlock"]="osint-username;"
    ["Maigret"]="osint-username;"
    ["TheHarvester"]="osint-recon;"
    ["EmailHarvester"]="osint-email;"
    ["H8mail"]="osint-email;"
    ["DNSRecon"]="osint-domain;"
    ["Photon"]="osint-domain;"
    ["Spiderfoot"]="osint-framework;"
)

# Configurar git para no pedir credenciales
git config --global advice.detachedHead false
export GIT_TERMINAL_PROMPT=0

for tool in "${!urls[@]}"; do 
    tool_dir="$BASE_DIR/$tool"
    tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    
    echo "Procesando $tool..."
    
    # Verificar si la herramienta existe y funciona
    if check_tool_exists "$tool_lower"; then
        if ! check_tool_functionality "$tool"; then
            echo "$tool está instalado pero no funciona correctamente. Reinstalando..."
            uninstall_tool "$tool"
        else
            echo "$tool está instalado y funcionando correctamente."
            SUCCESSFUL_TOOLS+=("$tool")
            continue
        fi
    fi

    # Variable para rastrear si la instalación/actualización fue exitosa
    installation_success=true

    if [ -d "$tool_dir" ]; then 
        echo "$tool ya está instalado en OSINTko. Actualizando..."
        if ! update_existing_tool "$tool"; then
            installation_success=false
        fi
    else 
        echo "Instalando $tool..."
        if ! git clone --depth 1 "${urls[$tool]}" "$tool_dir" 2>/dev/null; then
            log_error "$tool" "Error al clonar repositorio"
            installation_success=false
        else
            if ! cd "$tool_dir"; then
                log_error "$tool" "Error al acceder al directorio"
                installation_success=false
            else
                if ! python3 -m venv "$tool_dir/venv"; then
                    log_error "$tool" "Error al crear entorno virtual"
                    installation_success=false
                else
                    source "$tool_dir/venv/bin/activate"
                    case "$tool" in
                        "H8mail")
                            if ! pip install h8mail; then
                                log_error "$tool" "Error al instalar via pip"
                                installation_success=false
                            fi
                            ;;
                        "Blackbird")
                            if ! pip install -r requirements.txt requests beautifulsoup4 colorama; then
                                log_error "$tool" "Error al instalar dependencias específicas"
                                installation_success=false
                            fi
                            ;;
                        "Maigret")
                            if ! pip install maigret; then
                                log_error "$tool" "Error al instalar via pip"
                                installation_success=false
                            fi
                            ;;
                        "Profil3r")
                            if ! pip install -r requirements.txt; then
                                log_error "$tool" "Error al instalar dependencias"
                                installation_success=false
                            fi
                            ;;
                        "AliensEye")
                            if ! pip install -r requirements.txt; then
                                log_error "$tool" "Error al instalar dependencias"
                                installation_success=false
                            fi
                            ;;
                        *)
                            if [ -f "$tool_dir/requirements.txt" ]; then
                                if ! pip install -r requirements.txt; then
                                    log_error "$tool" "Error al instalar dependencias"
                                    installation_success=false
                                fi
                            elif [ -f "$tool_dir/setup.py" ]; then
                                if ! python3 setup.py install; then
                                    log_error "$tool" "Error al ejecutar setup.py"
                                    installation_success=false
                                fi
                            fi
                            ;;
                    esac
                    deactivate
                fi
            fi
        fi
    fi

    # Registrar resultado
    if [ "$installation_success" = true ]; then
        SUCCESSFUL_TOOLS+=("$tool")
        
        # Crear accesos directos solo si la instalación fue exitosa
        if is_kali && [ -f "/usr/bin/$tool_lower" ]; then
            tool_path="/usr/bin/$tool_lower"
        else
            tool_path="$BIN_DIR/$tool"
            cat << EOF > "$tool_path"
#!/bin/bash
cd "$tool_dir" || exit 1
source "$tool_dir/venv/bin/activate"
python3 "${scripts[$tool]}" "\$@"
deactivate
EOF
            chmod +x "$tool_path"
        fi

        cat << EOF > "$DESKTOP_DIR/${tool}.desktop"
[Desktop Entry]
Name=$tool
Comment=$tool is an OSINT tool.
Exec=xfce4-terminal -H -e "$tool_path"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=${categories[$tool]}
EOF

        if ! test_tool_installation "$tool"; then
            log_error "$tool" "La instalación fue exitosa pero la herramienta no funciona correctamente"
            installation_success=false
        fi
    else
        FAILED_TOOLS+=("$tool")
        continue
    fi
done

declare -A pipx_tools=(
    ["socialscan"]="osint-username;"
    ["social-analyzer"]="osint-username;"
    ["nexfil"]="osint-username;"
    ["instaloader"]="osint-social-media;"
    ["holehe"]="osint-email;"
    ["ghunt"]="osint-email;"
    ["osint"]="recon;"
    ["toutatis"]="osint-social-media;"
)

for pipx_tool in "${!pipx_tools[@]}"; do
    installation_success=true
    
    if is_kali && apt-cache show "$pipx_tool" >/dev/null 2>&1; then
        echo "Instalando/actualizando $pipx_tool desde repositorios de Kali..."
        if ! sudo apt install -y "$pipx_tool"; then
            log_error "$pipx_tool" "Error al instalar desde apt"
            installation_success=false
        fi
    elif command -v "$pipx_tool" >/dev/null 2>&1; then
        if ! check_tool_functionality "$pipx_tool"; then
            echo "$pipx_tool está instalado pero no funciona correctamente. Reinstalando..."
            pipx uninstall "$pipx_tool"
            if ! pipx install "$pipx_tool"; then
                log_error "$pipx_tool" "Error al reinstalar con pipx"
                installation_success=false
            fi
        else
            echo "$pipx_tool está instalado y funcionando correctamente."
            SUCCESSFUL_TOOLS+=("$pipx_tool")
            continue
        fi
    elif ! pipx list | grep -q "$pipx_tool"; then
        echo "Instalando $pipx_tool con pipx..."
        if ! pipx install "$pipx_tool"; then
            log_error "$pipx_tool" "Error al instalar con pipx"
            installation_success=false
        fi
    fi
    
    if [ "$installation_success" = true ]; then
        SUCCESSFUL_TOOLS+=("$pipx_tool")
        
        if is_kali && [ -f "/usr/bin/$pipx_tool" ]; then
            tool_path="/usr/bin/$pipx_tool"
        else
            tool_path="$HOME/.local/bin/$pipx_tool"
        fi

        cat << EOF > "$DESKTOP_DIR/${pipx_tool}.desktop"
[Desktop Entry]
Name=${pipx_tool^}
Comment=${pipx_tool^} is an OSINT tool
Exec=xfce4-terminal -H -e "$tool_path"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=${pipx_tools[$pipx_tool]}
EOF

        if ! test_tool_installation "$pipx_tool"; then
            log_error "$pipx_tool" "La instalación fue exitosa pero la herramienta no funciona correctamente"
            installation_success=false
        fi
    else
        FAILED_TOOLS+=("$pipx_tool")
    fi
done

# Instalar twint, whatsmyname y shodan-cli por separado usando pip
for tool in "twint" "whatsmyname" "shodan"; do
    if command -v "$tool" >/dev/null 2>&1; then
        if ! check_tool_functionality "$tool"; then
            echo "$tool está instalado pero no funciona correctamente. Reinstalando..."
            pip uninstall -y "$tool"
        else
            echo "$tool está instalado y funcionando correctamente."
            SUCCESSFUL_TOOLS+=("$tool")
            continue
        fi
    fi
    
    echo "Instalando $tool..."
    if ! pip3 install --user "$tool"; then
        log_error "$tool" "Error al instalar con pip"
        FAILED_TOOLS+=("$tool")
    else
        SUCCESSFUL_TOOLS+=("$tool")
        cat << EOF > "$DESKTOP_DIR/${tool}.desktop"
[Desktop Entry]
Name=${tool^}
Comment=${tool^} is an OSINT tool
Exec=xfce4-terminal -H -e "$tool"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=osint-social-media;
EOF

        if ! test_tool_installation "$tool"; then
            log_error "$tool" "La instalación fue exitosa pero la herramienta no funciona correctamente"
            installation_success=false
        fi
    fi
done

# Mostrar resumen final
echo -e "\n=== RESUMEN DETALLADO DE INSTALACIÓN ==="
echo -e "\nHerramientas instaladas exitosamente (${#SUCCESSFUL_TOOLS[@]}):"
printf '%s\n' "${SUCCESSFUL_TOOLS[@]}" | sort

if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
    echo -e "\nHerramientas que fallaron (${#FAILED_TOOLS[@]}):"
    printf '%s\n' "${FAILED_TOOLS[@]}" | sort
    
    echo -e "\nDetalles de errores por categoría:"
    echo -e "\n1. Errores de Entorno Virtual:"
    for error in "${ERROR_LOGS[@]}"; do
        if [[ $error == *"venv"* ]] || [[ $error == *"virtual environment"* ]]; then
            echo "- $error"
        fi
    done
    
    echo -e "\n2. Errores de Dependencias:"
    for error in "${ERROR_LOGS[@]}"; do
        if [[ $error == *"requirements.txt"* ]] || [[ $error == *"dependencies"* ]]; then
            echo "- $error"
        fi
    done
    
    echo -e "\n3. Errores de Clonación:"
    for error in "${ERROR_LOGS[@]}"; do
        if [[ $error == *"clone"* ]] || [[ $error == *"repositorio"* ]]; then
            echo "- $error"
        fi
    done
    
    echo -e "\n4. Errores de Ejecución:"
    for error in "${ERROR_LOGS[@]}"; do
        if [[ $error == *"Error al probar instalación"* ]] || [[ $error == *"Error al ejecutar"* ]]; then
            echo "- $error"
        fi
    done
    
    echo -e "\n5. Otros Errores:"
    for error in "${ERROR_LOGS[@]}"; do
        if [[ ! $error == *"venv"* ]] && [[ ! $error == *"requirements.txt"* ]] && \
           [[ ! $error == *"clone"* ]] && [[ ! $error == *"Error al probar instalación"* ]] && \
           [[ ! $error == *"Error al ejecutar"* ]]; then
            echo "- $error"
        fi
    done
fi

echo -e "\nRecomendaciones para resolver errores comunes:"
echo "1. Para errores de entorno virtual:"
echo "   - Asegúrate de tener python3-venv instalado"
echo "   - Verifica los permisos del directorio"
echo "   - Intenta crear el entorno virtual manualmente"
echo "2. Para errores de dependencias:"
echo "   - Actualiza pip: pip install --upgrade pip"
echo "   - Verifica la compatibilidad de versiones"
echo "   - Intenta instalar las dependencias manualmente"
echo "3. Para errores de clonación:"
echo "   - Verifica tu conexión a internet"
echo "   - Asegúrate de que el repositorio existe y es accesible"
echo "4. Para errores de ejecución:"
echo "   - Verifica que la herramienta está en el PATH"
echo "   - Comprueba los permisos de ejecución"
echo "   - Revisa los logs de error específicos"

echo -e "\nInstalación/actualización completada."
if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
    echo "Algunas herramientas fallaron. Revisa las recomendaciones anteriores para resolver los problemas."
fi

if is_kali; then
    echo "Nota: Se han respetado las instalaciones existentes de Kali Linux y se han actualizado según fue necesario."
fi

echo "Nota: Para usuarios de KDE, GNOME o Xfce, cierra sesión y vuelve a iniciar o usa una herramienta de actualización de menú para que los cambios aparezcan."

