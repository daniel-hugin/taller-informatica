#!/usr/bin/env bash
# 50-energia - Suspender, nunca apagar.
#
# Cerrar la tapa y abrirla al día siguiente en el punto exacto donde se
# dejó, con las ventanas abiertas. Dos segundos en lugar de noventa.
# Esto también resuelve parte del problema de continuidad entre sesiones.

# Guardián: este módulo no es autónomo. Se carga con `source` desde
# install.sh, que antes ha cargado lib/comun.sh (RAIZ, taller.conf,
# ejecuta/info/...). Ejecutarlo suelto arranca un proceso nuevo sin nada de
# eso, y cada línea falla con "orden no encontrada".
if ! declare -F ejecuta >/dev/null || [ -z "${RAIZ:-}" ]; then
  echo "Este módulo no se ejecuta solo. Usa: sudo ./install.sh $(basename "${BASH_SOURCE[0]%.sh}")" >&2
  exit 1
fi

CONF=/etc/systemd/logind.conf.d/taller.conf
TMP="$(mktemp)"

cat > "$TMP" <<LOGIND
# Gestionado por el taller. Suspender al cerrar la tapa, en cualquier caso.
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=suspend
IdleAction=suspend
IdleActionSec=30min
LOGIND

# Reiniciar logind afecta a la sesión gráfica activa, así que solo se hace
# si el contenido realmente cambia, no en cada ejecución de install.sh.
if [ -f "$CONF" ] && cmp -s "$TMP" "$CONF"; then
  cambiado=0
else
  cambiado=1
fi

info "Configurando comportamiento de la tapa"
copia_si_distinto "$TMP" "$CONF"
rm -f "$TMP"

if [ "$cambiado" = "1" ]; then
  ejecuta systemctl restart systemd-logind || avisa "No se pudo recargar logind (normal dentro de un contenedor)"
else
  salta "logind ya configurado, no hace falta reiniciarlo"
fi

ok "Energía configurada"
