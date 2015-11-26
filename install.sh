#!/bin/bash

. lib/init.sh

# Terminate execution on command failure
set -e

RED='\033[0;31m'
NC='\033[0m'

if [[ -n $CUSTOM_DOMAIN && "$CUSTOM_DOMAIN_CONFIRMED" != "$PROJECT" ]]; then
  echo -e ${RED}
  echo "You have provided a custom domain of $CUSTOM_DOMAIN"
  echo "In order to configure the domain you will need to perform the following steps:"
  echo
  echo "  1. Visit https://console.developers.google.com/appengine/settings/domains?project=$PROJECT"
  echo 
  echo "  If $CUSTOM_DOMAIN is already listed there then your work is done here, otherwise continue with step 2:"
  echo
  echo "  2. Otherwise, visit https://console.developers.google.com/appengine/settings/domains/add?project=$PROJECT"
  echo "  3. Register your custom domain."
  echo "  4. In your domain registrar, add the CNAME record indicated in the previous step."
  echo
  echo "  Learn more about custom domains at https://cloud.google.com/appengine/docs/using-custom-domains-and-ssl?hl=en"
  echo -e ${NC}
  
  echo "Please press enter to confirm that you've registered $CUSTOM_DOMAIN, or Ctrl-C to quit."
  read

  if [ $(grep -c "^CUSTOM_DOMAIN_CONFIRMED" phabricator.sh) -ne 0 ]; then
    sed -i'.tmp' -e "s/^CUSTOM_DOMAIN_CONFIRMED=.*/CUSTOM_DOMAIN_CONFIRMED=$PROJECT/" phabricator.sh
    rm -rf phabricator.sh.tmp
  else
    echo >> phabricator.sh
    echo "CUSTOM_DOMAIN_CONFIRMED=$PROJECT" >> phabricator.sh
  fi
fi

# TODO: Might not always be appspot - how do we configure this?
PHABRICATOR_URL=$PROJECT.appspot.com
PHABRICATOR_VERSIONED_URL=1-dot-$PROJECT.appspot.com

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

gcloud -v >/dev/null 2>&1 || { echo "gcloud SDK required. Download from https://cloud.google.com/sdk/?hl=en"; exit 1; }

echo -n "Checking gcloud auth..."

if [ -z "$(gcloud auth list 2> /dev/null | grep \(active\))" ]; then
  echo "Authenticating gcloud..."
  gcloud auth login
fi

echo OK

echo -n "APIs..."

if ! gcloud --project=${PROJECT} --quiet compute networks list >> /dev/null 2> /dev/null; then
  echo
  echo
  echo "  Error: The Compute Engine API has not been enabled for $PROJECT."
  echo
  echo "  Please visit https://console.developers.google.com/apis/api/compute_component/overview?project=$PROJECT"
  echo "  2. Enable API button"
  echo "  3. Rerun this script"
  echo
  exit 1
fi

if ! gcloud --project=${PROJECT} --quiet dns managed-zones list >> /dev/null 2> /dev/null; then
  echo
  echo
  echo "  Error: Google Cloud DNS API has not been enabled for $PROJECT."
  echo
  echo "  1. Please visit https://console.developers.google.com/apis/api/dns/overview?project=$PROJECT"
  echo "  2. Enable API button"
  echo "  3. Rerun this script"
  echo
  exit 1
fi

echo OK

echo -n "Network..."

if [ -z "$(gcloud --project=${PROJECT} --quiet compute networks list | grep "\b$NETWORK_NAME\b")" ]; then
  echo " creating $NETWORK_NAME network..."
  gcloud --project="${PROJECT}" --quiet compute networks create $NETWORK_NAME --range "10.0.0.0/24" || exit 1
fi

echo OK

echo -n " Firewall rules..."

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\ballow-internal\b")" ]; then
  echo " creating internal $NETWORK_NAME firewall rules..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create allow-internal \
    --allow "tcp:0-65535" \
    --network $NETWORK_NAME \
    --source-ranges "10.0.0.0/24" || exit 1
