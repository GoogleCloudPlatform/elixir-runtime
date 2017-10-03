# Elixir Runtime for Google Cloud Platform

[![Travis-CI Build Status](https://travis-ci.org/GoogleCloudPlatform/elixir-runtime.svg)](https://travis-ci.org/GoogleCloudPlatform/elixir-runtime/)

This repository contains the source for the Elixir Runtime for the
[Google App Engine Flexible Environment](https://cloud.google.com/appengine/docs/flexible/),
[Google Container Engine](https://cloud.google.com/container-engine), 
[Kubernetes](https://kubernetes.io), and other Docker-based hosting environments. 
It is not covered by any SLA or deprecation policy. It may change at any time.

## Using the Elixir Runtime

The Elixir Runtime for Google Cloud Platform is an experimental runtime making
it easy to run a Elixir web application in the Flexible Environment of
[Google App Engine](https://cloud.google.com/appengine/). It is not a
"custom runtime"; you do not need to provide your own Dockerfile. Instead, it
is a full-featured runtime using the same technology used by the official
language runtimes provided by Google.

To use the Elixir Runtime, you should have an Elixir project that, when run,
listens on port 8080 or honors the `PORT` environment variable. A project
that uses [Phoenix](http://phoenixframework.org/) will work. You will also
need a Google Cloud project with billing enabled, and you must have the
[Google Cloud SDK](https://cloud.google.com/sdk/) installed.

As of early Sept 2017, you will also need to configure the Google Cloud SDK
to enable "runtime builders". Execute this in your shell:

    gcloud config set app/use_runtime_builders true

However, note that some of the official languages may still be in beta with
the "runtime builders" setting activated, so you might want to set it only
when you are working with Elixir. We expect this setting to be the default
within a few months, once all the official languages have been validated.

At the root of your project, create a file called `app.yaml` with the following
contents:

    env: flex
    runtime: gs://elixir-runtime/elixir.yaml

You can then deploy to App Engine with

    gcloud app deploy

By default, the runtime will build your project by downloading its deps, and
compiling with `MIX_ENV=prod`. For phoenix apps that use brunch, it will also
perform a brunch build. It will start your application using the command
`mix phx.server` for Phoenix apps (or `mix run --no-halt` for non-Phoenix).
You may provide a different entrypoint by adding an `entrypoint` field to your
`app.yaml`; for example:

    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    entrypoint: mix app.start

More information, including other configuration fields that can be added to
`app.yaml`, is available in the
[App Engine documentation](https://cloud.google.com/appengine/docs/flexible/).
There is no Elixir-specific section, but much of the information for other
languages such as Ruby will still apply.

## Inside the Elixir Runtime

The Elixir Runtime comprises three parts:

* A base Docker image that includes a stable version of Debian and stable
  installations of Erlang and Elixir.
* A "generate-dockerfile" image. This is the heart of an App Engine runtime.
  It analyzes an Elixir project and constructs a Dockerfile that can be used
  to build the project and prepare it for running in App Engine. When you
  deploy an Elixir application to App Engine, this analyzer-generator runs on
  your application first, and then the generated Dockerfile is used to build
  the Docker image that gets pushed to App Engine servers.
* A configuration file that references a specific build of the above
  analyzer-generator image. This file serves as the official definition of
  the Elixir Runtime, and is available in Google Cloud Storage at the location
  `gs://elixir-runtime/elixir.yaml`. When you set the `runtime` field of your
  `app.yaml`, it points at this configuration file.

## Building and Releasing

Build and release scripts are provided that support test builds as well as
official releases.

### Prerequisites

You must have the [gcloud sdk](https://cloud.google.com/sdk/) installed, and
have access to a Google Cloud project. The CloudBuild API must be enabled in
your project. You should also set up a cloud storage bucket that will hold
your test runtime definition.

To perform an official build/release, you must have write access to the
`gcp-elixir` project and the `elixir-runtime` storage bucket.

### Test builds

To perform a test build, run the `build.sh` script:

    ./build.sh

By default, this will build the runtime images to Google Cloud Container
Registry in your current project (which should be configured in gcloud). It
will tag them with the current date and time. It will also build a runtime
definition and write it to a `tmp` directory in this repo directory.

If you want to upload the definition to cloud storage (and thus make it
available to use for App Engine deployments), you must provide the name of
a cloud storage bucket to upload it to. You must of course have write access
to this storage bucket.

    ./build.sh -b my-storage-bucket

You can then use the build of the runtime by pointing at the uploaded
definition file in cloud storage:

    runtime: gs://my-storage-bucket/elixir-<datetime-tag>.yaml

You may also mark the build as a "staging" build by providing the `-s` flag
to `build.sh`. This will tag the built images with the `staging` tag, and will
also write an `elixir-staging.yaml` runtime definition, so you can use:

    runtime: gs://my-storage-bucket/elixir-staging.yaml

There are several additional options to `build.sh`. Pass the `-h` flag for
more information.

### Releases

Official releases of the Elixir Runtime are done in the `gcp-elixir` project
and uploaded to the `elixir-runtime` storage bucket. If you have sufficient
access, you can perform an official release as follows:

    ./build.sh -p gcp-elixir -n runtime -b elixir-runtime -s
    ./release.sh -p gcp-elixir -n runtime -b elixir-runtime

## Contributing changes

* See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

* See [LICENSE](LICENSE)
