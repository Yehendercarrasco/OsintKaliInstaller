# OSINT Script para Kali Linux

Este script automatiza la instalación y configuración de herramientas OSINT en Kali Linux, organizándolas en categorías específicas en el menú de aplicaciones.

## Características

- Instalación automática de herramientas OSINT
- Organización en categorías en el menú de Kali Linux
- Gestión de dependencias y entornos virtuales
- Actualización automática de herramientas existentes
- Verificación de funcionalidad post-instalación
- Sistema de registro de errores detallado

## Requisitos

- Kali Linux (recomendado) o sistema basado en Debian
- Python 3.x
- Git
- pip y pipx
- python3-venv

## Instalación

1. Clona este repositorio:
```bash
git clone https://github.com/tu-usuario/OsintKaliInstaller.git
cd OsintKaliInstaller
```

2. Dale permisos de ejecución al script:
```bash
chmod +x osintscript.sh
```

3. Ejecuta el script:
```bash
./osintscript.sh
```

## Categorías y Herramientas

### 1. Username
Herramientas para búsqueda de nombres de usuario en diferentes plataformas:
- Blackbird
- AliensEye
- UserFinder
- Sherlock
- Maigret
- socialscan
- social-analyzer
- nexfil
- whatsmyname

### 2. Email
Herramientas para búsqueda y análisis de correos electrónicos:
- Eyes
- Profil3r
- Zehef
- EmailHarvester
- H8mail
- holehe
- ghunt

### 3. Phone
Herramientas para búsqueda de información relacionada con números de teléfono:
- PhoneInfoga
- Inspector
- Phunter

### 4. Social
Herramientas para análisis de redes sociales:
- GitSint
- Masto
- Osintgram
- twint
- instaloader
- toutatis

### 5. Domain
Herramientas para análisis de dominios:
- DNSRecon
- Photon

### 6. Framework
Herramientas framework para OSINT:
- Spiderfoot

### 7. Recon
Herramientas de reconocimiento general:
- TheHarvester
- osint
- shodan

## Estructura de Directorios

```
$HOME/
└── OSINTko/
    ├── [Herramientas instaladas]
    └── logs/
```

## Solución de Problemas

Si encuentras errores durante la instalación:

1. **Errores de Entorno Virtual**:
   - Instala python3-venv: `sudo apt install python3-venv`
   - Verifica permisos del directorio
   - Crea el entorno virtual manualmente

2. **Errores de Dependencias**:
   - Actualiza pip: `pip install --upgrade pip`
   - Verifica compatibilidad de versiones
   - Instala dependencias manualmente

3. **Errores de Clonación**:
   - Verifica tu conexión a internet
   - Comprueba la accesibilidad del repositorio

4. **Errores de Ejecución**:
   - Verifica que la herramienta está en el PATH
   - Comprueba los permisos de ejecución
   - Revisa los logs de error

## Notas Importantes

- El script respeta las instalaciones existentes de Kali Linux
- Las herramientas se organizan automáticamente en el menú de aplicaciones
- Para ver los cambios en el menú, cierra sesión y vuelve a iniciar o ejecuta:
  ```bash
  sudo update-desktop-database
  sudo update-menus
  ```

## Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue primero para discutir los cambios que te gustaría hacer.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.




