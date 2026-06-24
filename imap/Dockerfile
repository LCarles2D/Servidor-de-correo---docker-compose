# Dockerfile-imap
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Instalacion
RUN apt-get update &&     apt-get install -y dovecot-core dovecot-imapd dovecot-lmtpd dovecot-ldap &&     apt-get clean && rm -rf /var/lib/apt/lists/*

# Crear el usuario y grupo 
RUN groupadd -g 1005 vmail && \
    useradd -u 1005 -g vmail -m -d /home/vmail vmail

# Copiar configuraciones
COPY dovecot.conf /etc/dovecot/dovecot.conf
COPY conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
COPY conf.d/auth-ldap.conf.ext /etc/dovecot/conf.d/auth-ldap.conf.ext
COPY conf.d/10-logging.conf /etc/dovecot/conf.d/10-logging.conf
COPY conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf
COPY conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf
COPY dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap.conf.ext
EXPOSE 143

# Ejecutar
CMD ["dovecot", "-F"]
