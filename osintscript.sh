#!/bin/bash 

BASE_DIR="$HOME/OSINTko"
DESKTOP_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"
LOG_DIR="$BASE_DIR/logs"
SUCCESSFUL_TOOLS=()
FAILED_TOOLS=()
ERROR_LOGS=()

# Definición de categorías OSINT
declare -A OSINT_CATEGORIES=(
    ["username"]="OSINT;Username;"
    ["email"]="OSINT;Email;"
    ["phone"]="OSINT;Phone;"
    ["social"]="OSINT;Social;"
    ["domain"]="OSINT;Domain;"
    ["framework"]="OSINT;Framework;"
    ["recon"]="OSINT;Recon;"
)

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

# Función para crear categorías en el menú de Kali
create_kali_categories() {
    if is_kali; then
        # Crear directorio principal de OSINT
        sudo mkdir -p /usr/share/desktop-directories
        sudo mkdir -p /usr/share/applications
        
        # Crear categoría principal OSINT
        cat << EOF | sudo tee /usr/share/desktop-directories/osint.directory
[Desktop Entry]
Name=OSINT
Comment=OSINT Tools Collection
Icon=utilities-terminal
Type=Directory
EOF

        # Crear subcategorías
        for category in "${!OSINT_CATEGORIES[@]}"; do
            local category_name="${category^}"
            cat << EOF | sudo tee "/usr/share/desktop-directories/osint-$category.directory"
[Desktop Entry]
Name=$category_name
Comment=OSINT Tools for $category_name
Icon=utilities-terminal
Type=Directory
EOF
        done

        # Crear archivo de menú principal
        cat << EOF | sudo tee /usr/share/applications/osint-tools.menu
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
    <Name>OSINT Tools</Name>
    <Directory>osint.directory</Directory>
    <Include>
        <Category>OSINT</Category>
    </Include>
</Menu>
EOF

        # Actualizar la base de datos de menús
        sudo update-desktop-database
        sudo update-menus
    fi
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
    local tool_dir="$BASE_DIR/$tool"
    
    echo "Verificando funcionalidad de $tool..."
    
    case "$tool_lower" in
        "aliens-eye")
            if [ -d "$tool_dir" ]; then
                cd "$tool_dir" || return 1
                source venv/bin/activate
                if ! python3 Aliens_Eye.py --help >/dev/null 2>&1; then
                    deactivate
                    return 1
                fi
                deactivate
            else
                if ! command -v aliens-eye >/dev/null 2>&1 || ! aliens-eye --help >/dev/null 2>&1; then
                    return 1
                fi
            fi
            ;;
        "profil3r")
            if [ -d "$tool_dir" ]; then
                cd "$tool_dir" || return 1
                source venv/bin/activate
                if ! python3 profil3r.py --help >/dev/null 2>&1; then
                    deactivate
                    return 1
                fi
                deactivate
            else
                if ! command -v profil3r >/dev/null 2>&1 || ! profil3r --help >/dev/null 2>&1; then
                    return 1
                fi
            fi
            ;;
        "blackbird")
            if [ -d "$tool_dir" ]; then
                cd "$tool_dir" || return 1
                source venv/bin/activate
                if ! python3 blackbird.py --help >/dev/null 2>&1; then
                    deactivate
                    return 1
                fi
                deactivate
            else
                if ! command -v blackbird >/dev/null 2>&1 || ! blackbird --help >/dev/null 2>&1; then
                    return 1
                fi
            fi
            ;;
        "holehe")
            if ! command -v holehe >/dev/null 2>&1 || ! holehe --help >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "twint")
            if ! command -v twint >/dev/null 2>&1 || ! twint --help >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "whatsmyname")
            if ! command -v whatsmyname >/dev/null 2>&1 || ! whatsmyname --help >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "shodan")
            if ! command -v shodan >/dev/null 2>&1 || ! shodan --help >/dev/null 2>&1; then
                return 1
            fi
            ;;
        "sherlock")
            if ! command -v sherlock >/dev/null 2>&1 || ! sherlock --help >/dev/null 2>&1; then
                return 1
            fi
            ;;
        *)
            if [ -d "$tool_dir" ]; then
                cd "$tool_dir" || return 1
                source venv/bin/activate
                if ! python3 "${scripts[$tool]}" --help >/dev/null 2>&1; then
                    deactivate
                    return 1
                fi
                deactivate
            else
                if ! command -v "$tool_lower" >/dev/null 2>&1 || ! "$tool_lower" --help >/dev/null 2>&1; then
                    return 1
                fi
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

