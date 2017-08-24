# Elixir Runtime for Google Cloud Platform

This repository contains the source for the Elixir runtime for the
[Google App Engine Flexible Environment](https://cloud.google.com/appengine/docs/flexible/)
and other Docker-based hosting environments. It is not covered by any SLA or
deprecation policy. It may change at any time.

It comprises:

* A base image for Elixir-based applications
* A build pipeline that generates a Docker image from an Elixir application

## Building

To build the Elixir runtime, run the `build-base.sh` and `build-pipeline.sh`
scripts. These build the base image and build pipeline, respectively, using
[Google Cloud Container Builder](https://cloud.google.com/container-builder/),
and posting the results to
[Google Container Registry](https://cloud.google.com/container-registry/).

You may choose the project to build to and Docker tags for your build, as well
as whether to mark your build as staging. The pipeline script also optionally
generates and uploads the runtime pipeline configuration file. Use the `-h`
switch on each script to show usage information.

## Contributing changes

* See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

* See [LICENSE](LICENSE)
