#!/bin/bash

if ! cat /etc/passwd | grep "^git"; then
  sudo useradd -r -s /bin/false git
fi
