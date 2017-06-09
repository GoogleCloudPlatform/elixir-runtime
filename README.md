# Docker image for the App Engine Flexible Elixir/Erlang runtimes

This respository contains a runtime definition for Elixir and Erlang for Google App Engine Flexible Environment
and other Docker hosts. It is not covered by any SLA or deprecation policy. It may change at any time.

## Building

The following command builds many versions of the Erlang and Elixir runtime images using
[Google Cloud Container Builder](https://cloud.google.com/container-builder/). Replace the `_TAG` value
with whatever you want the final docker images' tag to be exported as.

```bash
gcloud container builds submit --config cloudbuild.yaml --substitutions _TAG=dev
```
