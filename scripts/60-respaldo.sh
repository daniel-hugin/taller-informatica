#!/usr/bin/env bash
# 60-respaldo - Copia nocturna al homelab.
#
# Con uso diario hay estado nuevo cada día. Perder tres meses de dibujos
# por un SSD muerto sería un golpe difícil de reparar a esa edad.
#
# Un segundo disco en la misma máquina NO es una copia de seguridad:
# protege del borrado accidental, no del robo, el vaso de agua ni la
# fuente que se lleva por delante los dos discos.

# Guardián: este módulo no es autónomo. Se carga con `source` desde
# install.sh, que antes ha cargado lib/comun.sh (RAIZ, taller.conf,
# ejecuta/info/...). Ejecutarlo suelto arranca un proceso nuevo sin nada de
# eso, y cada línea falla con "orden no encontrada".
if ! declare -F ejecuta >/dev/null || [ -z "${RAIZ:-}" ]; then
  echo "Este módulo no se ejecuta solo. Usa: sudo ./install.sh $(basename "${BASH_SOURCE[0]%.sh}")" >&2
  exit 1
fi

if [ -z "${DESTINO_RESPALDO:-}" ]; then
  salta "DESTINO_RESPALDO sin definir en taller.conf: se omite este módulo"
  return 0 2>/dev/null || exit 0
fi

SCRIPT=/usr/local/bin/taller-respaldo
UNIDAD=/etc/systemd/system/taller-respaldo.service
TEMPORIZADOR=/etc/systemd/system/taller-respaldo.timer

TMP_SCRIPT="$(mktemp)"
TMP_UNIDAD="$(mktemp)"
TMP_TEMPORIZADOR="$(mktemp)"

cat > "$TMP_SCRIPT" <<RSYNC
#!/usr/bin/env bash
# Respaldo del taller. Instalado por el repositorio, no editar a mano.
set -euo pipefail
exec rsync -aAX --delete \
  --exclude=".cache/" \
  --exclude="*/Trash/*" \
  /home/ "$DESTINO_RESPALDO"
RSYNC

cat > "$TMP_UNIDAD" <<UNIT
[Unit]
Description=Respaldo del taller
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/taller-respaldo
UNIT

cat > "$TMP_TEMPORIZADOR" <<TIMER
[Unit]
Description=Respaldo nocturno del taller

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
TIMER

# daemon-reload y enable --now solo hacen falta si algo cambió realmente,
# no en cada ejecución de install.sh.
cambiado=0
if ! { [ -f "$SCRIPT" ] && cmp -s "$TMP_SCRIPT" "$SCRIPT"; }; then
  cambiado=1
fi
if ! { [ -f "$UNIDAD" ] && cmp -s "$TMP_UNIDAD" "$UNIDAD"; }; then
  cambiado=1
fi
if ! { [ -f "$TEMPORIZADOR" ] && cmp -s "$TMP_TEMPORIZADOR" "$TEMPORIZADOR"; }; then
  cambiado=1
fi

info "Instalando script de respaldo"
copia_si_distinto "$TMP_SCRIPT" "$SCRIPT" 0755
copia_si_distinto "$TMP_UNIDAD" "$UNIDAD"
copia_si_distinto "$TMP_TEMPORIZADOR" "$TEMPORIZADOR"
rm -f "$TMP_SCRIPT" "$TMP_UNIDAD" "$TMP_TEMPORIZADOR"

if [ "$cambiado" = "1" ]; then
  info "Activando temporizador"
  ejecuta systemctl daemon-reload || true
  ejecuta systemctl enable --now taller-respaldo.timer || avisa "No se pudo activar el temporizador"
else
  salta "respaldo ya configurado, nada que recargar"
fi

ok "Respaldo configurado"
