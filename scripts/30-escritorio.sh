#!/usr/bin/env bash
# 30-escritorio - XFCE con fricción cero.
#
# Con sesiones de 30 minutos, cada segundo de arranque es el 0,05% del
# tiempo útil y, peor, el momento exacto en que un niño de 7 años se
# distrae. Todo lo de aquí persigue reducir pasos entre abrir la tapa
# y estar trabajando.

# Guardián: este módulo no es autónomo. Se carga con `source` desde
# install.sh, que antes ha cargado lib/comun.sh (RAIZ, taller.conf,
# ejecuta/info/...). Ejecutarlo suelto arranca un proceso nuevo sin nada de
# eso, y cada línea falla con "orden no encontrada".
if ! declare -F ejecuta >/dev/null || [ -z "${RAIZ:-}" ]; then
  echo "Este módulo no se ejecuta solo. Usa: sudo ./install.sh $(basename "${BASH_SOURCE[0]%.sh}")" >&2
  exit 1
fi

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

# ---------------------------------------------------------------------------
# Cuentas ya creadas con /etc/skel desactualizado
# ---------------------------------------------------------------------------
# /etc/skel solo se copia al CREAR la cuenta. 20-usuarios se ejecuta antes
# que este módulo, así que en una primera pasada las cuentas nacen con el
# /etc/skel de fábrica, no con el del taller (Sans 14, icon-size 96...).
#
# No se sincroniza solo: a los 7 años elegir el fondo de pantalla es el
# primer acto de propiedad sobre la máquina, y sincronizar a ciegas lo
# pisaría. Por defecto solo se avisa; --sincronizar-escritorios lo aplica.
if [ -d "$RAIZ/skel" ] && [ -n "$(ls -A "$RAIZ/skel" 2>/dev/null)" ]; then
  logins_a_revisar=()
  for entrada in "${NINOS[@]}"; do
    logins_a_revisar+=("${entrada%%:*}")
  done
  logins_a_revisar+=("${CUENTA_COMPARTIDA:-taller}")

  desincronizadas=()
  for login in "${logins_a_revisar[@]}"; do
    home="$(getent passwd "$login" 2>/dev/null | cut -d: -f6)"
    [ -n "$home" ] && [ -d "$home" ] || continue

    desincronizada=0
    while IFS= read -r f; do
      cmp -s "$RAIZ/skel/$f" "$home/${f#./}" || { desincronizada=1; break; }
    done < <(cd "$RAIZ/skel" && find . -type f)

    [ "$desincronizada" = "1" ] && desincronizadas+=("$login")
  done

  if [ "${#desincronizadas[@]}" -eq 0 ]; then
    salta "todas las cuentas ya tienen el escritorio del taller"
  elif [ "${SINCRONIZAR_ESCRITORIOS:-0}" = "1" ]; then
    for login in "${desincronizadas[@]}"; do
      home="$(getent passwd "$login" | cut -d: -f6)"
      info "Sincronizando escritorio de $login (--sincronizar-escritorios)"
      ejecuta rsync -a --chown="$login:$login" "$RAIZ/skel/" "$home/"
    done
  else
    avisa "Cuentas con configuración de escritorio desactualizada: ${desincronizadas[*]}"
    avisa "Esto pisaría personalizaciones del niño (fondo, iconos...). Revisa antes de aplicar."
    avisa "Para sincronizar: sudo ./install.sh 30-escritorio --sincronizar-escritorios"
  fi
fi

# ---------------------------------------------------------------------------
# Comprobación: ¿hay servidor gráfico?
# ---------------------------------------------------------------------------
# xorg es un Recommends de xfce4, no un Depends: con --no-install-recommends
# (instala_lista) puede faltar aunque el resto se instale sin ningún aviso,
# y el fallo solo se ve al arrancar, con lightdm.service en
# "Active: failed (Result: exit-code)". Esto solo avisa, no instala nada:
# arreglar paquetes es cosa de 10-paquetes, no de este módulo.

if paquete_instalado xserver-xorg; then
  ok "xserver-xorg instalado"
else
  avisa "xserver-xorg NO está instalado: lightdm no tendrá servidor X y el"
  avisa "arranque se quedará en consola. Revisa config/paquetes-base.txt."
fi

objetivo_actual="$(systemctl get-default 2>/dev/null || echo '?')"
if [ "$objetivo_actual" = "graphical.target" ]; then
  ok "default target: graphical.target"
else
  avisa "El target por defecto es '$objetivo_actual', no graphical.target."
  avisa "Arréglalo con: sudo systemctl set-default graphical.target"
fi

ok "Escritorio configurado"