# Función para crear acceso directo en el menú
create_menu_entry() {
    local tool=$1
    local category=$2
    local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    local tool_path="$BIN_DIR/$tool"
    
    if is_kali && [ -f "/usr/bin/$tool_lower" ]; then
        tool_path="/usr/bin/$tool_lower"
    fi
    
    # Crear el archivo .desktop en el directorio de aplicaciones del sistema
    cat << EOF | sudo tee "/usr/share/applications/osint-${tool_lower}.desktop"
[Desktop Entry]
Name=$tool
Comment=$tool is an OSINT tool
Exec=xfce4-terminal -H -e "$tool_path"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=OSINT;${OSINT_CATEGORIES[$category]}
EOF

    # Crear una copia en el directorio local para respaldo
    cat << EOF > "$DESKTOP_DIR/osint-${tool}.desktop"
[Desktop Entry]
Name=$tool
Comment=$tool is an OSINT tool
Exec=xfce4-terminal -H -e "$tool_path"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=OSINT;${OSINT_CATEGORIES[$category]}
EOF
}

# Crear directorios necesarios
mkdir -p "$BASE_DIR" "$DESKTOP_DIR" "$BIN_DIR" "$LOG_DIR"

# Crear categorías en el menú de Kali
create_kali_categories

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

# Definición de herramientas y sus categorías
declare -A tools=(
    ["Blackbird"]="username"
    ["AliensEye"]="username"
    ["UserFinder"]="username"
    ["PhoneInfoga"]="phone"
    ["Inspector"]="phone"
    ["Phunter"]="phone"
    ["Eyes"]="email"
    ["Profil3r"]="email"
    ["Zehef"]="email"
    ["GitSint"]="social"
    ["Masto"]="social"
    ["Osintgram"]="social"
    ["Maigret"]="username"
    ["TheHarvester"]="recon"
    ["EmailHarvester"]="email"
    ["H8mail"]="email"
    ["DNSRecon"]="domain"
    ["Photon"]="domain"
    ["Spiderfoot"]="framework"
)

# URLs de los repositorios
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
    ["Maigret"]="https://github.com/soxoj/maigret.git"
    ["TheHarvester"]="https://github.com/laramies/theHarvester.git"
    ["EmailHarvester"]="https://github.com/maldevel/EmailHarvester.git"
    ["H8mail"]="https://github.com/khast3x/h8mail.git"
    ["DNSRecon"]="https://github.com/darkoperator/dnsrecon.git"
    ["Photon"]="https://github.com/s0md3v/Photon.git"
    ["Spiderfoot"]="https://github.com/smicallef/spiderfoot.git"
)

# Scripts principales de cada herramienta
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
    ["Maigret"]="maigret.py"
    ["TheHarvester"]="theHarvester.py"
    ["EmailHarvester"]="EmailHarvester.py"
    ["H8mail"]="h8mail/h8mail.py"
    ["DNSRecon"]="dnsrecon.py"
    ["Photon"]="photon.py"
    ["Spiderfoot"]="sf.py"
)

# Configurar git para no pedir credenciales
git config --global advice.detachedHead false
export GIT_TERMINAL_PROMPT=0

# Función para crear y activar entorno virtual
setup_virtual_env() {
    local tool_dir=$1
    local tool=$2
    
    echo "Configurando entorno virtual para $tool..."
    
    # Crear el entorno virtual si no existe
    if [ ! -d "$tool_dir/venv" ]; then
        if ! python3 -m venv "$tool_dir/venv"; then
            log_error "$tool" "Error al crear entorno virtual"
            return 1
        fi
    fi
    
    # Activar el entorno virtual
    source "$tool_dir/venv/bin/activate"
    
    # Actualizar pip dentro del entorno virtual
    if ! pip install --upgrade pip; then
        log_error "$tool" "Error al actualizar pip en el entorno virtual"
        deactivate
        return 1
    fi
    
    return 0
}

