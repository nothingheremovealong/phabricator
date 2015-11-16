#!/bin/bash

sudo apt-get install postfix libsasl2-modules -y

if [ $(grep -c "^default_transport" /etc/postfix/main.cf) -ne 0 ]; then
  echo "Disabling default_transport...";
  sed -i -e "s/^default_transport/# default_transport/" /etc/postfix/main.cf
fi

if [ $(grep -c "^relay_transport" /etc/postfix/main.cf) -ne 0 ]; then
  echo "Disabling relay_transport...";
  sed -i -e "s/^relay_transport/# relay_transport/" /etc/postfix/main.cf
fi

if [ $(grep -c "^relayhost" /etc/postfix/main.cf) -eq 0 ]; then
  echo "Adding relayhost...";
  echo "relayhost = [smtp.sendgrid.net]:2525" >> /etc/postfix/main.cf
fi

if [ $(grep -c "^smtp_tls_security_level" /etc/postfix/main.cf) -eq 0 ]; then
  echo "Adding smtp_tls_security_level...";
  cat > /etc/postfix/main.cf echo << EOF
smtp_tls_security_level = encrypt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
header_size_limit = 4096000
smtp_sasl_security_options = noanonymous
EOF
fi

if [ -f /etc/postfix/sasl_passwd.db ]; then
  echo -n Username: 
  read username
  echo
  echo -n Password: 
  read -s password
  echo

  echo "[smtp.sendgrid.net]:2525 $username:$password" >> /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  rm /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd.db
fi

echo "Restarting postfix..."
/etc/init.d/postfix restart
