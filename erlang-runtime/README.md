# Erlang Docker Runtime

This folder contains everything needed to install Erlang on Debian 8 (jessie).

## Usage

To build a single version, simply run a docker build providing a build arg of the Erlang version (including the Debian
package sub-version). This is used to download the correct .deb file to install.

See [Erlang Solutions downloads](https://www.erlang-solutions.com/resources/download.html)

```bash
docker build --build-arg ERLANG_VERSION=19.3.6-1 .
```
