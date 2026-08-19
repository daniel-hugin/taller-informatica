#!/usr/bin/env bash
# 40-almacenamiento - Reparto entre SSD y HDD.
#
#   SSD  -> sistema y /home. Su trabajo diario, con respuesta instantánea.
#   HDD  -> contenido offline, archivo histórico e imágenes de VM.
#
# El archivo vive en un soporte físico distinto del sistema a propósito:
# así una reinstalación del SSD no puede tocarlo. Es una frontera más
# fuerte que una partición.

# Guardián: este módulo no es autónomo. Se carga con `source` desde
# install.sh, que antes ha cargado lib/comun.sh (RAIZ, taller.conf,
# ejecuta/info/...). Ejecutarlo suelto arranca un proceso nuevo sin nada de
# eso, y cada línea falla con "orden no encontrada".
if ! declare -F ejecuta >/dev/null || [ -z "${RAIZ:-}" ]; then
  echo "Este módulo no se ejecuta solo. Usa: sudo ./install.sh $(basename "${BASH_SOURCE[0]%.sh}")" >&2
  exit 1
fi

if [ -z "${DIR_HDD:-}" ]; then
  salta "DIR_HDD sin definir en taller.conf: se omite este módulo"
  return 0 2>/dev/null || exit 0
fi

if [ ! -d "$DIR_HDD" ]; then
  avisa "No existe $DIR_HDD. ¿Está montado el HDD? Se omite el módulo."
  return 0 2>/dev/null || exit 0
fi

crea_directorio "$DIR_HDD/kiwix"   "root:taller" 2775   # Wikipedia offline
crea_directorio "$DIR_HDD/archivo" "root:taller" 2775   # producción histórica
crea_directorio "$DIR_HDD/vm"      "root:taller" 2775   # fase 3

# Una carpeta por año dentro del archivo. Que a los 12 pueda abrir lo que
# hizo a los 7 no es nostalgia: es la prueba tangible de que ha crecido.
crea_directorio "$DIR_HDD/archivo/$(date +%Y)" "root:taller" 2775

# El HDD es la pieza más frágil del portátil: un plato girando dentro de
# una máquina que dos críos mueven de sitio. Dormirlo cuando no se usa lo
# deja parado la mayor parte del tiempo.
if [ -n "${DISPOSITIVO_HDD:-}" ] && [ -b "${DISPOSITIVO_HDD:-}" ]; then
  info "Configurando spindown en $DISPOSITIVO_HDD"
  ejecuta hdparm -S "${SPINDOWN:-120}" "$DISPOSITIVO_HDD"
  linea_en_fichero /etc/hdparm.conf "$DISPOSITIVO_HDD { spindown_time = ${SPINDOWN:-120} }"
else
  salta "DISPOSITIVO_HDD sin definir o no es un dispositivo de bloque"
fi

ok "Almacenamiento configurado"
