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

defmodule AppConfigTest do
  use ExUnit.Case
  alias GenerateDockerfile.AppConfig

  @test_dir __DIR__
  @cases_dir Path.join(@test_dir, "app_config")
  @tmp_dir Path.join(@test_dir, "tmp")
  @default_erlang_version "20.2"
  @default_elixir_version "1.5.3-otp-20"

  @minimal_config """
  env: flex
  runtime: gs://elixir-runtime/elixir.yaml
  """

  def setup_test(dir, config, args \\ []) do
    config_file = Keyword.get(args, :config_file, nil)
    project = Keyword.get(args, :project, nil)

    File.cd!(@test_dir)
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
      config_path = Path.join(@tmp_dir, config_file || "app.yaml")
      File.write!(config_path, config)
    end

    {:ok, pid} =
      AppConfig.start_link(
        workspace_dir: @tmp_dir,
        default_erlang_version: @default_erlang_version,
        default_elixir_version: @default_elixir_version,
        register_module: false
      )

    pid
  end

  test "minimal directory with config" do
    pid = AppConfigTest.setup_test("minimal", @minimal_config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:workspace_dir, pid) == @tmp_dir
    assert AppConfig.get!(:project_id, pid) == nil
    assert AppConfig.get!(:project_id_for_display, pid) == "(unknown)"
    assert AppConfig.get!(:project_id_for_example, pid) == "my-project-id"
    assert AppConfig.get!(:app_yaml_path, pid) == "app.yaml"
    assert AppConfig.get!(:runtime_config, pid) == %{}
    assert AppConfig.get!(:service_name, pid) == "default"
    assert AppConfig.get!(:env_variables, pid) == %{}
    assert AppConfig.get!(:mix_env, pid) == "prod"
    assert AppConfig.get!(:install_packages, pid) == []
    assert AppConfig.get!(:cloud_sql_instances, pid) == []
    assert AppConfig.get!(:entrypoint, pid) == "exec mix run --no-halt"
    assert AppConfig.get!(:phoenix_version, pid) == nil
    assert AppConfig.get!(:brunch_dir, pid) == nil
    assert AppConfig.get!(:build_scripts, pid) == []
    assert AppConfig.get!(:erlang_version, pid) == @default_erlang_version
    assert AppConfig.get!(:elixir_version, pid) == @default_elixir_version
  end

  test "custom project" do
    pid = AppConfigTest.setup_test("minimal", @minimal_config, project: "actual-project")
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:project_id, pid) == "actual-project"
    assert AppConfig.get!(:project_id_for_display, pid) == "actual-project"
    assert AppConfig.get!(:project_id_for_example, pid) == "actual-project"
  end

  test "basic app.yaml" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    service: elixir_app
    entrypoint: mix app.start
    env_variables:
      VAR1: value1
      VAR2: value2
      VAR3: 123
    beta_settings:
      cloud_sql_instances:
        - cloud-sql-instance-name,instance2:hi:there
        - instance3
    runtime_config:
      foo: bar
      packages: libgeos
      build:
        - npm install
        - brunch build
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:service_name, pid) == "elixir_app"
    assert AppConfig.get!(:release_app, pid) == nil

    assert AppConfig.get!(:env_variables, pid) ==
             %{"VAR1" => "value1", "VAR2" => "value2", "VAR3" => "123"}

    assert AppConfig.get!(:cloud_sql_instances, pid) ==
             ["cloud-sql-instance-name", "instance2:hi:there", "instance3"]

    assert AppConfig.get!(:build_scripts, pid) == ["npm install", "brunch build"]
    assert AppConfig.get!(:entrypoint, pid) == "exec mix app.start"
    assert AppConfig.get!(:install_packages, pid) == ["libgeos"]
    assert AppConfig.get!(:runtime_config, pid)["foo"] == "bar"
  end

  test "MIX_ENV set from env_variables" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    env_variables:
      MIX_ENV: staging
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:env_variables, pid) == %{"MIX_ENV" => "staging"}
    assert AppConfig.get!(:mix_env, pid) == "staging"
  end

  test "release_app set" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    runtime_config:
      release_app: my_app
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:release_app, pid) == "my_app"
    assert AppConfig.get!(:entrypoint, pid) == "[\"/app/bin/my_app\",\"foreground\"]"
  end

  test "release_app with custom entrypoint" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    runtime_config:
      release_app: my_app
      entrypoint: mix app.start
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:release_app, pid) == "my_app"
    assert AppConfig.get!(:entrypoint, pid) == "exec mix app.start"
  end

  test "complex entrypoint" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    entrypoint: cd myapp; mix app.start
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:entrypoint, pid) == "cd myapp; mix app.start"
  end

  test "entrypoint including environment variables" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    entrypoint: MIX_ENV=staging mix app.start
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:entrypoint, pid) == "MIX_ENV=staging mix app.start"
  end

  test "entrypoint already including exec" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    entrypoint: exec mix app.start
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:entrypoint, pid) == "exec mix app.start"
  end

  test "phoenix 1.3 defaults" do
    pid = AppConfigTest.setup_test("phoenix_1_3", @minimal_config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:entrypoint, pid) == "exec mix phx.server"
    assert AppConfig.get!(:phoenix_version, pid) == "1.3.0"
    assert AppConfig.get!(:brunch_dir, pid) == "assets"

    assert AppConfig.get!(:build_scripts, pid) == [
             "cd assets && npm install && node_modules/brunch/bin/brunch build --production && cd .. && mix phx.digest"
           ]

    assert AppConfig.get!(:erlang_version, pid) == @default_erlang_version
    assert AppConfig.get!(:elixir_version, pid) == "1.5.1"
  end

  test "phoenix umbrella 1.3 defaults" do
    pid = AppConfigTest.setup_test("phoenix_umbrella_1_3", @minimal_config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:entrypoint, pid) == "exec mix phx.server"
    assert AppConfig.get!(:phoenix_version, pid) == "1.3.0"
    assert AppConfig.get!(:brunch_dir, pid) == "apps/blog_web/assets"

    assert AppConfig.get!(:build_scripts, pid) == [
             "cd apps/blog_web/assets && npm install && node_modules/brunch/bin/brunch build --production && cd .. && mix phx.digest"
           ]

    assert AppConfig.get!(:erlang_version, pid) == "20.0"
    assert AppConfig.get!(:elixir_version, pid) == "1.5.1-otp-20"
  end

  test "phoenix 1.2 defaults" do
    pid = AppConfigTest.setup_test("phoenix_1_2", @minimal_config)
    assert AppConfig.status(pid) == :ok
    assert AppConfig.get!(:entrypoint, pid) == "exec mix phoenix.server"
    assert AppConfig.get!(:phoenix_version, pid) == "1.2.5"
    assert AppConfig.get!(:brunch_dir, pid) == "."

    assert AppConfig.get!(:build_scripts, pid) == [
             "npm install && node_modules/brunch/bin/brunch build --production && mix phoenix.digest"
           ]
  end

  test "missing app engine config" do
    pid = AppConfigTest.setup_test("minimal", nil)
    assert AppConfig.status(pid) == {:error, "Unable to find required `app.yaml` file."}
  end

  test "missing mix config" do
    pid = AppConfigTest.setup_test(nil, @minimal_config)
    assert AppConfig.status(pid) == {:error, "Unable to find required `mix.lock` file."}
  end

  test "illegal env variable name" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    env_variables:
      VAR-1: value1
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == {:error, "Illegal environment variable name: `VAR-1`."}
  end

  test "illegal debian package name" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    runtime_config:
      packages: bad!package
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == {:error, "Illegal debian package name: `bad!package`."}
  end

  test "illegal cloud sql instance name" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    beta_settings:
      cloud_sql_instances: bad!instance
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == {:error, "Illegal cloud sql instance name: `bad!instance`."}
  end

  test "entrypoint contains newline" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    entrypoint: "multiple\\nlines"
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == {:error, "Entrypoint may not contain a newline."}
  end

  test "build script contains newline" do
    config = """
    env: flex
    runtime: gs://elixir-runtime/elixir.yaml
    runtime_config:
      build: "multiple\\nlines"
    """

    pid = AppConfigTest.setup_test("minimal", config)
    assert AppConfig.status(pid) == {:error, "A build script may not contain a newline."}
  end
end
