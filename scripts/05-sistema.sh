#!/usr/bin/env bash
# 05-sistema - Preparación base del sistema.
#
# Todo lo que hasta ahora estaba en la guía como pasos manuales. Lo que vive
# en un documento y no en un script acaba ejecutándose distinto cada vez, y
# esa deriva es justo lo que este repositorio existe para evitar.
#
# Se ejecuta antes que 10-paquetes porque toca los repositorios: sin
# non-free-firmware no hay firmware de WiFi en el T430, y la instalación
# posterior fallaría a medias.

# ---------------------------------------------------------------------------
# Repositorios
# ---------------------------------------------------------------------------
# Debian 13 usa el formato deb822 en /etc/apt/sources.list.d/debian.sources.
# Las instalaciones más antiguas o migradas pueden seguir en el formato de
# una línea. Se contemplan los dos.

habilita_componentes() {
  local deb822=/etc/apt/sources.list.d/debian.sources
  local clasico=/etc/apt/sources.list
  local cambiado=0

  # La comprobación mira línea a línea, no "¿aparece en algún sitio del
  # fichero?": así una línea (p. ej. la de security) a la que aún le falta
  # un componente no se confunde con "ya está hecho" solo porque otra línea
  # del fichero sí lo tenga. El añadido también es por línea y por palabra,
  # así que nunca puede dejar "contrib contrib" duplicado.
  if [ -f "$deb822" ]; then
    if grep '^Components:' "$deb822" | grep -qvE '\bcontrib\b.*\bnon-free-firmware\b|\bnon-free-firmware\b.*\bcontrib\b'; then
      info "Añadiendo contrib y non-free-firmware a debian.sources"
      ejecuta cp -n "$deb822" "$deb822.taller-backup"
      ejecuta sed -i -E '/^Components:/ { /\bcontrib\b/! s/$/ contrib/; /\bnon-free-firmware\b/! s/$/ non-free-firmware/ }' "$deb822"
      cambiado=1
    else
      salta "componentes ya habilitados en debian.sources"
    fi
  fi

  if [ -f "$clasico" ] && grep -qE '^deb .*main' "$clasico"; then
    if grep -E '^deb .*main' "$clasico" | grep -qvE '\bcontrib\b.*\bnon-free-firmware\b|\bnon-free-firmware\b.*\bcontrib\b'; then
      info "Añadiendo contrib y non-free-firmware a sources.list"
      ejecuta cp -n "$clasico" "$clasico.taller-backup"
      ejecuta sed -i -E '/^deb .*main/ { /\bcontrib\b/! s/$/ contrib/; /\bnon-free-firmware\b/! s/$/ non-free-firmware/ }' "$clasico"
      cambiado=1
    else
      salta "componentes ya habilitados en sources.list"
    fi
  fi

  if [ "$cambiado" = "1" ]; then
    info "Refrescando índices tras cambiar los repositorios"
    ejecuta apt-get update
  fi
}

info "Repositorios"
habilita_componentes

# ---------------------------------------------------------------------------
# Actualización inicial
# ---------------------------------------------------------------------------
# La netinst instala con paquetes al día, pero entre que descargas la ISO y
# ejecutas esto pueden haber pasado semanas.

if [ "${OMITIR_UPGRADE:-0}" = "1" ]; then
  salta "actualización omitida (OMITIR_UPGRADE=1)"
else
  info "Actualizando el sistema"
  ejecuta apt-get upgrade -y
fi

# ---------------------------------------------------------------------------
# Firmware
# ---------------------------------------------------------------------------
# El T430 lleva WiFi Intel (Centrino Advanced-N 6205 en la mayoría de
# configuraciones) y gráficos Intel HD 4000. Ambos necesitan firmware que
# vive en non-free-firmware.
#
# Se detecta el fabricante en vez de instalar a ciegas: el repositorio debe
# funcionar también en máquinas que no sean un ThinkPad.

info "Firmware"
if lspci 2>/dev/null | grep -qi 'network.*intel\|wireless.*intel'; then
  instala_lista <(printf 'firmware-iwlwifi\n')
else
  salta "no se detecta WiFi Intel"
fi

