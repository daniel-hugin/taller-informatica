#!/usr/bin/env bash
# 10-paquetes - Instala el software del taller.
#
# Las listas viven en config/*.txt, no aquí. Para adaptar el taller,
# edita esos ficheros: no hace falta tocar bash.

# Guardián: este módulo no es autónomo. Se carga con `source` desde
# install.sh, que antes ha cargado lib/comun.sh (RAIZ, taller.conf,
# ejecuta/info/...). Ejecutarlo suelto arranca un proceso nuevo sin nada de
# eso, y cada línea falla con "orden no encontrada".
if ! declare -F ejecuta >/dev/null || [ -z "${RAIZ:-}" ]; then
  echo "Este módulo no se ejecuta solo. Usa: sudo ./install.sh $(basename "${BASH_SOURCE[0]%.sh}")" >&2
  exit 1
fi

info "Paquetes base del sistema"
instala_lista "$RAIZ/config/paquetes-base.txt"

# Se instalan las listas de los tramos activos declarados en taller.conf.
for tramo in $TRAMOS_ACTIVOS; do
  lista="$RAIZ/config/paquetes-$tramo.txt"
  if [ -f "$lista" ]; then
    info "Paquetes del tramo $tramo"
    instala_lista "$lista"
  else
    avisa "No existe lista para el tramo $tramo (se ignora)"
  fi
done

ok "Software instalado"
