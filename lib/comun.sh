#!/usr/bin/env bash
# Biblioteca común del taller.
# Se carga desde install.sh y desde cada script de scripts/.
#
# Todo lo que hay aquí es idempotente: ejecutarlo N veces deja el sistema
# en el mismo estado que ejecutarlo una vez.

set -euo pipefail

# ---------------------------------------------------------------------------
# Estado global
# ---------------------------------------------------------------------------

DRY_RUN="${DRY_RUN:-0}"
RAIZ="${RAIZ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Configuración del taller. Es el único fichero que hay que tocar para
# adaptar el repositorio a otro caso.
if [ -f "$RAIZ/config/taller.conf" ]; then
  # shellcheck source=../config/taller.conf
  source "$RAIZ/config/taller.conf"
else
  echo "No existe $RAIZ/config/taller.conf — copia config/taller.ejemplo.conf y edítalo." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Salida
# ---------------------------------------------------------------------------

if [ -t 1 ]; then
  C_AZUL=$'\033[34m'; C_VERDE=$'\033[32m'; C_AMBAR=$'\033[33m'
  C_ROJO=$'\033[31m'; C_GRIS=$'\033[90m';  C_OFF=$'\033[0m'
else
  C_AZUL=''; C_VERDE=''; C_AMBAR=''; C_ROJO=''; C_GRIS=''; C_OFF=''
fi

info()   { printf '%s==>%s %s\n'  "$C_AZUL"  "$C_OFF" "$*"; }
ok()     { printf '%s  ok%s %s\n' "$C_VERDE" "$C_OFF" "$*"; }
salta()  { printf '%s  --%s %s\n' "$C_GRIS"  "$C_OFF" "$*"; }
avisa()  { printf '%s  !!%s %s\n' "$C_AMBAR" "$C_OFF" "$*" >&2; }
muere()  { printf '%s  XX%s %s\n' "$C_ROJO"  "$C_OFF" "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Ejecución
# ---------------------------------------------------------------------------

# ejecuta <comando...>
# Respeta DRY_RUN. Es el único punto por el que deben pasar los cambios.
ejecuta() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '%s  ->%s %s\n' "$C_GRIS" "$C_OFF" "$*"
    return 0
  fi
  "$@"
}

requiere_root() {
  [ "$(id -u)" -eq 0 ] || muere "Este script necesita privilegios de root. Usa sudo."
}

requiere_debian() {
  [ -f /etc/debian_version ] || muere "Este taller está pensado para Debian. Detectado: $(uname -a)"
}

# ---------------------------------------------------------------------------
# Paquetes
# ---------------------------------------------------------------------------

# lee_lista <fichero>
# Devuelve los paquetes de un fichero, ignorando comentarios y líneas vacías.
lee_lista() {
  local f="$1"
  # Acepta ficheros regulares y sustituciones de proceso <(...)
  [ -f "$f" ] || [ -r "$f" ] || muere "No existe la lista de paquetes: $f"
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$f" | grep -v '^$' || true
}

paquete_instalado() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'
}

# paquete_existe <nombre>
# Un nombre de paquete puede cambiar entre versiones de Debian. Sin esta
# comprobación, un solo nombre obsoleto aborta la instalación entera y
# deja el sistema a medias.
paquete_existe() {
  apt-cache show "$1" >/dev/null 2>&1
}

# instala_lista <fichero>
# Instala solo lo que falte. Si no falta nada, no toca apt.
instala_lista() {
  local fichero="$1"
  local pendientes=()
  local ausentes=()
  local p

  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if paquete_instalado "$p"; then
      salta "$p ya instalado"
    elif ! paquete_existe "$p"; then
      avisa "$p NO EXISTE en esta versión de Debian: se omite"
      ausentes+=("$p")
    else
      pendientes+=("$p")
    fi
  done < <(lee_lista "$fichero")

  if [ "${#pendientes[@]}" -eq 0 ]; then
    salta "nada que instalar desde $(basename "$fichero")"
    return 0
  fi

  info "Instalando ${#pendientes[@]} paquete(s): ${pendientes[*]}"
  ejecuta apt-get install -y --no-install-recommends "${pendientes[@]}"

  if [ "${#ausentes[@]}" -gt 0 ]; then
    avisa "Revisa estos nombres en $(basename "$fichero"): ${ausentes[*]}"
    avisa "Búscalos con: apt-cache search <termino>"
  fi
}

