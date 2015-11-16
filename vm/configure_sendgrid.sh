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
  echo "smtp_tls_security_level = encrypt" >> /etc/postfix/main.cf
  echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf
  echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> /etc/postfix/main.cf
  echo "header_size_limit = 4096000" >> /etc/postfix/main.cf
  echo "smtp_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
fi

if [ ! -f /etc/postfix/sasl_passwd.db ]; then
  echo "Please enter your sendmail credentials from https://app.sendgrid.com/settings/credentials"
  echo -n "Sendgrid Username: "
  read username
  echo
  echo -n "Sendgrid Password: "
  read -s password
  echo

  echo "[smtp.sendgrid.net]:2525 $username:$password" >> /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  rm /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd.db
fi

echo "Restarting postfix..."
/etc/init.d/postfix restart
