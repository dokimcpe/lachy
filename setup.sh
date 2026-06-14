#!/bin/bash
# Script de instalación automatizada para Minecraft PE 0.15.10 x86 en WSL2
# Creado para simplificar la configuración de mcpelauncher y la extracción de assets desde el APK.

set -e

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <Ruta_al_APK_de_Minecraft> <Ruta_a_la_carpeta_Minecraft-0.15.10.0>"
    echo "Ejemplo: $0 \"/mnt/c/Users/pc/Downloads/Minecraft.apk\" \"/mnt/c/Users/pc/Downloads/MCLauncher/Minecraft-0.15.10.0\""
    exit 1
fi

APK_PATH="$1"
MC_DATA_PATH="$2"

echo "=== Paso 1: Instalando dependencias del sistema ==="
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y \
    cmake g++ g++-multilib \
    libpng-dev:i386 libx11-dev:i386 libxi-dev:i386 \
    libcurl4-openssl-dev:i386 libudev-dev:i386 \
    libevdev-dev:i386 libegl1-mesa-dev:i386 \
    libgles2-mesa-dev:i386 libasound2-dev:i386 \
    libxext-dev:i386 gcc-multilib build-essential \
    libwayland-dev:i386 libxkbcommon-dev:i386 \
    libxinerama-dev:i386 libxcursor-dev:i386 libxrandr-dev:i386 \
    unzip git

echo "=== Paso 2: Preparando la carpeta del juego híbrida (~/mc) ==="
mkdir -p ~/mc/lib/x86
echo "Extrayendo librerías del APK..."
unzip -jo "$APK_PATH" "lib/x86/*" -d ~/mc/lib/x86/
chmod +x ~/mc/lib/x86/*.so

echo "Extrayendo assets de idiomas del APK..."
unzip -o "$APK_PATH" "assets/*" -d ~/mc/

echo "Copiando carpeta data original..."
cp -r "$MC_DATA_PATH/data" ~/mc/data

echo "=== Paso 3: Configurando el Launcher ==="
if [ ! -d ~/lachy-launcher ]; then
    echo "Clonando repositorio de Lachy-Launcher..."
    git clone https://github.com/ry-diffusion/Lachy-Launcher ~/lachy-launcher
fi

cd ~/lachy-launcher

echo "Aplicando parche de WSLg en GLFW (Raw Mouse Fix)..."
GLFW_FILE="game-window/src/window_glfw.cpp"
GLFW_HEADER="game-window/src/window_glfw.h"

# Modificar archivo Header
if ! grep -q "skipNextMouseEvent" "$GLFW_HEADER"; then
    sed -i 's/bool focused = true;/bool focused = true;\n  bool skipNextMouseEvent = false;/g' "$GLFW_HEADER"
fi

# Parche de sensibilidad y delta en CPP (sólo si no se ha aplicado antes)
if ! grep -q "WSLg raw motion fix" "$GLFW_FILE"; then
    sed -i 's/double dx = x - user->lastMouseX;/double dx = x - user->lastMouseX;\n\n    user->lastMouseX = x;\n    user->lastMouseY = y;\n\n    if (user->skipNextMouseEvent) {\n      user->skipNextMouseEvent = false;\n      return;\n    }\n\n    const double maxDelta = 30.0;\n    if (dx > maxDelta) dx = maxDelta;\n    if (dx < -maxDelta) dx = -maxDelta;\n    if (dy > maxDelta) dy = maxDelta;\n    if (dy < -maxDelta) dy = -maxDelta;\n\n    dx *= 0.25;\n    dy *= 0.25;/g' "$GLFW_FILE"
    
    # Borrar la línea repetida de dx/dy manuales
    sed -i '/user->lastMouseX = x;/d' "$GLFW_FILE"
    sed -i '/user->lastMouseY = y;/d' "$GLFW_FILE"
    
    # Parchear el cursor disabled
    sed -i 's/glfwGetCursorPos(window, &lastMouseX, &lastMouseY);/glfwGetCursorPos(window, &lastMouseX, &lastMouseY);\n  skipNextMouseEvent = disabled;/g' "$GLFW_FILE"
fi

echo "=== Paso 4: Compilando el Launcher ==="
rm -rf build
cmake -B build -S . \
    -DGAMEWINDOW_SYSTEM=GLFW \
    -DCMAKE_TOOLCHAIN_FILE=cmake/linux32.cmake \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build -j$(nproc)

echo "=== Instalación Completa! ==="
echo "Para jugar, ejecuta: "
echo "cd ~/lachy-launcher"
echo "WAYLAND_DISPLAY=\"\" ./build/mcpelauncher-client/mcpelauncher-client -dg ~/mc"