# ---------------------------------------------------------------------------
# Ficheros
# ---------------------------------------------------------------------------

# linea_en_fichero <fichero> <linea>
# Añade la línea solo si no está ya. Este es el patrón que evita que un
# fichero crezca sin control al reejecutar.
linea_en_fichero() {
  local fichero="$1" linea="$2"
  if [ -f "$fichero" ] && grep -qxF "$linea" "$fichero"; then
    salta "línea ya presente en $fichero"
    return 0
  fi
  info "Añadiendo línea a $fichero"
  ejecuta bash -c "printf '%s\n' \"\$1\" >> \"\$2\"" _ "$linea" "$fichero"
}

# clave_en_fichero <fichero> <clave> <valor>
# Para ficheros tipo CLAVE="valor" (/etc/default/*). Sustituye la clave si
# ya existe, la añade si no.
#
# NO uses linea_en_fichero para esto: solo comprueba si la línea exacta está,
# así que dejaría el fichero con dos claves contradictorias. Es idempotente
# entre pasadas, pero deja el sistema permanentemente incoherente desde la
# primera.
clave_en_fichero() {
  local fichero="$1" clave="$2" valor="$3"
  local deseada="${clave}=\"${valor}\""

  if [ -f "$fichero" ] && grep -qxF "$deseada" "$fichero"; then
    salta "$clave ya vale $valor en $(basename "$fichero")"
    return 0
  fi

  if [ -f "$fichero" ] && grep -qE "^[[:space:]]*${clave}=" "$fichero"; then
    info "Cambiando $clave a $valor en $fichero"
    ejecuta sed -i -E "s|^[[:space:]]*${clave}=.*|${clave}=\"${valor}\"|" "$fichero"
  else
    info "Añadiendo $clave=$valor a $fichero"
    ejecuta bash -c "printf '%s\n' \"\$1\" >> \"\$2\"" _ "$deseada" "$fichero"
  fi
}

# copia_si_distinto <origen> <destino> [modo]
copia_si_distinto() {
  local origen="$1" destino="$2" modo="${3:-0644}"
  [ -f "$origen" ] || muere "No existe el origen: $origen"

  if [ -f "$destino" ] && cmp -s "$origen" "$destino"; then
    salta "$destino ya actualizado"
    return 0
  fi

  info "Copiando $(basename "$origen") -> $destino"
  ejecuta install -D -m "$modo" "$origen" "$destino"
}

# crea_directorio <ruta> [propietario] [modo]
crea_directorio() {
  local ruta="$1" propietario="${2:-}" modo="${3:-0755}"
  if [ -d "$ruta" ]; then
    salta "$ruta ya existe"
  else
    info "Creando $ruta"
    ejecuta mkdir -p "$ruta"
  fi
  ejecuta chmod "$modo" "$ruta"
  [ -n "$propietario" ] && ejecuta chown "$propietario" "$ruta"
  return 0
}

# ---------------------------------------------------------------------------
# Usuarios
# ---------------------------------------------------------------------------

usuario_existe() { id -u "$1" >/dev/null 2>&1; }
grupo_existe()   { getent group "$1" >/dev/null 2>&1; }

# crea_usuario_nino <login> <nombre completo>
# Sin contraseña: a los 7 años una contraseña es un obstáculo, no seguridad.
# Se establece más adelante, en la fase 3, junto con la entrega de sudo.
crea_usuario_nino() {
  local login="$1" nombre="$2"

  # El grupo lo crea 20-usuarios antes de llamar aquí, pero no dependemos
  # de ese orden: si la función se usa desde otro módulo, sigue funcionando.
  grupo_existe taller || { info "Creando grupo taller"; ejecuta addgroup taller; }
  if usuario_existe "$login"; then
    salta "usuario $login ya existe"
  else
    info "Creando usuario $login ($nombre)"
    ejecuta adduser --disabled-password --gecos "$nombre" "$login"
  fi
  ejecuta usermod -aG taller "$login"
}
