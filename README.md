# Create a Phabricator server pool

## Create a project

Visit https://console.developers.google.com/project to create a new project.

## Enable APIs

1. Google Compute Engine
2. Google Cloud SQL API

## Install gcloud tools

Follow the directions located here: https://cloud.google.com/sdk/?hl=en

## TODO

[ ] Support https on the phabricator vm and nginx instance.
[ ] Allow "login" app.yaml settings to be configured. It currently defaults to "admin" for the entire site, which is good for development but not necessary once launched.