if lspci 2>/dev/null | grep -qi 'vga.*intel'; then
  instala_lista <(printf 'firmware-misc-nonfree\nintel-microcode\n')
else
  salta "no se detectan gráficos Intel"
fi

# ---------------------------------------------------------------------------
# Localización
# ---------------------------------------------------------------------------
# El instalador suele dejarlo bien si se eligió español, pero una imagen
# genérica o una instalación desatendida puede no hacerlo. Sin esto, los
# acentos de las actividades salen rotos.

LOCALE_OBJETIVO="${LOCALE_TALLER:-es_ES.UTF-8}"

info "Localización ($LOCALE_OBJETIVO)"
if locale -a 2>/dev/null | grep -qi "^${LOCALE_OBJETIVO//-/}$\|^${LOCALE_OBJETIVO%.*}.utf8$"; then
  salta "locale $LOCALE_OBJETIVO ya generado"
else
  info "Generando $LOCALE_OBJETIVO"
  ejecuta sed -i "s/^# *\(${LOCALE_OBJETIVO} UTF-8\)/\1/" /etc/locale.gen
  ejecuta locale-gen
  ejecuta update-locale "LANG=$LOCALE_OBJETIVO" "LC_ALL=$LOCALE_OBJETIVO"
fi

# Zona horaria
ZONA="${ZONA_HORARIA:-Europe/Madrid}"
if [ "$(timedatectl show -p Timezone --value 2>/dev/null)" = "$ZONA" ]; then
  salta "zona horaria ya es $ZONA"
else
  info "Estableciendo zona horaria: $ZONA"
  ejecuta timedatectl set-timezone "$ZONA" || avisa "No se pudo fijar la zona horaria"
fi

# Teclado en consola.
# clave_en_fichero y no linea_en_fichero: /etc/default/keyboard YA trae un
# XKBLAYOUT (normalmente "us"), así que añadir una línea dejaría dos claves
# contradictorias en el fichero.
info "Teclado de consola"
clave_en_fichero /etc/default/keyboard XKBLAYOUT "${TECLADO:-es}"

# ---------------------------------------------------------------------------
# Comprobaciones que no arreglan nada, solo avisan
# ---------------------------------------------------------------------------
# El script no debe tomar decisiones sobre el disco por su cuenta, pero sí
# debe decirte si algo importante falta.

info "Comprobaciones"

if mountpoint -q /home; then
  ok "/home está en partición separada"
else
  avisa "/home NO está en partición separada."
  avisa "La continuidad ES el taller: sin esto, saltar a Debian 14 dentro de"
  avisa "tres años pone en riesgo todo lo que hayan hecho. Considera reinstalar."
fi

if [ -d /sys/firmware/efi ]; then
  salta "arranque UEFI"
else
  salta "arranque BIOS/legacy"
fi

RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if [ "$RAM_MB" -lt 2048 ]; then
  avisa "Solo ${RAM_MB} MB de RAM: XFCE irá justo"
else
  ok "${RAM_MB} MB de RAM"
fi

LIBRE_GB=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')
if [ "${LIBRE_GB:-0}" -lt 8 ]; then
  avisa "Solo ${LIBRE_GB} GB libres en /: puede no bastar para el escritorio"
else
  ok "${LIBRE_GB} GB libres en /"
fi

if command -v smartctl >/dev/null 2>&1 && [ -n "${DISPOSITIVO_HDD:-}" ] && [ -b "${DISPOSITIVO_HDD:-}" ]; then
  HORAS=$(smartctl -A "$DISPOSITIVO_HDD" 2>/dev/null | awk '/Power_On_Hours/ {print $10}')
  REALOC=$(smartctl -A "$DISPOSITIVO_HDD" 2>/dev/null | awk '/Reallocated_Sector_Ct/ {print $10}')
  if [ -n "$HORAS" ]; then
    ok "HDD: ${HORAS} h encendido, ${REALOC:-?} sectores reasignados"
    [ "${REALOC:-0}" -gt 0 ] 2>/dev/null && \
      avisa "Hay sectores reasignados: no confíes al HDD ninguna copia única"
  fi
fi

ok "Sistema preparado"
