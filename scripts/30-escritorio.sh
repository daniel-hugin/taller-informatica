#!/usr/bin/env bash
# 30-escritorio - XFCE con fricción cero.
#
# Con sesiones de 30 minutos, cada segundo de arranque es el 0,05% del
# tiempo útil y, peor, el momento exacto en que un niño de 7 años se
# distrae. Todo lo de aquí persigue reducir pasos entre abrir la tapa
# y estar trabajando.

# La configuración de XFCE se despliega vía /etc/skel, de modo que
# cualquier cuenta nueva la hereda.
if [ -d "$RAIZ/skel" ] && [ -n "$(ls -A "$RAIZ/skel" 2>/dev/null)" ]; then
  info "Desplegando configuración de escritorio en /etc/skel"
  for f in $(cd "$RAIZ/skel" && find . -type f); do
    copia_si_distinto "$RAIZ/skel/$f" "/etc/skel/${f#./}"
  done
else
  salta "no hay configuración en skel/ todavía"
fi

# Lanzador de cambio rápido de usuario. El cambio de turno tiene que ser
# un gesto visible, no una excursión por los menús.
LANZADOR=/usr/local/share/applications/taller-cambiar-usuario.desktop
if [ -f "$LANZADOR" ]; then
  salta "lanzador de cambio de usuario ya existe"
else
  info "Creando lanzador de cambio de usuario"
  ejecuta install -d /usr/local/share/applications
  ejecuta bash -c 'cat > '"$LANZADOR"' <<DESKTOP
[Desktop Entry]
Type=Application
Name=Cambiar de niño
Comment=Cambiar de sesión sin cerrar nada
Icon=system-users
Exec=dm-tool switch-to-greeter
Categories=System;
DESKTOP'
fi

# Pantalla de login legible. Fuente grande y sin indicadores de más.
if [ -d "$RAIZ/skel-etc" ]; then
  info "Desplegando configuración del gestor de sesión"
  for f in $(cd "$RAIZ/skel-etc" && find . -type f); do
    copia_si_distinto "$RAIZ/skel-etc/$f" "/etc/${f#./}"
  done
fi

# Autologin desactivado a propósito: la pantalla de selección de usuario
# es útil aquí, porque el icono propio es el gesto de "ahora me toca a mí".
# Sin contraseña todavía; llega en la fase 3 con la entrega de sudo.

ok "Escritorio configurado"
