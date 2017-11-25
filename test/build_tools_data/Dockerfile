FROM elixir-base
RUN apt-get update -y && apt-get install -y -q python2.7 && apt-get clean && rm -f /var/lib/apt/lists/*_*
COPY --from=elixir-build-tools /build_tools/ /build_tools/
ENV PATH /build_tools:/build_tools/google-cloud-sdk/bin:/build_tools/nodejs/bin:/build_tools/yarn/bin:${PATH}
