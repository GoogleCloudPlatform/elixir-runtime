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

defmodule SampleAppBuildTest do
  use ExUnit.Case
  import TestHelper

  @moduletag timeout: 300_000

  test "Minimal plug app" do
    run_app_test("minimal_plug")
  end

  test "Minimal phoenix app" do
    run_app_test(
      "minimal_phoenix",
      tool_versions: "elixir 1.8.2-otp-22\n",
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-f", "/app/priv/static/cache_manifest.json"],
          show: true
        )

        assert_cmd_output(
          ["docker", "run", "--rm", image, "elixir", "--version"],
          ~r{1\.8\.2},
          show: true
        )
      end
    )
  end

  test "Minimal phoenix app with release" do
    config = """
    env: flex
    runtime: elixir
    runtime_config:
      release_app: minimal_phoenix
    """

    run_app_test(
      "minimal_phoenix",
      tool_versions: "elixir 1.8.2-otp-22\n",
      config: config,
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-x", "/app/bin/minimal_phoenix"],
          show: true
        )
      end,
      check_container: fn _container ->
        assert_cmd_output(
          ["curl", "-s", "-S", "http://localhost:8080/elixir-version"],
          "1.8.2",
          timeout: 10,
          show: true,
          verbose: true
        )
      end
    )
  end

  test "Minimal phoenix app in staging environment" do
    config = """
    env: flex
    runtime: elixir
    env_variables:
      MIX_ENV: staging
    entrypoint: MIX_ENV=staging mix phx.server
    """

    run_app_test(
      "minimal_phoenix",
      tool_versions: "elixir 1.8.2-otp-22\n",
      config: config,
      expected_output: ~r{from staging}
    )
  end

  test "Minimal phoenix app with release in staging environment" do
    config = """
    env: flex
    runtime: elixir
    runtime_config:
      release_app: minimal_phoenix
    env_variables:
      MIX_ENV: staging
    """

    run_app_test(
      "minimal_phoenix",
      tool_versions: "elixir 1.8.2-otp-22\n",
      config: config,
      expected_output: ~r{from staging}
    )
  end

  test "Minimal phoenix 1.4 app" do
    run_app_test(
      "minimal_phoenix14",
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-f", "/app/priv/static/cache_manifest.json"],
          show: true
        )

        assert_cmd_output(
          ["docker", "run", "--rm", image, "elixir", "--version"],
          ~r{1\.11\.4},
          show: true
        )
      end
    )
  end

  test "Minimal phoenix 1.4 app with elixir 1.9 release" do
    config = """
    env: flex
    runtime: elixir
    runtime_config:
      release_app: minimal_phoenix14
    """

    run_app_test(
      "minimal_phoenix14",
      config: config,
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-x", "/app/bin/minimal_phoenix14"],
          show: true
        )
      end,
      check_container: fn _container ->
        assert_cmd_output(
          ["curl", "-s", "-S", "http://localhost:8080/elixir-version"],
          "1.11.4",
          timeout: 10,
          show: true,
          verbose: true
        )
      end
    )
  end

  test "Minimal phoenix 1.4 app with distillery 2.1 release" do
    config = """
    env: flex
    runtime: elixir
    runtime_config:
      release_app: minimal_phoenix14
    """

    run_app_test(
      "minimal_phoenix14",
      config: config,
      postprocess_dir: fn dir ->
        File.rename!(Path.join(dir, "mix-dist21.exs"), Path.join(dir, "mix.exs"))
        File.rename!(Path.join(dir, "mix-dist21.lock"), Path.join(dir, "mix.lock"))
      end,
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-x", "/app/bin/minimal_phoenix14"],
          show: true
        )
      end,
      check_container: fn _container ->
        assert_cmd_output(
          ["curl", "-s", "-S", "http://localhost:8080/elixir-version"],
          "1.11.4",
          timeout: 10,
          show: true,
          verbose: true
        )
      end
    )
  end

  test "Minimal phoenix 1.4 app with distillery 2.0 release" do
    config = """
    env: flex
    runtime: elixir
    runtime_config:
      release_app: minimal_phoenix14
    """

    run_app_test(
      "minimal_phoenix14",
      config: config,
      postprocess_dir: fn dir ->
        config_path = Path.join([dir, "rel", "config.exs"])

        str =
          config_path
          |> File.read!()
          |> String.replace("Distillery.Releases.Config", "Mix.Releases.Config")

        File.write!(config_path, str)
        File.rename!(Path.join(dir, "mix-dist20.exs"), Path.join(dir, "mix.exs"))
        File.rename!(Path.join(dir, "mix-dist20.lock"), Path.join(dir, "mix.lock"))
      end,
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-x", "/app/bin/minimal_phoenix14"],
          show: true
        )
      end,
      check_container: fn _container ->
        assert_cmd_output(
          ["curl", "-s", "-S", "http://localhost:8080/elixir-version"],
          "1.8.2",
          timeout: 10,
          show: true,
          verbose: true
        )
      end
    )
  end

  @apps_dir Path.join(__DIR__, "sample_apps")
  @tmp_dir Path.join(__DIR__, "tmp")
  @default_config """
  env: flex
  runtime: elixir
  """

  def run_app_test(app_name, opts \\ []) do
    check_container = Keyword.get(opts, :check_container, nil)
    check_image = Keyword.get(opts, :check_image, nil)
    expected_output = Keyword.get(opts, :expected_output, ~r{Hello, world!})
    config = Keyword.get(opts, :config, @default_config)
    tool_versions = Keyword.get(opts, :tool_versions, nil)
    postprocess_dir = Keyword.get(opts, :postprocess_dir, nil)

    File.rm_rf!(@tmp_dir)

    @apps_dir
    |> Path.join(app_name)
    |> File.cp_r!(@tmp_dir)

    @tmp_dir
    |> Path.join("app.yaml")
    |> File.write!(config)

    if tool_versions != nil do
      @tmp_dir
      |> Path.join(".tool-versions")
      |> File.write!(tool_versions)
    end

    if postprocess_dir != nil, do: postprocess_dir.(@tmp_dir)

    assert_cmd_succeeds(
      [
        "docker",
        "run",
        "--rm",
        "-v",
        "#{@tmp_dir}:/workspace",
        "-w",
        "/workspace",
        "elixir-generate-dockerfile"
      ],
      show: true,
      verbose: true
    )

    File.cd!(@tmp_dir, fn ->
      build_docker_image(fn image ->
        if check_image != nil do
          check_image.(image)
        end

        run_docker_daemon(["-p", "8080:8080", image], fn container ->
          if check_container != nil do
            check_container.(container)
          end

          assert_cmd_output(
            ["curl", "-s", "-S", "http://localhost:8080"],
            expected_output,
            timeout: 10,
            show: true,
            verbose: true
          )
        end)
      end)
    end)
  end
end
