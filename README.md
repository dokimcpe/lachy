# Minecraft 0.15.10 x86 en WSL2

Este repositorio contiene la guía y el script de automatización para compilar e instalar el puerto nativo de Minecraft Bedrock (0.15.10 de 32-bits) en Ubuntu WSL2 (Windows Subsystem for Linux).

## ¿Cómo funciona?

- **Motor Nativo**: Usamos la librería `libminecraftpe.so` compilada nativamente para procesadores x86. Al ser x86, se ejecuta directamente en tu procesador sin usar emuladores (como BlueStacks).
- **libhybris**: El motor del juego fue compilado para Android (usa la librería de sistema Bionic de Android). Usamos `Lachy-Launcher` (basado en mcpelauncher) y `libhybris` para traducir las llamadas del sistema Android en llamadas nativas de Linux al vuelo.
- **Gráficos en Windows**: Gracias a **WSLg**, el entorno gráfico de Linux se renderiza y se muestra directamente como una ventana en tu escritorio de Windows utilizando tu tarjeta de video real mediante GLFW y OpenGL.
- **Multiarquitectura**: Puesto que el juego es de 32-bits, se requiere instalar las librerías del sistema de Ubuntu (Jammy) en su versión `i386` para permitir la compatibilidad cruzada.

## Requisitos

- Windows 10 o Windows 11 con WSL2 instalado y la distribución `Ubuntu` activa.
- WSLg soportado para interfaces gráficas (normalmente incluido en instalaciones recientes de WSL).
- El archivo APK de Minecraft PE 0.15.10 x86.
- La carpeta original de datos (opcional, pero recomendada) `Minecraft-0.15.10.0`.

## Instalación Automatizada

Hemos provisto un script llamado `setup.sh` que instala automáticamente:
- Dependencias del sistema y de 32-bits.
- Clona y compila `Lachy-Launcher-main`.
- Extrae la librería del motor (`libminecraftpe.so`) y las librerías dependientes (`libgnustl_shared.so`, `libfmod.so`) del APK de Android.
- Extrae la carpeta de idiomas e interfaz visual (`assets/`) del APK.
- Parchea el código de manejo del mouse en GLFW para arreglar el bug de Raw Motion y saltos de cámara locos específicos de WSLg.

### Instrucciones de uso:

1. Abre tu terminal de WSL (`wsl` en PowerShell).
2. Asegúrate de tener el APK listo.
3. Ejecuta el script pasándole como argumentos:
   - Ruta hacia tu APK
   - Ruta hacia tu carpeta base de mclauncher (data)

Ejemplo:
```bash
chmod +x setup.sh
./setup.sh "/mnt/c/Users/pc/Downloads/Minecraft PE x86 0.15.10 - www.MadCraft.ir.apk" "/mnt/c/Users/pc/Downloads/MCLauncher/Minecraft-0.15.10.0"
```

## Ejecución del Juego

Una vez completado el script, puedes iniciar el juego desde WSL con:

```bash
cd ~/lachy-launcher
WAYLAND_DISPLAY="" ./build/mcpelauncher-client/mcpelauncher-client -dg ~/mc
```

*Nota: Usamos `WAYLAND_DISPLAY=""` para forzar a GLFW a utilizar X11 debido a problemas con la captura del ratón en Wayland sobre WSLg.*
