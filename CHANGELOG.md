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

## elixir-2017-10-17-142851

* Generate the correct brunch build script for phoenix umbrella apps.

## elixir-2017-10-03-154925

* Update OTP 20.0 to 20.1.
* Update Elixir 1.5.1 to 1.5.2.
* Some internal cleanup

## elixir-2017-09-02-192912

* Initial release