fi

echo OK

if [ -n $CUSTOM_DOMAIN ]; then
  echo -n " DNS for $CUSTOM_DOMAIN..."
  
  # Use the custom domain
  PHABRICATOR_URL=$CUSTOM_DOMAIN
  
  TOP_LEVEL_DOMAIN=$(echo $CUSTOM_DOMAIN | rev | cut -d'.' -f-2 | rev)

  if [ -z "$(gcloud --project=${PROJECT} --quiet dns managed-zones list | grep "\b$DNS_NAME\b")" ]; then
    echo " creating DNS zone $DNS_NAME..."
    gcloud --project="${PROJECT}" --quiet dns managed-zones create \
      --dns-name="$TOP_LEVEL_DOMAIN" \
      --description="phabricator DNS" \
      $DNS_NAME || exit 1
  fi

  echo OK

  # Abort any existing transaction
  if gcloud --project=${PROJECT} --quiet dns record-sets transaction --zone="$DNS_NAME" describe >> /dev/null 2> /dev/null; then
    gcloud --project=${PROJECT} --quiet dns record-sets transaction abort --zone=$DNS_NAME
  fi
  
  # Mailgun TXT
  if [ -z "$(gcloud --project=${PROJECT} --quiet dns record-sets --zone="$DNS_NAME" list | grep "TXT" | grep "mailgun.org")" ]; then
    echo " Adding DNS TXT entry 'v=spf1 include:mailgun.org ~all'..."
    gcloud --project=${PROJECT} --quiet dns record-sets transaction start --zone=$DNS_NAME
    gcloud --project=${PROJECT} --quiet dns record-sets transaction add --zone=$DNS_NAME --name="$TOP_LEVEL_DOMAIN." --ttl=21600 --type=TXT "v=spf1 include:mailgun.org ~all"
    gcloud --project=${PROJECT} --quiet dns record-sets transaction execute --zone=$DNS_NAME
    echo OK
  fi

  # Mailgun email. CNAME
  if [ -z "$(gcloud --project=${PROJECT} --quiet dns record-sets --zone="$DNS_NAME" list | grep "CNAME" | grep "mailgun.org")" ]; then
    echo " Adding DNS CNAME entry email.$PHABRICATOR_URL. 'mailgun.org'..."
    gcloud --project=${PROJECT} --quiet dns record-sets transaction start --zone=$DNS_NAME
    gcloud --project=${PROJECT} --quiet dns record-sets transaction add --zone=$DNS_NAME --name="email.$TOP_LEVEL_DOMAIN." --ttl=21600 --type=CNAME "mailgun.org."
    gcloud --project=${PROJECT} --quiet dns record-sets transaction execute --zone=$DNS_NAME
    echo OK
  fi
fi

echo -n "SQL..."

if [ -z "$(gcloud --quiet --project=${PROJECT} sql instances list | grep "\b$SQL_NAME\b")" ]; then
  echo -n " creating $SQL_NAME SQL database..."
  gcloud --quiet --project="${PROJECT}" sql instances create "$SQL_NAME" \
    --backup-start-time="00:00" \
    --assign-ip \
    --authorized-networks "0.0.0.0/0" \
    --authorized-gae-apps "${PROJECT}" \
    --gce-zone "us-central1-a" \
    --tier="D0" \
    --pricing-plan="PACKAGE" \
    --database-flags="sql_mode=STRICT_ALL_TABLES,ft_min_word_len=3,max_allowed_packet=33554432" || exit 1
fi

SQL_INSTANCE_NAME=$(gcloud --project="${PROJECT}" --quiet sql instances list | grep "\b$SQL_NAME\b" | cut -d " " -f 1)
if [ -z "${SQL_INSTANCE_NAME}" ]; then
  # We could not load the name of the Cloud SQL instance, so we need to bail out.
  echo "Failed to load the name of the Cloud SQL instance to use for Phabricator"
  exit
fi

echo OK

