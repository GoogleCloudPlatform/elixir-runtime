# Elixir Runtime for Google Cloud Platform

[![Travis-CI Build Status](https://travis-ci.org/GoogleCloudPlatform/elixir-runtime.svg)](https://travis-ci.org/GoogleCloudPlatform/elixir-runtime/)

This repository contains the source for the Elixir Runtime for the
[Google App Engine Flexible Environment](https://cloud.google.com/appengine/docs/flexible/).
It can also be used to run Elixir applications in
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine) and
other Docker-based hosting environments.

This runtime is maintained by Google, but is experimental and not covered by
any SLA or deprecation policy. It may change at any time.

## Elixir on Google App Engine

[Google App Engine](https://cloud.google.com/appengine/) is a
platform-as-a-service offering on Google Cloud Platform. It is an easy way to
build scalable web and mobile backends in any language on Google's
infrastructure.

You may consider deploying your Elixir application to Google App Engine if:

*   Your application is an HTTP web or mobile backend using an Elixir-based
    framework such as [Phoenix](https://phoenixframework.org).
*   You want to focus on application development, and allow Google's
    infrastructure and operations teams to handle your operations needs such as
    monitoring, scaling, and upgrades.

You should consider a different hosting solution such as, e.g.,
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) if:

*   Your application uses websockets, as this feature is not yet supported by
    Google App Engine.
*   Your application uses Erlang's hot upgrade feature because it stores
    critical state in long-running processes. App Engine is designed for
    "stateless" apps that use a separate store such as a database for long-term
    state.

## Using the Elixir Runtime

The Elixir Runtime for Google Cloud Platform is an experimental runtime making
it easy to run a Elixir web application in the Flexible Environment of
[Google App Engine](https://cloud.google.com/appengine/). It is not a
"custom runtime" in that it does not require you to use docker or provide your
own Dockerfile. Instead, it is a full-featured runtime built on the same
technology that powers the official language runtimes provided by Google.

To use the Elixir Runtime, you should have an Elixir project that, when run,
listens on port 8080 or honors the `PORT` environment variable. A project
that uses [Phoenix](http://phoenixframework.org/) will work. You will also
need a Google Cloud project with billing enabled, and you must have the
[Google Cloud SDK](https://cloud.google.com/sdk/) installed.

(Note: some very early versions of this README directed you to set the
`app/use_runtime_builders` configuration in gcloud. This step is no longer
necessary with gcloud 175.0.0 and later, and you should now remove this config
if you currently have it.)

### Configuring an app with Distillery releases

Generally, we recommend that you set up releases for your application using
[Distillery](https://github.com/bitwalker/distillery). Releases are the
community's standard way to package and deploy your code, and they also help
optimize the size and performance of your deployed application.

If your application uses releases, the Elixir Runtime will build a release
automatically, in the `:prod` environment, when you deploy to App Engine.
You must set `include_erts: true` in your release configuration so the Erlang
runtime is included. The release will be built in the cloud on the same OS and
architecture that it will run on, so you do not need to worry about
cross-compilation.

Once you have configured Distillery, create a file called `app.yaml` at the
root of your application directory, with the following contents:

    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    runtime_config:
      release_app: my_app

Replace `my_app` with the name of your release.

See the [App Engine documentation](https://cloud.google.com/appengine/docs/flexible/)
for more information on things you can set in the `app.yaml` configuration
file. A variety of settings are available to control scaling, health checks,
cron jobs, and so forth. There is no Elixir-specific section in the
documentation, but much of the information for other languages such as Ruby
will still apply.

### Configuring an app without releases

The Elixir Runtime also supports deploying an application that does not build
releases. If your app does not use Distillery, create a file called `app.yaml`
at the root of your application directory, with the following contents:

    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    entrypoint: mix phx.server

Set the `entrypoint` field to a command that launches your app in the
foreground. If you do not specify an entrypoint, the Elixir Runtime will
examine your app and attempt to guess an appropriate command to use. Generally,
this guess will be `mix phx.server` for Phoenix apps, or `mix run --no-halt`
for non-Phoenix apps. However, for best results, it is recommended that you
provide an explicit entrypoint.

See the [App Engine documentation](https://cloud.google.com/appengine/docs/flexible/)
for more information on things you can set in the `app.yaml` configuration
file. A variety of settings are available to control scaling, health checks,
cron jobs, and so forth. There is no Elixir-specific section in the
documentation, but much of the information for other languages such as Ruby
will still apply.

### Deploy your application

Once the `app.yaml` config file is set up, you can deploy to App Engine with

    gcloud app deploy

By default, the Runtime will build your project by downloading its deps, and
compile with `MIX_ENV=prod`. For Phoenix apps that use Brunch, it will also
perform a brunch build. Finally, if you are using releases, a release will be
built for your application automatically; otherwise your application code will
be compiled in place.

You may update your application by modifying your source and redeploying.
Again, the Elixir Runtime will take care of rebuilding your application in
the cloud when you deploy.

### Changing the environment/config

If your application needs environment variables to be set, you can use the
standard `env_variables:` field in the `app.yaml` file. For example:

    env_variables:
      MY_VAR: value1
      SERVICE_HOSTNAME: example.com

This will set those environment variables both at build time and at runtime.

One environment variable of particular note is `MIX_ENV`, which controls the
"environment" your application runs in. It can affect build parameters such as
compilation settings; and many frameworks, including Phoenix, use it to select
a set of configuration to use.

By default, the Elixir runtime builds and runs your app in the `prod`
environment, but you can change this by setting the `MIX_ENV` environment
variable. For example:

    env_variables:
      MIX_ENV: staging

This will not only set the `MIX_ENV` during the building and running of your
application, but if you are using a Distillery release, it will also cause
Distillery to build the app with that environment. (So make sure there is a
corresponding clause for the environment in your `rel/config.exs` file.)

### Specifying the Erlang and Elixir versions

The Elixir Runtime uses the [asdf](https://github.com/asdf-vm/asdf) tool to
install and manage Erlang and Elixir. By default, it will run your application
on recent stable releases of those languages. However, you may specify which
versions to use by providing a `.tool-versions` file with versions for `erlang`
and `elixir`. See the [asdf](https://github.com/asdf-vm/asdf) documentation for
more information on the format of the `.tool-versions` file.

When you deploy an Elixir application, the Elixir runtime will install the
requested releases of Erlang and Elixir into your application image
"just-in-time". In most cases, this is pretty quick. Asdf installs Elixir
directly from precompiled binaries hosted on hex.pm. For Erlang, the Elixir
Runtime itself provides prebuilt binaries of recent versions of Erlang since
Erlang 17, and can install any of these directly.

However, if you request an Erlang version for which we do not have a prebuilt
binary, the Elixir runtime will have to build Erlang from source. This can
take a good 10-20 minutes by itself, and it often causes App Engine deployment
to time out. To fix this, set the following:

    gcloud config set app/cloud_build_timeout 60m

This allocates 60 minutes to the "build" phase of app engine deployment, which
should be more than sufficient to build both Erlang and your application. (Feel
free to set it to a different value if you want.) If this gcloud configuration
is not explicitly set, it defaults to 10 minutes.

### Customizing application builds

The Elixir Runtime provides a standard build script that includes installation
of Erlang and Elixir, fetching dependencies, compiling your application, and
(for release-based applications) building the release using Distillery.

There is also a space for custom build commands that are executed after
compilation but before release generation. Your application might use this
space for application-specific or framework-specific build steps such as
building asset files or obtaining credentials.

Phoenix applications generally use Webpack or Brunch to build assets. So, by
default, if the Elixir runtime detects that your app uses Phoenix and contains
a brunch or webpack config file, it will automatically give you a custom build
command that attempts the appropriate build.

Specifically, for Phoenix 1.4 using Webpack, this command is:

    cd assets \
    && npm install \
    && node_modules/webpack/bin/webpack.js --mode production \
    && cd .. \
    && mix phx.digest

Similarly, for Phoenix 1.3 using Brunch, this command is:

    cd assets \
    && npm install \
    && node_modules/brunch/bin/brunch build --production \
    && cd .. \
    && mix phx.digest

(It is slightly different for Phoenix 1.2 applications, and for Phoenix
umbrella applications.)

You may also provide your own custom build commands, by setting the
`runtime_config: -> build:` setting in your `app.yaml` file. The value should
be an array of shell commands to be executed in order. For example:

    runtime_config:
      build:
        - mix phx.digest
        - mix do.something.else

Note that if you provide your own custom build commands, they will override
any Webpack or Brunch build that the Elixir Runtime gives you by default, so
if you still want to use one of those asset build systems, you will have to
include a command explicitly in your config.

### Installing Debian packages

The Elixir runtime provides a minimal set of Debian packages needed to run
ERTS. If your application requires additional packages, you may specify them
in the `runtime_config: -> packages:` setting of your `app.yaml` file. The
Elixir runtime will then make sure they get installed in the Docker image.
For example:

    runtime_config:
      packages:
        - libpq-dev
        - imagemagick

## Inside the Elixir Runtime

The Elixir Runtime comprises three parts:

*   A series of base Docker images that are used by the runtime, and can also
    be used directly by applications. They are all based on a stable version of
    Debian (the same Debian base image used by Google's officially supported
    runtimes).
    *   `elixir-debian` contains an installation of Debian 8 plus a few
        dependencies for the Erlang VM, and some common configuration for
        App Engine runtimes. However, it does not include an installation of
        Erlang or Elixir itself. This image is used as a runtime base image for
        release-based applications. An application release, with its embedded
        ERTS, is installed directly atop this image.
    *   `elixir-asdf` extends `elixir-debian` by installing
        [asdf](https://github.com/asdf-vm/asdf) and the erlang and elixir
        plugins, but does not include any actual installations. This image is
        used as a base image for most other images.
    *   `elixir-base` extends `elixir-asdf` by installing a default recent
        version of both Erlang and Elixir. It may be used as a convenient
        base image for applications that do not care about specific versions
        of the language.
    *   `elixir-builder` extends `elixir-asdf` and installs additional build
        tools such as NodeJS and the Google Cloud SDK. It is used as a base
        image for builds, but still requires that asdf be used to install a
        version of Erlang and Elixir.
*   An `elixir-generate-dockerfile` image. This is the heart of an App Engine
    runtime. It analyzes an Elixir project and constructs a Dockerfile that can
    be used to build the project and prepare it for running in App Engine. When
    you deploy an Elixir application to App Engine, this analyzer-generator
    runs on your application first, and then the generated Dockerfile is used
    to build the Docker image that gets pushed to App Engine servers. The
    generated Dockerfile generally contains two stages: a build stage based on
    `elixir-builder` that performs the build, and a runtime stage based on
    either `elixir-debian` (for release-based builds) or `elixir-asdf` (for
    non-release-based).
*   A configuration file that references a specific build of the above
    analyzer-generator image. This file serves as the official definition of
    the Elixir Runtime, and is available in Google Cloud Storage at the
    location `gs://elixir-runtime/elixir.yaml`. When you set the `runtime`
    field of your `app.yaml`, it points at this configuration file.

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

To perform a test build, run the `runtime-build.sh` script:

    ./runtime-build.sh

By default, this will build the runtime images to Google Cloud Container
Registry in your current project (which should be configured in gcloud). It
will tag them with the current date and time. It will also build a runtime
definition and write it to a `tmp` directory in this repo directory.

If you want to upload the definition to cloud storage (and thus make it
available to use for App Engine deployments), you must provide the name of
a cloud storage bucket to upload it to. You must of course have write access
to this storage bucket.

    ./runtime-build.sh -b my-storage-bucket

You can then use the build of the runtime by pointing at the uploaded
definition file in cloud storage:

    runtime: gs://my-storage-bucket/elixir-<datetime-tag>.yaml

You may also mark the build as a "staging" build by providing the `-s` flag
to `runtime-build.sh`. This will tag the built images with the `staging` tag,
and will also write an `elixir-staging.yaml` definition, so you can use:

    runtime: gs://my-storage-bucket/elixir-staging.yaml

There are several additional options to `runtime-build.sh`. Pass the `-h` flag
for more information.

### Prebuilding Erlang binaries

A basic test build as configured above will likely be slow because it must
compile Erlang from source while deploying. To fix this, provide a set of
prebuilt Erlang binaries.

First, choose the Erlang versions that will be covered. This list should
include at least the default Erlang version specified in the `runtime-build.sh`
script. Write them, one per line, in a file in this directory called
`erlang-versions.txt`. For example:

    19.3
    20.0
    20.1

Next, execute the `erlang-build.sh` script to build these versions of Erlang.
This script uses the "elixir-asdf" base image so you must first build the
runtime itself.

The runtime build script also uses the `erlang-versions.txt` file to decide
which Erlang versions it can install using prebuilt binaries. So after you
edit the version list, you must rebuild the runtime itself.

From this point, the prebuilt binaries can be revved independent of the
runtime. When you update the runtime, you generally will not need to rebuild
the Erlang prebuilt images, or vice versa.

### Releases

Official releases of the Elixir Runtime are done in the `gcp-elixir` project
and uploaded to the `elixir-runtime` storage bucket. If you have sufficient
access, you can perform an official release as follows:

    ./runtime-build.sh -p gcp-elixir -n runtime -b elixir-runtime -s -i
    ./runtime-release.sh -p gcp-elixir -n runtime -b elixir-runtime

To update the official prebuilt Erlang binaries, do this:

    ./erlang-build.sh -p gcp-elixir -n runtime -s -e <versions-to-build>
    ./erlang-release.sh -p gcp-elixir -n runtime -e <versions-to-release>

Generally, you should provide versions explicitly, otherwise it will build or
release ALL versions in the erlang-versions.txt file, which would take a very
long time.

## Contributing changes

* See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

* See [LICENSE](LICENSE)
