# Dockerfile-smtp
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Instalar Postfix y el módulo de integración con LDAP
RUN apt-get update &&     apt-get install -y postfix postfix-ldap &&     apt-get clean && rm -rf /var/lib/apt/lists/*

# AQUI COPIAS TUS CONFIGURACIONES
COPY main.cf /etc/postfix/main.cf
COPY master.cf /etc/postfix/master.cf
COPY ldapmaps.cf /etc/postfix/ldapmaps.cf
COPY vdomains.txt /etc/postfix/vdomains.txt



# Puerto SMTP estándar
EXPOSE 25

# Postfix en versiones recientes permite start-fg para correr en primer plano
CMD ["postfix", "start-fg"]
