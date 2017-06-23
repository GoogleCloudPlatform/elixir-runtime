#!/bin/bash

set -ex

# Install node
mkdir /nodejs
curl https://nodejs.org/dist/v6.10.3/node-v6.10.3-linux-x64.tar.gz | tar xvzf - -C /nodejs --strip-components=1
