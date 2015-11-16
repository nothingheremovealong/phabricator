# Create a Phabricator server pool

## Create a project

Visit https://console.developers.google.com/project to create a new project.

## network: phabricator

1. Visit https://console.developers.google.com/networking/networks/list to manage your networks.
2. Click "Create network".
3. Name: `phabricator`
4. Address range: `10.0.0.0/24`
5. Gateway: `10.0.0.1`
6. Enable "allow-internal" in the Firewall settings.
7. Click "Create".

## SQL server: phabricator

1. Visit https://console.developers.google.com/sql/instances to create a SQL server instance.
2. Name: `phabricator`
3. Region: `us-central`
4. Tier: `D1 - 512MB RAM`
5. Expand advanced options...
6. Select `Package billing plan`
7. Assign an IPv4 address.
8. Under MySQL flags, set the following:

Flags:

    ft_min_word_len=3
    sql_mode=STRICT_ALL_TABLES
    max_allowed_packet=33554432

Create the SQL server.

## VM instance: phabricator

- Tags: none
- Machine type: `n1-standard-1 (1 vCPU, 3.75 GB memory)`
- CPU platform: `Intel Sandy Bridge`
- Zone: `us-central1-a`
- External IP: `ephemeral` (required for nginx to be able to serve content...why?)
- Internal IP: 10.0.0.x
- IP forwarding: off
- Network: `phabricator`
- Firewalls: none enabled
- Preemptibility: `off`
- Automatic restart: `on`
- On host maintenance: `Migrate VM instance`

To set up, SSH into the machine and run the following:

    sudo apt-get install git
    git clone https://github.com/nothingheremovealong/phabricator.git
    cd /opt
    sudo bash ~/phabricator/install.sh phabricator http://subdomain.appspot.com/ http://1-dot-subdomain.appspot.com/

While testing, you can enabling the http firewall and changing the last line accordingly:

    sudo bash ~/phabricator/install.sh phabricator http://some.ip.address/

## App engine instance: nginx

To set up, run the following from a personal machine:

    cd nginx
    cp nginx.conf.template nginx.conf
    vi nginx.conf
    # Replace $PHABRICATOR_URL with http://subdomain.appspot.com/
    # Replace $PHABRICATOR_IP with the Internal IP of the **phabricator** vm.

Once you've modified nginx.conf, deploy the server like so:

    gcloud --project=your.project preview app deploy --version=1 --promote app.yaml

You should then be able to hit http://subdomain.appspot.com/ in order to visit phabricator.


## TODO

[ ] Support https on the phabricator vm and nginx instance.