# Función para instalar dependencias en el entorno virtual
install_virtual_env_deps() {
    local tool_dir=$1
    local tool=$2
    
    # Activar el entorno virtual
    source "$tool_dir/venv/bin/activate"
    
    case "$tool" in
        "H8mail")
            if ! pip install h8mail; then
                log_error "$tool" "Error al instalar h8mail en el entorno virtual"
                deactivate
                return 1
            fi
            ;;
        "Blackbird")
            if ! pip install -r requirements.txt requests beautifulsoup4 colorama; then
                log_error "$tool" "Error al instalar dependencias de Blackbird en el entorno virtual"
                deactivate
                return 1
            fi
            ;;
        "Maigret")
            if ! pip install maigret; then
                log_error "$tool" "Error al instalar maigret en el entorno virtual"
                deactivate
                return 1
            fi
            ;;
        "Profil3r")
            if ! pip install -r requirements.txt; then
                log_error "$tool" "Error al instalar dependencias de Profil3r en el entorno virtual"
                deactivate
                return 1
            fi
            ;;
        "AliensEye")
            if ! pip install -r requirements.txt; then
                log_error "$tool" "Error al instalar dependencias de AliensEye en el entorno virtual"
                deactivate
                return 1
            fi
            ;;
        *)
            if [ -f "$tool_dir/requirements.txt" ]; then
                if ! pip install -r requirements.txt; then
                    log_error "$tool" "Error al instalar dependencias en el entorno virtual"
                    deactivate
                    return 1
                fi
            elif [ -f "$tool_dir/setup.py" ]; then
                if ! python3 setup.py install; then
                    log_error "$tool" "Error al ejecutar setup.py en el entorno virtual"
                    deactivate
                    return 1
                fi
            fi
            ;;
    esac
    
    deactivate
    return 0
}

# Función para verificar instalación después de reinstalar
verify_reinstallation() {
    local tool=$1
    local max_attempts=2
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Intento $attempt de verificar la instalación de $tool..."
        if check_tool_functionality "$tool"; then
            echo "$tool instalado y funcionando correctamente."
            return 0
        else
            echo "La verificación de $tool falló en el intento $attempt."
            if [ $attempt -eq 1 ]; then
                echo "Reintentando instalación..."
                uninstall_tool "$tool"
                if [ -d "$BASE_DIR/$tool" ]; then
                    cd "$BASE_DIR/$tool" || return 1
                    if ! setup_virtual_env "$BASE_DIR/$tool" "$tool"; then
                        return 1
                    fi
                    if ! install_virtual_env_deps "$BASE_DIR/$tool" "$tool"; then
                        return 1
                    fi
                fi
            fi
        fi
        attempt=$((attempt + 1))
    done
    
    log_error "$tool" "La instalación falló después de $max_attempts intentos"
    return 1
}

# Función para instalar herramienta con múltiples métodos
install_tool_cascade() {
    local tool=$1
    local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    local tool_dir="$BASE_DIR/$tool"
    local category=$2
    
    echo "Iniciando instalación en cascada para $tool..."
    
    # Método 1: Intentar instalación desde apt (solo en Kali)
    if is_kali && apt-cache show "$tool_lower" >/dev/null 2>&1; then
        echo "Intentando instalar $tool desde apt..."
        if sudo apt install -y "$tool_lower"; then
            if check_tool_functionality "$tool"; then
                echo "$tool instalado exitosamente desde apt"
                return 0
            else
                echo "La instalación desde apt falló la verificación"
                sudo apt remove -y "$tool_lower"
            fi
        fi
    fi
    
    # Método 2: Intentar instalación desde pipx
    echo "Intentando instalar $tool desde pipx..."
    if pipx install "$tool_lower"; then
        if check_tool_functionality "$tool"; then
            echo "$tool instalado exitosamente desde pipx"
            return 0
        else
            echo "La instalación desde pipx falló la verificación"
            pipx uninstall "$tool_lower"
        fi
    fi
    
    # Método 3: Intentar instalación desde pip
    echo "Intentando instalar $tool desde pip..."
    if pip3 install --user "$tool_lower"; then
        if check_tool_functionality "$tool"; then
            echo "$tool instalado exitosamente desde pip"
            return 0
        else
            echo "La instalación desde pip falló la verificación"
            pip3 uninstall -y "$tool_lower"
        fi
    fi
    
    # Método 4: Intentar instalación desde git
    echo "Intentando instalar $tool desde git..."
    if [ -d "$tool_dir" ]; then
        rm -rf "$tool_dir"
    fi
    
    if git clone --depth 1 "${urls[$tool]}" "$tool_dir" 2>/dev/null; then
        cd "$tool_dir" || return 1
        
        # Configurar y activar el entorno virtual
        if setup_virtual_env "$tool_dir" "$tool"; then
            if install_virtual_env_deps "$tool_dir" "$tool"; then
                if check_tool_functionality "$tool"; then
                    echo "$tool instalado exitosamente desde git"
                    return 0
                else
                    echo "La instalación desde git falló la verificación"
                    cd "$BASE_DIR" || return 1
                    rm -rf "$tool_dir"
                fi
            fi
        fi
    fi
    
    # Si llegamos aquí, todos los métodos fallaron
    log_error "$tool" "Todos los métodos de instalación fallaron"
    return 1
}

