#!/bin/bash

. lib/init.sh

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

echo -n "Network..."

if [ -z "$(gcloud --project=${PROJECT} --quiet compute networks list | grep \"\b$NETWORK_NAME\b\")" ]; then
  echo " creating $NETWORK_NAME network..."
  gcloud --project="${PROJECT}" --quiet compute networks create $NETWORK_NAME --range "10.0.0.0/24" || exit 1
fi

echo OK

echo -n " Firewall rules..."

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep \"\b$NETWORK_NAME\b\" | grep \"\ballow-internal\b\")" ]; then
  echo " creating internal $NETWORK_NAME firewall rules..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create allow-internal \
    --allow "tcp:0-65535" \
    --network $NETWORK_NAME \
    --source-ranges "10.0.0.0/24" || exit 1
fi

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep \"\b$NETWORK_NAME\b\" | grep \"\btemp-allow-ssh\b\")" ]; then
  echo " creating temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create temp-allow-ssh \
    --allow "tcp:22" \
    --network $NETWORK_NAME \
    --source-ranges "0.0.0.0/0" || exit 1
fi

echo OK

if [ -n $CUSTOM_DOMAIN ]; then
  echo -n " DNS for $CUSTOM_DOMAIN..."
  
  # Use the custom domain
  PHABRICATOR_URL=$CUSTOM_DOMAIN

  if [ -z "$(gcloud --project=${PROJECT} --quiet dns managed-zones list | grep \"\b$DNS_NAME\b\")" ]; then
    echo " creating DNS zone $DNS_NAME..."
    gcloud --project="${PROJECT}" --quiet dns managed-zones create \
      --dns-name="$PHABRICATOR_URL." \
      --description="phabricator DNS" \
      $DNS_NAME || exit 1
  fi

  # Mailgun DNS
  if [ -z "$(gcloud --project=${PROJECT} --quiet dnsdns record-sets --zone=\"$DNS_NAME\" list | grep \"v=spf1 include:mailgun.org ~all\")" ]; then
    echo " adding DNS TXT entry 'v=spf1 include:mailgun.org ~all'..."
    gcloud --project=${PROJECT} dns record-sets transaction start --zone=$DNS_NAME
    gcloud --project=${PROJECT} dns record-sets transaction add --zone=$DNS_NAME --name="$PHABRICATOR_URL." --ttl=21600 --type=TXT "v=spf1 include:mailgun.org ~all"
    gcloud --project=${PROJECT} dns record-sets transaction execute --zone=$DNS_NAME
  fi

  echo OK
fi

echo -n "SQL..."

if [ -z "$(gcloud --quiet --project=${PROJECT} sql instances list | grep \"\b$SQL_NAME\b\")" ]; then
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

if [ -z "$(gcloud --quiet --project=${PROJECT} compute instances list | grep \"\b$VM_NAME\b\")" ]; then
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
while [ -z "$(gcloud --quiet --project=${PROJECT} compute instances list | grep \"\b$VM_NAME\b\")" ]; do
  sleep 10
done

VM_INTERNAL_IP=$(gcloud --project="${PROJECT}" --quiet compute instances list | grep \"\b$VM_NAME\b\" | awk '{print $4}')

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

echo "deploying nginx..."

gcloud --quiet --project="${PROJECT}" preview app deploy --version=1 --promote app.yaml || exit 1

echo OK

popd >> /dev/null

function remote_exec {
  echo "Executing $1..."
  gcloud --project=${PROJECT} compute ssh $VM_NAME --zone us-central1-a --command "$1" || exit 1
}

remote_exec "sudo apt-get -qq update && sudo apt-get install -y git" || exit 1
remote_exec "if [ ! -d phabricator ]; then git clone https://github.com/nothingheremovealong/phabricator.git; else cd phabricator; git fetch; git rebase origin/master; fi" || exit 1
remote_exec "cd /opt;sudo bash ~/phabricator/vm/install.sh $SQL_NAME http://$PHABRICATOR_URL http://$PHABRICATOR_VERSIONED_URL" || exit 1

if [ "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep \"\b$NETWORK_NAME\b\" | grep \"\btemp-allow-ssh\b\")" ]; then
  echo -n "Removing temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules delete temp-allow-ssh || exit 1
fi

echo "Visit http://$PHABRICATOR_URL to set up your phabricator instance."
echo "Visit https://console.developers.google.com/permissions/projectpermissions?project=$PROJECT to configure your project's permissions."
echo "Setup complete."