echo -n "Compute instances..."

if [ -z "$(gcloud --quiet --project=${PROJECT} compute instances list | grep "\b$VM_NAME\b")" ]; then
  echo " creating $VM_NAME compute instance..."
  gcloud --quiet --project="${PROJECT}" compute instances create "$VM_NAME" \
    --boot-disk-size "10GB" \
    --image "ubuntu-14-04" \
    --machine-type "n1-standard-1" \
    --network "$NETWORK_NAME" \
    --zone "us-central1-a" \
    --scopes sql,cloud-platform || exit 1
fi

echo -n "waiting for compute instance to activate..."
while [ -z "$(gcloud --quiet --project=${PROJECT} compute instances list | grep "\b$VM_NAME\b")" ]; do
  sleep 10
done

VM_INTERNAL_IP=$(gcloud --project="${PROJECT}" --quiet compute instances list | grep "\b$VM_NAME\b" | awk '{print $4}')

echo -n "internal IP: $VM_INTERNAL_IP. "
echo OK

pushd $DIR/nginx >> /dev/null

echo -n "Generating nginx.conf..."

if [ -z "$PHABRICATOR_URL" ]; then
  echo "No phabricator URL found...bailing out"
  exit 1
fi

if [ -z "$VM_INTERNAL_IP" ]; then
  echo "No internal IP found...bailing out"
  exit 1
fi

cp nginx.conf.template nginx.conf
sed -i.bak -e s/\\\$PHABRICATOR_URL/$PHABRICATOR_URL/ nginx.conf
sed -i.bak -e s/\\\$PHABRICATOR_ALTERNATE_URL/$PHABRICATOR_VERSIONED_URL/ nginx.conf
sed -i.bak -e s/\\\$PHABRICATOR_IP/$VM_INTERNAL_IP/ nginx.conf
rm nginx.conf.bak

COMPUTED_NGINX_SHA=$(find . -type f \( -exec shasum {} \; \) | shasum | cut -d' ' -f1)

if [ "$COMPUTED_NGINX_SHA" != "$NGINX_SHA" ]; then
  echo "deploying nginx..."
  gcloud --quiet --project="${PROJECT}" preview app deploy --version=1 --promote app.yaml || exit 1

  popd >> /dev/null

  if [ $(grep -c "^NGINX_SHA" phabricator.sh) -ne 0 ]; then
    sed -i'.tmp' -e "s/^NGINX_SHA=.*/NGINX_SHA=$COMPUTED_NGINX_SHA/" phabricator.sh
    rm -rf phabricator.sh.tmp
  else
    echo >> phabricator.sh
    echo "NGINX_SHA=$COMPUTED_NGINX_SHA" >> phabricator.sh
  fi

  pushd $DIR/nginx >> /dev/null
fi

echo OK

popd >> /dev/null

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo "Creating temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create temp-allow-ssh \
    --allow "tcp:22" \
    --network $NETWORK_NAME \
    --source-ranges "0.0.0.0/0" || exit 1
fi

function remote_exec {
  echo "Executing $1..."
  gcloud --project=${PROJECT} compute ssh $VM_NAME --zone us-central1-a --command "$1" || exit 1
}

remote_exec "sudo apt-get -qq update && sudo apt-get install -y git" || exit 1
remote_exec "if [ ! -d phabricator ]; then git clone https://github.com/nothingheremovealong/phabricator.git; else cd phabricator; git fetch; git rebase origin/master; fi" || exit 1
remote_exec "cd /opt;sudo bash ~/phabricator/vm/install.sh $SQL_NAME http://$PHABRICATOR_URL http://$PHABRICATOR_VERSIONED_URL" || exit 1

if [ "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo -n "Removing temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules delete temp-allow-ssh || exit 1
fi

echo "Visit http://$PHABRICATOR_URL to set up your phabricator instance."
echo "Visit https://console.developers.google.com/permissions/projectpermissions?project=$PROJECT to configure your project's permissions."
echo "Setup complete."
