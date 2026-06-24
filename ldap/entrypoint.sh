#!/bin/sh
set -eu

status () {
  echo "---> ${@}" >&2
}

set +x
: LDAP_ROOTPASS=${LDAP_ROOTPASS}
: LDAP_DOMAIN=${LDAP_DOMAIN}
: LDAP_ORGANISATION=${LDAP_ORGANISATION}

# 🔍 CHECK DE PERSISTENCIA: Buscamos si ya existe el archivo clave de la base de datos
if [ -f "/var/lib/ldap/DB_CONFIG" ] || [ -f "/var/lib/ldap/data.mdb" ]; then
    status "¡Base de datos persistente detectada! Saltando inicialización para no borrar datos..."
else
    status "Contenedor nuevo detectado. Iniciando despliegue forzado y limpio..."

    # 1. Configuración base de Debian
    cat <<EOF | debconf-set-selections
slapd slapd/password1 password ${LDAP_ROOTPASS}
slapd slapd/password2 password ${LDAP_ROOTPASS}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${LDAP_DOMAIN}
slapd shared/organization string ${LDAP_ORGANISATION}
slapd slapd/backend string MDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF

    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure slapd

    # Borrando cualquier residuo previo en la configuración limpia
    rm -f /etc/ldap/slapd.d/cn=config/cn=schema/*misc.ldif
    rm -f /etc/ldap/slapd.d/cn=config/cn=schema/*courier.ldif

    # --- PASO A: Inyectar MISC primero ---
    status "Compilando e instalando esquema MISC..."
    echo "include /etc/ldap/schema/core.schema" > /tmp/misc.conf
    echo "include /etc/ldap/schema/cosine.schema" >> /tmp/misc.conf
    echo "include /etc/ldap/schema/nis.schema" >> /tmp/misc.conf
    echo "include /etc/ldap/schema/inetorgperson.schema" >> /tmp/misc.conf
    echo "include /etc/ldap/schema/misc.schema" >> /tmp/misc.conf

    rm -rf /tmp/misc.d && mkdir -p /tmp/misc.d
    slaptest -f /tmp/misc.conf -F /tmp/misc.d

    MISC_FILE=$(basename /tmp/misc.d/cn=config/cn=schema/cn=*misc.ldif)
    cp "/tmp/misc.d/cn=config/cn=schema/${MISC_FILE}" "/etc/ldap/slapd.d/cn=config/cn=schema/cn={4}misc.ldif"
    sed -i -E 's/\{[0-9]+\}misc/misc/g' "/etc/ldap/slapd.d/cn=config/cn=schema/cn={4}misc.ldif"
    sed -i '1,2d' "/etc/ldap/slapd.d/cn=config/cn=schema/cn={4}misc.ldif"

    # --- PASO B: Inyectar COURIER después ---
    status "Compilando e instalando esquema COURIER..."
    echo "include /etc/ldap/schema/core.schema" > /tmp/courier.conf
    echo "include /etc/ldap/schema/cosine.schema" >> /tmp/courier.conf
    echo "include /etc/ldap/schema/nis.schema" >> /tmp/courier.conf
    echo "include /etc/ldap/schema/inetorgperson.schema" >> /tmp/courier.conf
    echo "include /etc/ldap/schema/misc.schema" >> /tmp/courier.conf
    echo "include /etc/ldap/schema/courier.schema" >> /tmp/courier.conf

    rm -rf /tmp/courier.d && mkdir -p /tmp/courier.d
    slaptest -f /tmp/courier.conf -F /tmp/courier.d

    COURIER_FILE=$(basename /tmp/courier.d/cn=config/cn=schema/cn=*courier.ldif)
    cp "/tmp/courier.d/cn=config/cn=schema/${COURIER_FILE}" "/etc/ldap/slapd.d/cn=config/cn=schema/cn={5}courier.ldif"
    sed -i -E 's/\{[0-9]+\}courier/courier/g' "/etc/ldap/slapd.d/cn=config/cn=schema/cn={5}courier.ldif"
    sed -i '1,2d' "/etc/ldap/slapd.d/cn=config/cn=schema/cn={5}courier.ldif"

    # Permisos finales de la carpeta
    chown -R openldap:openldap /etc/ldap/slapd.d/
    status "¡Estructura de esquemas inyectada con éxito!"
fi

# Ajustes de límites del sistema (Sigue corriendo siempre)
ULIMIT_NOFILE_SYS=$(ulimit -Sn)
ULIMIT_NOFILE_SET=${SLAPD_NOFILE_SOFT:-16384}
ULIMIT_NOFILE=$(( $ULIMIT_NOFILE_SYS < $ULIMIT_NOFILE_SET ? $ULIMIT_NOFILE_SYS : $ULIMIT_NOFILE_SET ))

status "Iniciando slapd de producción..."
set -x
ulimit -Sn "$ULIMIT_NOFILE"

exec /usr/sbin/slapd -h "ldap:///" -u openldap -g openldap -d 0