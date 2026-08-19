#!/usr/bin/env bash
# 17-scratch - TurboWarp Desktop (Scratch 3), vendorizado.
#
# Scratch Desktop, el oficial de Scratch Foundation, no tiene build para
# Linux -- solo Windows y macOS, confirmado en su repositorio y en su
# página de descarga. TurboWarp es un mod de Scratch 3 mantenido por
# terceros, compatible al 100% con ficheros .sb3: mismo editor, mismos
# bloques. Es la vía real de tener Scratch 3 en Linux, y trae .deb oficial
# para Linux vía GitHub Releases.
#
# Fijado a una versión concreta y verificado por sha256, no a "la última":
# no hay fichero de sumas publicado en la release, así que el hash de abajo
# es el que se obtuvo al descargar y comprobar este fichero en concreto.

# Guardián: este módulo no es autónomo. Se carga con `source` desde
# install.sh, que antes ha cargado lib/comun.sh (RAIZ, taller.conf,
# ejecuta/info/...). Ejecutarlo suelto arranca un proceso nuevo sin nada de
# eso, y cada línea falla con "orden no encontrada".
if ! declare -F ejecuta >/dev/null || [ -z "${RAIZ:-}" ]; then
  echo "Este módulo no se ejecuta solo. Usa: sudo ./install.sh $(basename "${BASH_SOURCE[0]%.sh}")" >&2
  exit 1
fi

VERSION="1.16.0"
URL="https://github.com/TurboWarp/desktop/releases/download/v${VERSION}/TurboWarp-linux-amd64-${VERSION}.deb"
SHA256_ESPERADO="a11edc3bdfdf84b730a8972d1285d89c71cd13a38483748d34674f35587c4013"
PAQUETE="turbowarp-desktop"

if paquete_instalado "$PAQUETE" && [ "$(dpkg-query -W -f='${Version}' "$PAQUETE" 2>/dev/null)" = "$VERSION" ]; then
  salta "$PAQUETE $VERSION ya instalado"
else
  info "Descargando TurboWarp Desktop $VERSION"
  TMP_DEB="$(mktemp --suffix=.deb)"
  if ejecuta curl -fsSL -o "$TMP_DEB" "$URL"; then
    if [ "$DRY_RUN" != "1" ]; then
      SHA256_REAL="$(sha256sum "$TMP_DEB" | awk '{print $1}')"
      [ "$SHA256_REAL" = "$SHA256_ESPERADO" ] || \
        muere "TurboWarp: el sha256 descargado ($SHA256_REAL) no es el esperado ($SHA256_ESPERADO)"
    fi
    info "Instalando $PAQUETE $VERSION"
    # apt, no dpkg -i: resuelve las dependencias del .deb (libgtk-3-0,
    # libnotify4...) contra los repositorios ya configurados en un solo paso.
    ejecuta apt-get install -y "$TMP_DEB"
  else
    avisa "No se pudo descargar TurboWarp Desktop (¿sin red?). Se omite."
  fi
  rm -f "$TMP_DEB"
fi

# El propio paquete registra su lanzador en el menú de aplicaciones; a
# diferencia de Turtle Blocks, aquí no hace falta crear ninguno a mano.

ok "Scratch (TurboWarp) configurado"