# Instalar herramientas principales
for tool in "${!tools[@]}"; do 
    tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
    category="${tools[$tool]}"
    
    echo "Procesando $tool (Categoría: $category)..."
    
    if check_tool_exists "$tool_lower"; then
        if ! check_tool_functionality "$tool"; then
            echo "$tool está instalado pero no funciona correctamente. Reinstalando..."
            uninstall_tool "$tool"
        else
            echo "$tool está instalado y funcionando correctamente."
            SUCCESSFUL_TOOLS+=("$tool")
            create_menu_entry "$tool" "$category"
            continue
        fi
    fi

    if install_tool_cascade "$tool" "$category"; then
        SUCCESSFUL_TOOLS+=("$tool")
        create_menu_entry "$tool" "$category"
    else
        FAILED_TOOLS+=("$tool")
    fi
done

# Instalar Sherlock usando apt
echo "Instalando Sherlock..."
if ! sudo apt install -y sherlock; then
    log_error "Sherlock" "Error al instalar desde apt"
    FAILED_TOOLS+=("Sherlock")
else
    SUCCESSFUL_TOOLS+=("Sherlock")
    create_menu_entry "Sherlock" "username"
fi

# Instalar herramientas pipx
declare -A pipx_tools=(
    ["socialscan"]="username"
    ["social-analyzer"]="username"
    ["nexfil"]="username"
    ["instaloader"]="social"
    ["holehe"]="email"
    ["ghunt"]="email"
    ["osint"]="recon"
    ["toutatis"]="social"
)

for pipx_tool in "${!pipx_tools[@]}"; do
    category="${pipx_tools[$pipx_tool]}"
    
    if check_tool_exists "$pipx_tool"; then
        if ! check_tool_functionality "$pipx_tool"; then
            echo "$pipx_tool está instalado pero no funciona correctamente. Reinstalando..."
            uninstall_tool "$pipx_tool"
        else
            echo "$pipx_tool está instalado y funcionando correctamente."
            SUCCESSFUL_TOOLS+=("$pipx_tool")
            create_menu_entry "$pipx_tool" "$category"
            continue
        fi
    fi
    
    if install_tool_cascade "$pipx_tool" "$category"; then
        SUCCESSFUL_TOOLS+=("$pipx_tool")
        create_menu_entry "$pipx_tool" "$category"
    else
        FAILED_TOOLS+=("$pipx_tool")
    fi
done

# Instalar herramientas pip adicionales
declare -A pip_tools=(
    ["twint"]="social"
    ["whatsmyname"]="username"
    ["shodan"]="recon"
)

for tool in "${!pip_tools[@]}"; do
    category="${pip_tools[$tool]}"
    
    if check_tool_exists "$tool"; then
        if ! check_tool_functionality "$tool"; then
            echo "$tool está instalado pero no funciona correctamente. Reinstalando..."
            uninstall_tool "$tool"
        else
            echo "$tool está instalado y funcionando correctamente."
            SUCCESSFUL_TOOLS+=("$tool")
            create_menu_entry "$tool" "$category"
            continue
        fi
    fi
    
    if install_tool_cascade "$tool" "$category"; then
        SUCCESSFUL_TOOLS+=("$tool")
        create_menu_entry "$tool" "$category"
    else
        FAILED_TOOLS+=("$tool")
    fi
done

# Actualizar menú de aplicaciones
if is_kali; then
    echo "Actualizando menú de aplicaciones..."
    sudo update-desktop-database
    sudo update-menus
    echo "Menú de aplicaciones actualizado. Las herramientas aparecerán en la categoría OSINT."
fi

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
    echo "Las herramientas han sido organizadas en categorías en el menú de aplicaciones bajo la sección OSINT."
fi

echo "Nota: Para usuarios de KDE, GNOME o Xfce, cierra sesión y vuelve a iniciar o usa una herramienta de actualización de menú para que los cambios aparezcan."

