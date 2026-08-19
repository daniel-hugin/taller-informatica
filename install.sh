#!/usr/bin/env bash
#
# install.sh - Orquestador del taller de informática.
#
#   sudo ./install.sh                  # todo
#   sudo ./install.sh --dry-run        # enseña lo que haría, sin tocar nada
#   sudo ./install.sh 20-usuarios      # solo un módulo
#   ./install.sh --lista               # lista los módulos disponibles
#   sudo ./install.sh --sincronizar-escritorios   # 30-escritorio: aplica el
#                                                  # /etc/skel del taller a
#                                                  # cuentas ya creadas
#
# Todos los módulos son idempotentes. Reejecutar es seguro y es el modo
# previsto de trabajo: cuando quieras añadir algo, edita config/ y relanza.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RAIZ
# shellcheck source=lib/comun.sh
source "$RAIZ/lib/comun.sh"

modulos() {
  find "$RAIZ/scripts" -maxdepth 1 -name '[0-9][0-9]-*.sh' -type f | sort
}

uso() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

SELECCION=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; export DRY_RUN ;;
    --sincronizar-escritorios) SINCRONIZAR_ESCRITORIOS=1; export SINCRONIZAR_ESCRITORIOS ;;
    --lista|-l)
      for m in $(modulos); do basename "$m" .sh; done
      exit 0 ;;
    --help|-h) uso ;;
    -*) muere "Opción desconocida: $1" ;;
    *)  SELECCION+=("$1") ;;
  esac
  shift
done

requiere_debian
[ "$DRY_RUN" = "1" ] || requiere_root

if [ "$DRY_RUN" = "1" ]; then
  avisa "MODO SIMULACIÓN: no se va a modificar nada."
fi

# Refrescar índices una sola vez, no en cada módulo.
if [ "${#SELECCION[@]}" -eq 0 ] || printf '%s\n' "${SELECCION[@]}" | grep -q paquetes; then
  info "Actualizando índices de apt"
  ejecuta apt-get update
fi

ejecutados=0
for modulo in $(modulos); do
  nombre="$(basename "$modulo" .sh)"

  if [ "${#SELECCION[@]}" -gt 0 ]; then
    if ! printf '%s\n' "${SELECCION[@]}" | grep -qx "$nombre"; then
      continue
    fi
  fi

  printf '\n'
  info "== $nombre =="
  # shellcheck source=/dev/null
  source "$modulo"
  ejecutados=$((ejecutados + 1))
done

if [ "$ejecutados" -eq 0 ]; then
  muere "Ningún módulo coincide. Prueba ./install.sh --lista"
fi

printf '\n'
ok "Hecho. $ejecutados módulo(s) aplicado(s)."
if [ "$DRY_RUN" = "1" ]; then
  avisa "Recuerda: era una simulación. Relanza sin --dry-run para aplicar."
fi
