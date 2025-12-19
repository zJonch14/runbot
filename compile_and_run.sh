#!/bin/bash
set -e # Sale inmediatamente si un comando falla

echo "========================================"
echo "INICIANDO SCRIPT DE COMPILACIÓN Y EJECUCIÓN"
echo "========================================"

# Limpiar directorio anterior
echo "Limpiando directorios anteriores..."
rm -rf BotUDPs 2>/dev/null || true

# Clonar el repositorio
echo "Clonando el repositorio..."
if git clone --verbose https://github.com/zJonch14/BotUDPs.git; then
  echo "Repositorio clonado exitosamente."
else
  echo "Error al clonar el repositorio. Saliendo..."
  exit 1
fi

# Entrar al directorio del repositorio
cd BotUDPs || { echo "No se pudo acceder al directorio BotUDPs"; exit 1; }

# Instalar dependencias (asumiendo que usas Python)
echo "Instalando dependencias..."
python -m pip install --upgrade pip
pip install -r requirements.txt

# Compilación de binarios C
echo "========================================"
echo "COMPILANDO TODOS LOS BINARIOS C"
echo "========================================"

# Crear lista de métodos C a compilar
declare -A c_programs=(
  ["udp.c"]="UDP Flood"
  ["udphex.c"]="UDPHEX"
  ["udppps.c"]="UDPPPS"
  ["ovh.c"]="OVH Bypass"
  ["udppayload.c"]="UDP Payload"
)

compiled_c=0
failed_c=0

for source_file in "${!c_programs[@]}"; do
  echo ""
  echo "🔨 ${c_programs[$source_file]} ($source_file)"
  if [ -f "$source_file" ]; then
    binary="${source_file%.c}"

    # Compilar según el tipo de archivo
    if [ "$source_file" == "ovh.c" ]; then
      # OVH necesita libpcap
      gcc -O3 -pthread "$source_file" -o "$binary" -lpcap 2>/dev/null
    else
      # Otros métodos
      gcc -O3 -pthread "$source_file" -o "$binary" 2>/dev/null
    fi

    if [ -f "$binary" ]; then
      chmod +x "$binary"
      echo " ✅ $binary compilado exitosamente"
      ((compiled_c++))
    else
      echo " ❌ Error compilando $binary"
      ((failed_c++))
    fi
  else
    echo " ❌ $source_file no encontrado"
    ((failed_c++))
  fi
done

# Compilación de Go
echo "========================================"
echo "COMPILANDO PROGRAMAS GO"
echo "========================================"

compiled_go=0
failed_go=0

# Compile udpflood.go
if [ -f "udpflood.go" ]; then
  go build -o udpflood udpflood.go 2>/dev/null
  if [ -f "udpflood" ]; then
    chmod +x udpflood
    echo " ✅ udpflood compilado exitosamente"
    ((compiled_go++))
  else
    echo " ❌ Error compilando udpflood.go"
    ((failed_go++))
  fi
else
  echo " ❌ udpflood.go no encontrado"
  ((failed_go++))
fi

# Compile raknet.go
if [ -f "raknet.go" ]; then
  go build -o raknet raknet.go 2>/dev/null
  if [ -f "raknet" ]; then
    chmod +x raknet
    echo " ✅ raknet compilado exitosamente"
    ((compiled_go++))
  else
    echo " ❌ Error compilando raknet.go"
    ((failed_go++))
  fi
else
  echo " ❌ raknet.go no encontrado"
  ((failed_go++))
fi

echo ""
echo "========================================"
echo "RESULTADO COMPILACIÓN:"
echo " ✅ $compiled_c programas C compilados correctamente"
echo " ❌ $failed_c programas C con errores"
echo " ✅ $compiled_go programas Go compilados correctamente"
echo " ❌ $failed_go programas Go con errores"
echo ""

# Imprimir la lista de ejecutables de forma segura
echo "EJECUTABLES DISPONIBLES:"
find . -maxdepth 1 -type f -executable ! -name "*.py" ! -name "*.go" ! -name "*.sh" -print0 | while IFS= read -r -d $'\0' file; do
  base=$(basename "$file")
  echo "   - $base"
done
total_compiled=$((compiled_c + compiled_go))
if [ "$total_compiled" -eq 0 ]; then
    echo "   Ninguno"
fi

echo "========================================"

# Ejecutar el bot UDP (asumiendo que usa Python)
echo "Ejecutando el bot UDP..."
python bot.py

echo "========================================"
echo "SCRIPT DE COMPILACIÓN Y EJECUCIÓN FINALIZADO"
echo "========================================"
