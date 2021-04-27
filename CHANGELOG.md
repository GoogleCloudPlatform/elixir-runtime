# Changelog for Elixir runtime

This is a history of elixir runtime releases.

Generally, you can cause Google App Engine to use the latest stable runtime by
choosing the following in your `app.yaml` config file:

    runtime: gs://elixir-runtime/elixir.yaml

However, you may also pin to a specific version of the runtime by specifying
the version name as the yaml file name. For example, to pin to the
`elixir-2019-10-09-181239` release, use:

    runtime: gs://elixir-runtime/elixir-2019-10-09-181239.yaml

There is currently no guarantee regarding how long older runtime releases will
continue to be supported. It is generally best not to pin to a specific
release unless absolutely necessary, and then you should return to latest as
soon as possible.

## elixir-2021-04-26-035921

* Update default Elixir to 1.11.4.
* Update default OTP to 22.3.4.17.
* Prebuilt OTP 22.3.4.5 through 22.3.4.17, 23.0.4, 23.1 through 23.1.5, 23.2 through 23.2.7.2, and 23.3 through 23.3.1.
* Dropped prebuilt binaries for OTP 20.x.
* Update gcloud to 334.0.0.
* Update nodejs to 14.16.1.
* Update asdf to 0.8.0.

## elixir-2020-08-03-131308

* Update default Elixir to 1.10.4.
* Update default OTP to 22.3.4.4.
* Prebuilt OTP 20.3.8.26, 21.3.8.17, 22.3.1 through 22.3.4.4, and 23.0 through 23.0.3.
* Update gcloud to 303.0.0
* Update nodejs to 12.18.3

## elixir-2020-04-07-131853

* Update default Elixir to 1.10.2
* Update default OTP to 22.2.8
* Prebuilt OTP 21.3.8.13, 21.3.8.14, 22.2.4 through 22.2.8, and 22.3.
* Update gcloud to 287.0.0
* Update nodejs to 12.16.1
* Update asdf to 0.7.8

## elixir-2020-01-22-160655

* Prebuilt OTP 21.3.8.12, 22.1.8.1, and 22.2 through 22.2.3
* Update default OTP to 22.2.3
* Update gcloud to 277.0.0
* Update nodejs to 12.14.1
* Update asdf to 0.7.6

## elixir-2019-12-10-142915

* Prebuilt OTP 21.3.8.11 and 22.1.8
* Update default OTP to 22.1.8
* Update gcloud to 273.0.0
* Update nodejs to 12.13.1

## elixir-2019-11-14-223500

* Prebuilt OTP up to 22.1.7
* Update default elixir to 1.9.4
* Update default OTP to 22.1.7
* Update gcloud to 271.0.0
* Update asdf to 0.7.5

## elixir-2019-10-29-183530

* Prebuilt OTP up to 21.3.8.10 and 22.1.5
* Removed prebuilt OTP 21.0.1 through 21.0.8 (but kept 21.0 and 21.0.9)
* Update default elixir to 1.9.2
* Update default OTP to 22.1.5
* Update gcloud to 268.0.0
* Update nodejs to 12.13.0

## elixir-2019-10-09-181239

* Prebuilt OTP 21.3.8.7, 22.1, and 22.1.1.
* Update default to elixir to 1.9.1.
* Update default OTP to 22.1.1.
* Allow custom debian packages with plus signs in the name.
* Update gcloud to 265.0.0
* Update nodejs to 10.16.3
* Update asdf to 0.7.4

## elixir-2019-07-18-112708

* Supports building releases using the built-in mix release in elixir 1.9.
* Supports the usage changes in distillery 2.1.
* Update default elixir to 1.9.0, unless pre-2.1 distillery is in use in which case it remains on 1.8.2.
* Update default OTP to 22.0.7.
* Prebuilt OTP through 21.3.8.6 and 22.0.7.
* Removed intermediate OTP 20.x versions from the prebuilt list. (The primary and latest versions are still present.)
* Update default gcloud to 253.0.0.
* Update asdf to 0.7.3.

## elixir-2019-07-01-065508

* Prebuilt OTP through 21.3.8.4 and 22.0.4.
* Update default OTP to 22.0.4.
* Update default gcloud to 252.0.0.
* Update nodejs to 10.16.0.

## elixir-2019-05-28-222238

* Prebuilt OTP through 21.3.7.1, 21.3.8.2, and 22.0.1.
* Update default OTP to 21.3.8.2, and default Elixir to 1.8.2.
* Update default gcloud to 247.0.0.
* Update asdf to 0.7.2

## elixir-2019-04-19-135626

* Prebuilt OTP 20.3.8.21, and 21.3.3 thru 21.3.6.
* Update default OTP to 21.3.6.
* Update gcloud to 242.0.0.
* Update asdf to 0.7.1.

## elixir-2019-03-21-181846

