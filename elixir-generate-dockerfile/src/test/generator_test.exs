# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule GeneratorTest do
  use ExUnit.Case
  alias GenerateDockerfile.Generator

  @test_dir __DIR__
  @cases_dir Path.join(@test_dir, "app_config")
  @tmp_dir Path.join(@test_dir, "tmp")
  @template_dir Path.expand("../../app", @test_dir)

  @minimal_config """
  env: flex
  runtime: gs://elixir-runtime/elixir.yaml
  """

  test "minimal directory with minimal config" do
    run_generator("minimal", @minimal_config)
    assert_ignore_line("Dockerfile")
    refute_ignore_line("priv/static")
    refute_file_contents(Path.join(@tmp_dir, ".dockerignore"), ~r{node_modules}m)
    assert_dockerfile_line("## Service: default")
    assert_dockerfile_line("## Project: (unknown)")
    assert_dockerfile_line("FROM gcr.io/gcp-elixir/runtime/ubuntu16/builder AS app-build")
    assert_dockerfile_line("#     && apt-get install -y -q package-name")
    assert_dockerfile_line("ARG erlang_version=\"20.2\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.3-otp-20\"")
    assert_dockerfile_line("RUN asdf plugin-update erlang")
    assert_dockerfile_line("# RUN gcloud config set project my-project-id")
    assert_dockerfile_line("# ENV NAME=\"value\"")
    assert_dockerfile_line("# ENV BUILD_CLOUDSQL_INSTANCES=\"my-project-id:db-region:db-name\"")
    refute_dockerfile_line("RUN mix release --env=prod --verbose")
    assert_dockerfile_line("FROM gcr.io/gcp-elixir/runtime/ubuntu16/asdf")
    assert_dockerfile_line("CMD exec mix run --no-halt")
  end

  test "minimal directory with custom service" do
    config =
      @minimal_config <>
        """
        service: elixir_app
        """

    run_generator("minimal", config)
    assert_dockerfile_line("## Service: elixir_app")
  end

  test "minimal directory with custom project" do
    run_generator("minimal", @minimal_config, project: "actual-project")
    assert_dockerfile_line("## Project: actual-project")
    assert_dockerfile_line("RUN gcloud config set project actual-project")
  end

  test "minimal directory with custom entrypoint" do
    config =
      @minimal_config <>
        """
        entrypoint: my-entrypoint.sh
        """

    run_generator("minimal", config)
    assert_dockerfile_line("CMD exec my-entrypoint.sh")
  end

  test "minimal directory with environment variables" do
    config =
      @minimal_config <>
        """
        env_variables:
          VAR1: value1
          VAR2: value2
          VAR3: 123
        """

    run_generator("minimal", config)

    expected = """
    ENV VAR1="value1" \\
        VAR2="value2" \\
        VAR3="123"
    """

    assert_file_contents(Path.join(@tmp_dir, "Dockerfile"), expected)
  end

  test "minimal directory with cloudsql instances" do
    config =
      @minimal_config <>
        """
        beta_settings:
          cloud_sql_instances:
            - cloud-sql-instance-name,instance2:hi:there
            - instance3
        """

    run_generator("minimal", config)

    assert_dockerfile_line(
      "ENV BUILD_CLOUDSQL_INSTANCES=\"cloud-sql-instance-name,instance2:hi:there,instance3\""
    )
  end

  test "minimal directory with build scripts" do
    config =
      @minimal_config <>
        """
        runtime_config:
          build:
            - npm install
            - brunch build
        """

    run_generator("minimal", config)
    assert_dockerfile_line("RUN npm install")
    assert_dockerfile_line("RUN brunch build")
  end

  test "minimal directory with package installations" do
    config =
      @minimal_config <>
        """
        runtime_config:
          packages: libgeos
        """

    run_generator("minimal", config)
    assert_dockerfile_line("    && apt-get install -y -q libgeos")
  end

  test "minimal directory with release app" do
    config =
      @minimal_config <>
        """
        runtime_config:
          release_app: my_app
        """

    run_generator("minimal", config)
    assert_dockerfile_line("FROM gcr.io/gcp-elixir/runtime/ubuntu16/builder AS app-build")
    assert_dockerfile_line("ARG erlang_version=\"20.2\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.3-otp-20\"")
    assert_dockerfile_line("RUN asdf plugin-update erlang")
    assert_dockerfile_line("RUN mix release --env=prod --verbose")
    assert_dockerfile_line("COPY --from=app-build /app/_build/prod/rel/my_app /app/")
    assert_dockerfile_line("FROM gcr.io/gcp-elixir/runtime/ubuntu16")
    assert_dockerfile_line("CMD [\"/app/bin/my_app\",\"foreground\"]")
  end

  test "minimal directory with release app and custom entrypoint" do
    config =
      @minimal_config <>
        """
        runtime_config:
          release_app: my_app
        entrypoint: /app/bin/my_app foreground --blah
        """

    run_generator("minimal", config)
    assert_dockerfile_line("RUN mix release --env=prod --verbose")
    assert_dockerfile_line("CMD exec /app/bin/my_app foreground --blah")
  end

  test "minimal directory with release app and custom mix_env" do
    config =
      @minimal_config <>
        """
        runtime_config:
          release_app: my_app
        env_variables:
          MIX_ENV: staging
        """

    run_generator("minimal", config)
    assert_dockerfile_line("RUN mix release --env=staging --verbose")
    assert_dockerfile_line("COPY --from=app-build /app/_build/staging/rel/my_app /app/")
  end

  test "phoenix 1.2 directory" do
    run_generator("phoenix_1_2", @minimal_config)
    assert_ignore_line("priv/static")
    assert_ignore_line("node_modules")
    refute_dockerfile_line("RUN mix release --env=prod --verbose")
  end

  test "phoenix 1.3 directory with custom elixir" do
    run_generator("phoenix_1_3", @minimal_config)
    assert_ignore_line("priv/static")
    assert_ignore_line("assets/node_modules")
    assert_dockerfile_line("ARG erlang_version=\"20.2\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.1\"")
    refute_dockerfile_line("RUN mix release --env=prod --verbose")
  end

  test "phoenix umbrella 1.3 directory with custom erlang and elixir" do
    run_generator("phoenix_umbrella_1_3", @minimal_config)
    assert_ignore_line("priv/static")
    assert_ignore_line("apps/blog_web/assets/node_modules")
    assert_dockerfile_line("ARG erlang_version=\"20.0\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.1-otp-20\"")
    refute_dockerfile_line("RUN mix release --env=prod --verbose")
  end

  test "phoenix 1.3 directory with release app and custom elixir" do
    config =
      @minimal_config <>
        """
        runtime_config:
          release_app: blog
        """

    run_generator("phoenix_1_3", config)
    assert_dockerfile_line("ARG erlang_version=\"20.2\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.1\"")
    assert_dockerfile_line("RUN mix release --env=prod --verbose")
  end

  test "phoenix umbrella 1.3 directory with release app and custom erlang and elixir" do
    config =
      @minimal_config <>
        """
        runtime_config:
          release_app: blog
        """

    run_generator("phoenix_umbrella_1_3", config)
    assert_dockerfile_line("ARG erlang_version=\"20.0\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.1-otp-20\"")
    assert_dockerfile_line("RUN mix release --env=prod --verbose")
  end

  test "minimal directory with prebuilt erlang" do
    run_generator("minimal", @minimal_config, prebuilt_erlang_versions: "20.2")
    assert_dockerfile_line("ARG erlang_version=\"20.2\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.3-otp-20\"")

    assert_dockerfile_line(
      "COPY --from=gcr.io/gcp-elixir/runtime/ubuntu16/prebuilt/otp-20.2:latest"
    )
  end

  test "minimal directory with release app and prebuilt erlang" do
    config =
      @minimal_config <>
        """
        runtime_config:
          release_app: my_app
        """

    run_generator("minimal", config, prebuilt_erlang_versions: "20.2")
    assert_dockerfile_line("ARG erlang_version=\"20.2\"")
    assert_dockerfile_line("ARG elixir_version=\"1.5.3-otp-20\"")

    assert_dockerfile_line(
      "COPY --from=gcr.io/gcp-elixir/runtime/ubuntu16/prebuilt/otp-20.2:latest"
    )
  end

  defp run_generator(dir, config, args \\ []) do
    config_file = Keyword.get(args, :config_file, nil)
    project = Keyword.get(args, :project, nil)
    prebuilt_erlang_versions = Keyword.get(args, :prebuilt_erlang_versions, "")

    File.rm_rf!(@tmp_dir)

    if dir do
      full_dir = Path.join(@cases_dir, dir)
      File.cp_r!(full_dir, @tmp_dir)
    else
      File.mkdir!(@tmp_dir)
    end

    if config_file do
      System.put_env("GAE_APPLICATION_YAML_PATH", config_file)
    else
      System.delete_env("GAE_APPLICATION_YAML_PATH")
    end

    if project do
      System.put_env("PROJECT_ID", project)
    else
      System.delete_env("PROJECT_ID")
    end

    if config do
      @tmp_dir
      |> Path.join(config_file || "app.yaml")
      |> File.write!(config)
    end

    opts = [
      workspace_dir: @tmp_dir,
      template_dir: @template_dir,
      os_image: "gcr.io/gcp-elixir/runtime/ubuntu16",
      asdf_image: "gcr.io/gcp-elixir/runtime/ubuntu16/asdf",
      builder_image: "gcr.io/gcp-elixir/runtime/ubuntu16/builder",
      default_erlang_version: "20.2",
      default_elixir_version: "1.5.3-otp-20"
    ]

    opts =
      if prebuilt_erlang_versions == "" do
        opts
      else
        prebuilt_erlang_versions
        |> String.split(",")
        |> Enum.reduce(opts, fn v, o ->
          image = "#{v}=gcr.io/gcp-elixir/runtime/ubuntu16/prebuilt/otp-#{v}:latest"
          [{:prebuilt_erlang_images, image} | o]
        end)
      end

    Generator.execute(opts)
  end

  defp assert_file_contents(path, expectations) do
    expectations = List.wrap(expectations)
    contents = File.read!(path)

    Enum.each(expectations, fn expectation ->
      assert(contents =~ expectation, "File #{path} did not contain #{inspect(expectation)}")
    end)

    contents
  end

  defp refute_file_contents(path, expectations) do
    expectations = List.wrap(expectations)
    contents = File.read!(path)

    Enum.each(expectations, fn expectation ->
      refute(contents =~ expectation, "File #{path} contained #{inspect(expectation)}")
    end)

    contents
  end

  defp assert_dockerfile_line(line) do
    line = Regex.escape(line)
    path = Path.join(@tmp_dir, "Dockerfile")
    assert_file_contents(path, ~r{^#{line}}m)
  end

  defp refute_dockerfile_line(line) do
    line = Regex.escape(line)
    path = Path.join(@tmp_dir, "Dockerfile")
    refute_file_contents(path, ~r{^#{line}}m)
  end

  defp assert_ignore_line(line) do
    line = Regex.escape(line)
    path = Path.join(@tmp_dir, ".dockerignore")
    assert_file_contents(path, ~r{^#{line}}m)
  end

  defp refute_ignore_line(line) do
    line = Regex.escape(line)
    path = Path.join(@tmp_dir, ".dockerignore")
    refute_file_contents(path, ~r{^#{line}}m)
  end
end
