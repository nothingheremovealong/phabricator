# Create a Phabricator server pool

This script tries its darndest to automate the process of setting up a Phabricator server on
Google's Compute Engine.

Things that aren't automated:

- Creating a Cloud engine project.
- Enabling Google Cloud APIs.
- Installing the gcloud APIs on your local machine.
- Buying a domain.
- Updating your domain's NS entries to point to Google's Cloud DNS.
- Signing up for a mailgun account.
- Creating a mailgun domain.

Other than that, though, this repo contains a script that handles most of the busy work. Let's go
over getting a Compute Engine project started.

## Getting started

### Create a project

Visit https://console.developers.google.com/project to create a new project.

### Enable APIs

Visit your project's APIs library:

    https://console.developers.google.com/apis/library?project=your-project-name

And enable the following:

1. Google Compute Engine
2. Google Cloud SQL API
3. Google Cloud DNS API

You don't need to create credentials for either of the above services.

Estimated time to complete: 2-5 minutes (all manual steps).

### Install gcloud tools

Follow the directions located here: https://cloud.google.com/sdk/?hl=en

    curl https://sdk.cloud.google.com | bash

NOTE for [fish shell](https://fishshell.com/) users: gcloud doesn't provide fish support out of the
box. You can directly add the gcloud bin to your path by editing config.fish like so:

    vi ~/.config/fish/config.fish
    set -x PATH $PATH /path/to/google-cloud-sdk/bin

Once gcloud has been installed and is available in your PATH (may require restarting terminal), run:

    gcloud init

This configuration will ask you for the following information:

- Your login credentials
- A cloud project (pick your phabricator project)
- The default compute zone (pick what's closest to you)
- Whether or not you want to use Google's source hosting. You don't need this for this script.

Estimated time to complete: 5 minutes (some manual steps).

### Create your project's configuration file

The first time you run the script it will create a default configuration file for your project in
`config/`.

    ./install -p <project name>

### Run the install script

Once you've configured your project's config file you can run the install script:

    ./install -p <project name>

Estimated time to complete: 18-20 minutes (totally automated after invocation).

### Upgrading phabricator

To upgrade phabricator you may run:

    ./upgrade -p <project name>

Estimated time to complete: 3 minutes (totally automated after invocation).

### Connecting to the phabricator instance

To ssh into your instance you must run:

    ./ssh -p <project name>

## Custom domains

Custom domains enable the following features:

- Email with Mailgun
- Notifications
- Git hosting

### Before you start

- Choose your favorite registrar and purchase a domain name. Ensure that you are able to change the
  name servers for your domain.
- Register for Mailgun. [Mailgun](http://www.mailgun.com/) is
  [Phabricator's recommended outgoing email service](https://secure.phabricator.com/book/phabricator/article/configuring_outbound_email/).
  Register for an account and provide it with your custom domain.

NOTE: Do not use a subdomain when creating your Mailgun domain. E.g. if your website's name is
`phabricatorplayground.com`, use `phabricatorplayground.com` as the domain name.

### Update your configuration

Modify your `config/<project>` file to set the following values:

    MAILGUN_APIKEY="your api key"
    CUSTOM_DOMAIN="yourdomain.com"

Re-run the installation script:

    ./install -p <project name>

Follow the displayed steps to register your custom domain with your Cloud Engine project.

#### Manual step: Change nameservers

Once the install script completes you must change the name servers for your domain.

Start by visiting the DNS Zones page of your project:

https://console.cloud.google.com/networking/dns/zones

Open your phabricator zone and look at the `NS` values listed. Enter these values in your
registrar's namespace editor for your domain. These changes may take up to 24 hours to propagate.

You will know once your DNS changes have propagated when you visit your Mailgun project page and
your domain has been verified.

#### Don't want to wait for propagation?

If propagation is taking a long time you can set up a temporary mapping by modifying any of the IPs
found at:

https://console.cloud.google.com/appengine/settings/domains

to your domain in your `/etc/hosts` file.

    some.ip<tab>yourdomain.com

## TODO

- ☐ Support https on the phabricator vm and nginx instance.
- ☐ Support plugins. E.g. a server that listens to github webhooks and phabricators http.post events and synchronizes pull request accordingly.
