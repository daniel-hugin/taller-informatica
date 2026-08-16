#!/usr/bin/env bash
# 20-usuarios - Cuentas de los niños, grupo y espacio compartido.
#
# Cada niño tiene su cuenta. Existe además una cuenta de proyectos
# conjuntos, para que el trabajo compartido no viva en el territorio
# de ninguno de los dos: evita el "es mi Scratch".

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

if usuario_existe taller; then
  salta "usuario taller ya existe"
else
  info "Creando cuenta de proyectos conjuntos"
  ejecuta adduser --disabled-password --gecos "Proyectos conjuntos" taller
  ejecuta usermod -aG taller taller
fi

# Espacio compartido con setgid: todo lo que se cree dentro hereda el
# grupo, así los niños pueden pasarse ficheros sin tocar el /home del otro.
crea_directorio "$DIR_COMPARTIDO" "root:taller" 2775
ejecuta chmod g+s "$DIR_COMPARTIDO"

ok "Usuarios configurados"
