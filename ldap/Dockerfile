FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y slapd ldap-utils wget && \
    wget https://raw.githubusercontent.com/variablenix/ldap-mail-schema/master/courier.schema -O /etc/ldap/schema/courier.schema && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LDAP_ROOTPASS=admin123
ENV LDAP_ORGANISATION=frijoli.com
ENV LDAP_DOMAIN=frijoli.com

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 389

CMD ["/entrypoint.sh"]