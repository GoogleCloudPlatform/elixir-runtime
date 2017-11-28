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

  test "Minimal plug app" do
    config = """
      env: flex
      runtime: elixir
      """
    run_app_test("minimal_plug", config)
  end

  test "Minimal phoenix app" do
    config = """
      env: flex
      runtime: elixir
      """
    run_app_test("minimal_phoenix", config,
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-f", "/app/priv/static/cache_manifest.json"],
          show: true)
        assert_cmd_output(
          ["docker", "run", "--rm", image, "elixir", "--version"], ~r{1\.5\.1}, show: true)
      end)
  end

  test "Minimal phoenix app with release" do
    config = """
      env: flex
      runtime: elixir
      runtime_config:
        release_app: minimal_phoenix
      """
    run_app_test("minimal_phoenix", config,
      check_image: fn image ->
        assert_cmd_succeeds(
          ["docker", "run", "--rm", image, "test", "-x", "/app/bin/minimal_phoenix"],
          show: true)
      end,
      check_container: fn _container ->
        assert_cmd_output(["curl", "-s", "-S", "http://localhost:8080/elixir-version"],
          "1.5.1", timeout: 10, show: true, verbose: true)
      end)
  end

  @apps_dir Path.join(__DIR__, "sample_apps")
  @tmp_dir Path.join(__DIR__, "tmp")

  def run_app_test(app_name, config, opts \\ []) do
    check_container = Keyword.get(opts, :check_container, nil)
    check_image = Keyword.get(opts, :check_image, nil)

    File.rm_rf!(@tmp_dir)
    @apps_dir
    |> Path.join(app_name)
    |> File.cp_r!(@tmp_dir)
    @tmp_dir
    |> Path.join("app.yaml")
    |> File.write!(config)

    assert_cmd_succeeds(
      ["docker", "run","--rm",
        "-v", "#{@tmp_dir}:/workspace", "-w", "/workspace",
        "elixir-generate-dockerfile"], show: true, verbose: true)

    File.cd!(@tmp_dir, fn ->
      build_docker_image(fn image ->
        if check_image != nil do
          check_image.(image)
        end
        run_docker_daemon(["-p", "8080:8080", image], fn container ->
          if check_container != nil do
            check_container.(container)
          end
          assert_cmd_output(["curl", "-s", "-S", "http://localhost:8080"],
            ~r{Hello, world!}, timeout: 10, show: true, verbose: true)
        end)
      end)
    end)
  end
end
