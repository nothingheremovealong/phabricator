#!/bin/bash

if ! cat /etc/passwd | grep "^git" >> /dev/null; then
  sudo useradd -r -s /bin/false git
fi
