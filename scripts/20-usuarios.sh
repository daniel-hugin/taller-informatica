#!/usr/bin/env bash
# 20-usuarios - Cuentas de los niños, grupo y espacio compartido.
#
# Cada niño tiene su cuenta. Existe además una cuenta de proyectos
# conjuntos, para que el trabajo compartido no viva en el territorio
# de ninguno de los dos: evita el "es mi Scratch".

# Guardián: este módulo no es autónomo. Se carga con `source` desde
# install.sh, que antes ha cargado lib/comun.sh (RAIZ, taller.conf,
# ejecuta/info/...). Ejecutarlo suelto arranca un proceso nuevo sin nada de
# eso, y cada línea falla con "orden no encontrada".
if ! declare -F ejecuta >/dev/null || [ -z "${RAIZ:-}" ]; then
  echo "Este módulo no se ejecuta solo. Usa: sudo ./install.sh $(basename "${BASH_SOURCE[0]%.sh}")" >&2
  exit 1
fi

if grupo_existe taller; then
  salta "grupo taller ya existe"
else
  info "Creando grupo taller"
  ejecuta addgroup taller
fi

for entrada in "${NINOS[@]}"; do
  login="${entrada%%:*}"
  nombre="${entrada#*:}"
  crea_usuario_nino "$login" "$nombre"
done

# ---------------------------------------------------------------------------
# Cuenta de proyectos conjuntos
# ---------------------------------------------------------------------------
# Si en el instalador de Debian se nombró así a la cuenta de administración
# (p. ej. el docente escribió "taller" sin pensar en este script),
# usuario_existe la daría por buena sin más comprobación y los niños
# acabarían usando una cuenta CON sudo sin que nadie lo note. Se aborta en
# vez de arriesgarse.
CUENTA_COMPARTIDA="${CUENTA_COMPARTIDA:-taller}"

if usuario_existe "$CUENTA_COMPARTIDA"; then
  uid_existente="$(id -u "$CUENTA_COMPARTIDA")"
  grupos_existentes="$(id -Gn "$CUENTA_COMPARTIDA")"
  estado_pass="$(passwd -S "$CUENTA_COMPARTIDA" 2>/dev/null | awk '{print $2}')" || estado_pass=""

  if [ "$uid_existente" -lt 1000 ] \
    || grep -qw 'sudo' <<< "$grupos_existentes" \
    || grep -qw 'adm' <<< "$grupos_existentes" \
    || [ "$estado_pass" = "P" ]; then
    muere "La cuenta '$CUENTA_COMPARTIDA' ya existe y parece ser la de administración (UID $uid_existente, grupos: $grupos_existentes), no la de proyectos conjuntos del taller. Cambia CUENTA_COMPARTIDA en config/taller.conf a otro nombre, o renombra la cuenta de administración."
  fi
fi

crea_usuario_nino "$CUENTA_COMPARTIDA" "Proyectos conjuntos"

# Espacio compartido con setgid: todo lo que se cree dentro hereda el
# grupo, así los niños pueden pasarse ficheros sin tocar el /home del otro.
crea_directorio "$DIR_COMPARTIDO" "root:taller" 2775
ejecuta chmod g+s "$DIR_COMPARTIDO"

ok "Usuarios configurados"
