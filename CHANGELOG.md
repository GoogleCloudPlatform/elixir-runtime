# Changelog for Elixir runtime

This is a history of elixir runtime releases.

Generally, you can cause Google App Engine to use the latest stable runtime by
choosing the following in your `app.yaml` config file:

    runtime: gs://elixir-runtime/elixir.yaml

However, you may also pin to a specific version of the runtime by specifying
the version name as the yaml file name. For example, to pin to the
`elixir-2017-10-17-142851` release, use:

    runtime: gs://elixir-runtime/elixir-2017-10-17-142851.yaml

There is currently no guarantee regarding how long older runtime releases will
continue to be supported. It is generally best not to pin to a specific
release unless absolutely necessary, and then you should return to latest as
soon as possible.

## elixir-2017-11-29-234522

This is a major overhaul of the runtime with significant new features and
fixes. Among those:

* Deployments can now be configured to build a release using Distillery, which
  yields a more efficient deployment.
* Applications can provide a `.tool-versions` file specifying the particular
  Erlang and Elixir versions to use. These are installed at build time.
* The builder image now includes a C compiler, so dependencies with a C
  component should now install properly.
* Builds exclude directories that could contain prior development artifacts,
  such as deps, _build, and node_modules, to prevent those from leaking into
  the production build.
* The builder image now includes gcloud, so build steps can easily do things
  like download files from Cloud Storage.

The test suite has also been fleshed out, and a bunch of minor issues have
been fixed, so the runtime should be more stable moving forward.

## elixir-2017-10-17-142851

* Generate the correct brunch build script for phoenix umbrella apps.

## elixir-2017-10-03-154925

* Update OTP 20.0 to 20.1.
* Update Elixir 1.5.1 to 1.5.2.
* Some internal cleanup

## elixir-2017-09-02-192912

* Initial release
