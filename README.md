# Create a Phabricator server pool

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

# Supporting notifications

- ☐ Create a Cloud DNS entry for a n.domain subdomain.
- ☐ When the phabricator vm instance turns on it needs to register its ip with the Cloud DNS.
- ☐ Changing notification.client-uri to something like n.domain should cause the browser client to hit the correct ws:// domain.
- ☐ Subdomain should point directly to the phabricator server.

