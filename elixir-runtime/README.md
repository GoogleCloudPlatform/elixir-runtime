# Elixir Docker Runtime

This folder contains everything needed to install Elixir on Debian 8 (jessie).

## Usage

To build a single version, simply run a docker build providing a build arg of the Elixir version (including the Debian
package sub-version). This is used to download the correct .deb file to install.

See [Erlang Solutions downloads](https://www.erlang-solutions.com/resources/download.html)

```bash
docker build --build-arg ELIXIR_VERSION=1.4.4-1 .
```
