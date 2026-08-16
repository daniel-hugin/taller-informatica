#!/usr/bin/env bash
# 15-turtleblocks - Turtle Blocks, vendorizado.
#
# Debian no empaqueta Turtle Blocks: ni la actividad de Sugar
# (sugar-turtleart-activity) ni ninguna alternativa aparecen en trixie,
# comprobado contra packages.debian.org. Es la herramienta central del
# tramo 7-8 (ver docs/diseno.md, "Por qué Turtle Blocks antes que
# Scratch"), así que en vez de sustituirla se vendoriza la versión web
# oficial de Sugar Labs: es una app estática (HTML/JS con sus propias
# librerías ya incluidas) que no necesita la shell de Sugar ni compilarse.
#
# Fijado al tag v1.2 (commit ea311e1), no a una rama en movimiento. Es la
# última versión antes de que el proyecto se fusionara con Music Blocks:
# esa versión posterior pesa 4 veces más, se llama a sí misma "Music
# Blocks" y trae edición musical, exportación a LilyPond y documentación
# en seis idiomas que no pintan nada aquí. v1.2 además no llama a ningún
# CDN externo, así que funciona sin red una vez descargada.

REPO="https://github.com/sugarlabs/turtleblocksjs.git"
TAG="v1.2"
COMMIT_ESPERADO="ea311e131bf65a96d70ca00ff24b24cc4a28a789"
DEST=/opt/taller/turtleblocksjs

if [ -d "$DEST/.git" ] && [ "$(git -C "$DEST" rev-parse HEAD 2>/dev/null)" = "$COMMIT_ESPERADO" ]; then
  salta "Turtle Blocks ya está en $DEST"
else
  info "Descargando Turtle Blocks ($TAG) a $DEST"
  ejecuta rm -rf "$DEST"
  ejecuta install -d /opt/taller
  if ejecuta git clone --quiet --branch "$TAG" --depth 1 "$REPO" "$DEST"; then
    if [ "$DRY_RUN" != "1" ]; then
      COMMIT_REAL="$(git -C "$DEST" rev-parse HEAD)"
      [ "$COMMIT_REAL" = "$COMMIT_ESPERADO" ] || \
        muere "Turtle Blocks: el commit descargado ($COMMIT_REAL) no es el esperado ($COMMIT_ESPERADO)"
    fi
  else
    avisa "No se pudo descargar Turtle Blocks (¿sin red?). Se omite el resto del módulo."
    return 0 2>/dev/null || exit 0
  fi
fi

# Servido en local con http.server, tal y como recomienda el propio
# proyecto en su package.json ("serve": "python3 -m http.server 3000
# --bind 127.0.0.1"). file:// no basta: los módulos que carga vía
# require.js hacen peticiones que algunos navegadores bloquean si no
# vienen de http(s).
UNIDAD=/etc/systemd/system/taller-turtleblocks.service
TMP_UNIDAD="$(mktemp)"

cat > "$TMP_UNIDAD" <<UNIT
[Unit]
Description=Turtle Blocks (servidor local)
After=network.target

[Service]
Type=simple
WorkingDirectory=$DEST
ExecStart=/usr/bin/python3 -m http.server 3000 --bind 127.0.0.1
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

if [ -f "$UNIDAD" ] && cmp -s "$TMP_UNIDAD" "$UNIDAD"; then
  cambiado=0
else
  cambiado=1
fi

info "Configurando el servidor local de Turtle Blocks"
copia_si_distinto "$TMP_UNIDAD" "$UNIDAD"
rm -f "$TMP_UNIDAD"

if [ "$cambiado" = "1" ]; then
  ejecuta systemctl daemon-reload || true
  ejecuta systemctl enable --now taller-turtleblocks.service || avisa "No se pudo activar el servidor de Turtle Blocks"
else
  salta "servidor de Turtle Blocks ya activo, nada que recargar"
fi

# Lanzador de escritorio, mismo patrón que "Cambiar de niño" en
# 30-escritorio.sh. Se abre directamente con firefox-esr (el único
# navegador del sistema) en vez de xdg-open, para no depender de que la
# asociación MIME por defecto esté bien puesta en el primer arranque.
LANZADOR=/usr/local/share/applications/taller-turtleblocks.desktop
if [ -f "$LANZADOR" ]; then
  salta "lanzador de Turtle Blocks ya existe"
else
  info "Creando lanzador de Turtle Blocks"
  ejecuta install -d /usr/local/share/applications
  ejecuta bash -c 'cat > '"$LANZADOR"' <<DESKTOP
[Desktop Entry]
Type=Application
Name=Turtle Blocks
Comment=Programar con bloques dibujando con la tortuga
Icon=applications-graphics
Exec=firefox-esr --new-window http://127.0.0.1:3000/index.html
Categories=Education;
DESKTOP'
fi

ok "Turtle Blocks configurado"
