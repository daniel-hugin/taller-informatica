#!/usr/bin/env bash
#
# probar.sh - Valida el repositorio sin tocar la máquina de los niños.
#
#   ./probar.sh              # comprobaciones estáticas + simulación
#   ./probar.sh --vm         # además, levanta un contenedor Debian limpio
#
# La comprobación estática no necesita permisos ni Debian. La de contenedor
# necesita podman o docker.

set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fallos=0

titulo() { printf '\n\033[34m==>\033[0m %s\n' "$*"; }
bien()   { printf '  \033[32mok\033[0m %s\n' "$*"; }
mal()    { printf '  \033[31mXX\033[0m %s\n' "$*"; fallos=$((fallos+1)); }

titulo "Sintaxis de bash"
for f in "$RAIZ"/install.sh "$RAIZ"/probar.sh "$RAIZ"/lib/*.sh "$RAIZ"/scripts/*.sh "$RAIZ"/config/taller.ejemplo.conf; do
  if bash -n "$f" 2>/dev/null; then bien "$(basename "$f")"; else mal "$(basename "$f")"; fi
done

titulo "shellcheck (si está disponible)"
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -e SC1090,SC1091,SC2154,SC2317 "$RAIZ"/install.sh "$RAIZ"/lib/*.sh "$RAIZ"/scripts/*.sh; then
    bien "sin avisos"
  else
    mal "shellcheck ha encontrado problemas"
  fi
else
  printf '  -- shellcheck no instalado, se omite\n'
fi

titulo "Listas de paquetes"
for f in "$RAIZ"/config/paquetes-*.txt; do
  n=$(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$f" | wc -l)
  [ "$n" -gt 0 ] && bien "$(basename "$f"): $n paquete(s)" || mal "$(basename "$f") vacío"
done

titulo "xorg en paquetes-base.txt"
if sed -e 's/#.*//' "$RAIZ/config/paquetes-base.txt" | grep -qx 'xorg'; then
  bien "xorg presente"
else
  mal "falta 'xorg' en config/paquetes-base.txt: lightdm arrancará sin servidor X (Active: failed)"
fi

titulo "Configuración de escritorio (XML)"
if [ -n "$(find "$RAIZ/skel" -name '*.xml' 2>/dev/null)" ]; then
  while IFS= read -r x; do
    if python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse('$x')" 2>/dev/null; then
      bien "$(basename "$x")"
    else
      mal "$(basename "$x") XML inválido"
    fi
  done < <(find "$RAIZ/skel" -name '*.xml' | sort)
else
  mal "skel/ sin configuración de escritorio"
fi

titulo "Fichas de actividad"
total=0; probadas=0
while IFS= read -r ficha; do
  total=$((total+1))
  grep -q '`probado`' "$ficha" && probadas=$((probadas+1))
  for seccion in "## Objetivo" "## Cómo arrancar" "## Dónde se atascan" "## Señal de que lo tienen"; do
    grep -qF "$seccion" "$ficha" || mal "$(dirname "${ficha#"$RAIZ"/}") sin sección '$seccion'"
  done
done < <(find "$RAIZ/actividades" -mindepth 3 -name README.md | sort)
bien "$total ficha(s), $probadas probada(s)"

titulo "Simulación de la instalación"
if [ ! -f "$RAIZ/config/taller.conf" ]; then
  printf '  -- config/taller.conf no existe, se omite (copia config/taller.ejemplo.conf)\n'
elif [ -f /etc/debian_version ]; then
  if "$RAIZ/install.sh" --dry-run >/dev/null 2>&1; then bien "dry-run limpio"; else mal "dry-run ha fallado"; fi
else
  printf '  -- no es Debian, se omite\n'
fi

if [ "${1:-}" = "--vm" ]; then
  titulo "Contenedor Debian limpio"
  motor=""
  command -v podman >/dev/null 2>&1 && motor=podman
  [ -z "$motor" ] && command -v docker >/dev/null 2>&1 && motor=docker
  if [ -z "$motor" ]; then
    mal "ni podman ni docker disponibles"
  else
    "$motor" run --rm -v "$RAIZ:/taller:ro" debian:stable \
      bash -c 'apt-get update -qq && cd /taller && ./install.sh --dry-run' \
      && bien "instalación simulada en Debian limpia" || mal "fallo en contenedor"
  fi
fi

printf '\n'
[ "$fallos" -eq 0 ] && { printf '\033[32mTodo correcto.\033[0m\n'; exit 0; }
printf '\033[31m%d problema(s).\033[0m\n' "$fallos"; exit 1