* Prebuilt OTP 21.2 up to 21.2.7, and 21.3 up to 21.3.2.
* Update default OTP to 21.3.2.
* Update gcloud to 239.0.0.

## elixir-2019-03-04-150411

* Updated the underlying OS from Ubuntu 16.04 (Xenial) to Ubuntu 18.04 (Bionic).
* Prebuilt OTP 20.3 up to 20.3.8.20, and 21.2 up to 21.2.6.
* Update default OTP to 21.2.6, and default Elixir to 1.8.1
* Update asdf to 0.7.0.
* Update gcloud to 236.0.0.
* Update nodejs to 10.15.2.

## elixir-2019-01-19-000446 (elixir-ubuntu16)

* This is the last planned release on Ubuntu 16.04 (Xenial). Future releases will update to Ubuntu 18.04 (Bionic). To remain on Xenial, pin to this release by setting the runtime to `gs://elixir-runtime/elixir-ubuntu16.yaml`
* Prebuilt OTP 20.3 up to 20.3.8.18, and 21.2 up to 21.2.3.
* Update default OTP to 21.2.3.
* Update gcloud to 230.0.0.

## elixir-2019-01-02-104948

* Prebuilt OTP 21.2, 21.2.1, and 21.2.2.
* Update default OTP to 21.2.2.
* Update gcloud to 228.0.0.
* Update nodejs to 10.15.0.

## elixir-2018-12-11-124828

* The runtime now recognizes Phoenix 1.4 and webpack when building assets. (Brunch is still supported for older projects.)
* Prebuilt OTP 20.3.8.x up to 20.3.8.15, and 21.1.x up to 21.1.4.
* Update default OTP to 21.1.4 and default Elixir to 1.7.4.
* Update gcloud to 227.0.0.
* Update nodejs to 10.14.1.

## elixir-2018-10-10-134614

* Set ASDF_DATA_DIR to fix asdf after being updated to 0.6.
* Prebuilt OTP 20.3.8.9, 21.0.9, and 21.1.
* Update default OTP to 21.0.9. Default Elixir remains 1.7.3.
* Update gcloud to 219.0.1.
* Update nodejs to 8.12.0.

## elixir-2018-09-11-102415

* Update defaults to OTP 21 and Elixir 1.7 (specifically OTP 21.0.8 and Elixir 1.7.3).
* Prebuilt OTP through 20.3.8.8 and 21.0.8
* Update gcloud to 215.0.0
* Update nodejs to 8.11.4

## elixir-2018-07-30-141124

* Prebuilt OTP through 20.3.8.3 and 21.0.4
* Update default OTP to 20.3.8.3. Default Elixir remains 1.6.6.
* Update gcloud to 209.0.0
* Update nodejs to 8.11.3
* Modify pipeline config so there is room for more erlang prebuilts.

## elixir-2018-06-22-144237

* OTP 20.3.8 and 21.0 are now prebuilt.
* Update default OTP to 20.3.8, and default Elixir to 1.6.6
* Update gcloud to 205.0.0
* Build image now includes automake, fop, and xsltproc, to support recent
  asdf-erlang changes.

## elixir-2018-06-10-064921

* OTP 20.3.7 is prebuilt and is the default.
* Update gcloud to 204.0.0
* Pin prebuilt OTP image tags in each runtime release.

## elixir-2018-06-01-105216

* OTP 20.3.3, 20.3.4, 20.3.5, and 20.3.6 are now prebuilt.
* Update default OTP to 20.3.6, and default Elixir to 1.6.5
* Update asdf to 0.5.0, nodejs to 8.11.2, and gcloud to 203.0.0

## elixir-2018-04-03-180947

* OTP 20.3.2 is prebuilt and is the default
* Update nodejs to 8.11.1, and gcloud to 196.0.0

## elixir-2018-03-19-203701

* OTP 20.2.4, 20.3, and 20.3.1 are now prebuilt.
* Update default OTP from 20.2.2 to 20.3.1 and Elixir from 1.6.1 to 1.6.4.
* Update asdf to 0.4.3, nodejs to 8.10.0, and gcloud to 193.0.0

## elixir-2018-02-25-171329

* OTP 20.2.3 is now prebuilt.
* Update default Elixir from 1.5.3 to 1.6.1
* Update asdf to 0.4.2 and gcloud to 189.0.0

## elixir-2018-01-20-210216

* Prebuilt patch releases of OTP 20. Update default OTP to 20.2.2.

## elixir-2018-01-17-121145

* Support for building releases in an environment other than `prod`.
* OTP 20.2 is now prebuilt. Update default OTP from 20.1 to 20.2.
* Update default Elixir from 1.5.2 to 1.5.3.
* Update NodeJS to 8.9.4 and GCloud to 185.0.0 in the build image.
* Don't attempt to prepend `exec` to entrypoints that set environment variables
  inline.

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
