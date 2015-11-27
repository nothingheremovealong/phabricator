# Create a Phabricator server pool

This scripts tries its darndest to automate the process of setting up a Phabricator server on
Google's Compute Engine.

Things that aren't automated:

- Creating a Cloud engine project.
- Enabling Google Cloud APIs.
- Installing the gcloud APIs on your local machine.
- Buying a domain.
- Updating your domain's NS entries to point to Google's Cloud DNS.
- Signing up for a mailgun account.
- Creating a mailgun domain.

Other than that, though, you simply have to run:

    ./install.sh <Google Cloud Project ID>

And off it goes. The script can be ran as many times as you like.

## Create a project

Visit https://console.developers.google.com/project to create a new project.

## Enable APIs

1. Google Compute Engine
2. Google Cloud SQL API

## Install gcloud tools

Follow the directions located here: https://cloud.google.com/sdk/?hl=en

## TODO

- ☐ Support https on the phabricator vm and nginx instance.
- ☐ Allow "login" app.yaml settings to be configured. It currently defaults to "admin" for the entire site, which is good for development but not necessary once launched.
- ☐ Support plugins. E.g. a server that listens to github webhooks and phabricators http.post events and synchronizes pull request accordingly.
