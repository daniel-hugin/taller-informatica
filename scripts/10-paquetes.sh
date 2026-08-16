#!/usr/bin/env bash
# 10-paquetes - Instala el software del taller.
#
# Las listas viven en config/*.txt, no aquí. Para adaptar el taller,
# edita esos ficheros: no hace falta tocar bash.

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
