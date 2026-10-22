openssl req -x509 -newkey rsa:4096 -keyout /etc/bind/dot.key \
  -out /etc/bind/dot.crt -days 3650 -nodes \
  -subj "/CN=$PUBLIC_NAMESERVER"
