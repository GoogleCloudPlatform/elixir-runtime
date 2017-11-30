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

defmodule GenerateDockerfile.AppConfig do
  require Logger

  @default_app_yaml_path "app.yaml"
  @default_service_name "default"

  def start_link(args) do
    register_module = Keyword.get(args, :register_module, true)
    opts = if register_module, do: [name: __MODULE__], else: []
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get(key, server \\ __MODULE__) do
    GenServer.call(server, {:get, key})
  end

  def get!(key, server \\ __MODULE__) do
    {:ok, result} = GenServer.call(server, {:get, key})
    result
  end

  def status(server \\ __MODULE__) do
    case GenServer.call(server, {:get, :error}) do
      {:ok, error} -> {:error, error}
      :error -> :ok
    end
  end


  use GenServer

  defmodule MetadataFetcher do
    use Tesla

    plug Tesla.Middleware.Tuples
    plug Tesla.Middleware.BaseUrl, "http://169.254.169.254"
    plug Tesla.Middleware.Headers, %{"Metadata-Flavor" => "Google"}
    plug Tesla.Middleware.Opts, timeout: 100

    def get_project_id do
      "/computeMetadata/v1/project/project-id" |> get() |> handle_response()
    end

    def handle_response({:ok, %{status: 200, body: body}}), do: body
    def handle_response(_), do: nil
  end
  alias GenerateDockerfile.AppConfig.MetadataFetcher

  def init(args) do
    try do
      workspace_dir = Keyword.fetch!(args, :workspace_dir)
      default_erlang_version = Keyword.fetch!(args, :default_erlang_version)
      default_elixir_version = Keyword.fetch!(args, :default_elixir_version)
      data = build_data(workspace_dir, default_erlang_version, default_elixir_version)
      {:ok, data}
    catch
      {:usage_error, message} -> {:ok, %{error: message}}
    end
  end

  def handle_call({:get, key}, _from, data) do
    {:reply, Map.fetch(data, key), data}
  end

  defp build_data(workspace_dir, default_erlang_version, default_elixir_version) do
    project_id = get_project()
    project_id_for_display = project_id || "(unknown)"
    project_id_for_example = project_id || "my-project-id"

    deps_info = analyze_deps(workspace_dir)
    phoenix_version = Map.get(deps_info, :phoenix)
    phoenix_prefix = get_phoenix_prefix(phoenix_version)

    {erlang_version, elixir_version} =
      get_tool_versions(workspace_dir, default_erlang_version, default_elixir_version)

    app_yaml_path = System.get_env("GAE_APPLICATION_YAML_PATH") || @default_app_yaml_path
    app_config = load_config(workspace_dir, app_yaml_path)
    runtime_config = Map.get(app_config, "runtime_config") |> ensure_map
    beta_settings = Map.get(app_config, "beta_settings") |> ensure_map

    service_name = Map.get(app_config, "service", @default_service_name)
    release_app = Map.get(runtime_config, "release_app")
    env_variables = get_env_variables(app_config)
    install_packages = get_install_packages(runtime_config, app_config)
    cloud_sql_instances = get_cloud_sql_instances(beta_settings)
    entrypoint = get_entrypoint(runtime_config, app_config, phoenix_prefix, release_app)
    brunch_dir = get_brunch_dir(workspace_dir, phoenix_version)
    build_scripts = get_build_scripts(runtime_config, brunch_dir, phoenix_prefix)

    %{
      workspace_dir: workspace_dir,
      project_id: project_id,
      project_id_for_display: project_id_for_display,
      project_id_for_example: project_id_for_example,
      erlang_version: erlang_version,
      elixir_version: elixir_version,
      app_yaml_path: app_yaml_path,
      runtime_config: runtime_config,
      service_name: service_name,
      release_app: release_app,
      env_variables: env_variables,
      install_packages: install_packages,
      cloud_sql_instances: cloud_sql_instances,
      phoenix_version: phoenix_version,
      brunch_dir: brunch_dir,
      entrypoint: entrypoint,
      build_scripts: build_scripts
    }
  end

  defp get_project() do
    project_id = System.get_env("PROJECT_ID")
    if project_id == nil do
      if System.get_env("CI") == "true" && System.get_env("TRAVIS") == "true" do
        nil
      else
        MetadataFetcher.get_project_id()
      end
    else
      project_id
    end
  end

  defp load_config(workspace_dir, app_yaml_path) do
    app_config_path = Path.join(workspace_dir, app_yaml_path)
    unless File.regular?(app_config_path) do
      throw {:usage_error, "Unable to find required `#{app_yaml_path}` file."}
    end
    YamlElixir.read_from_file(app_config_path)
  end

  defp analyze_deps(workspace_dir) do
    mix_lock_path = Path.join(workspace_dir, "mix.lock")
    unless File.regular?(mix_lock_path) do
      throw {:usage_error, "Unable to find required `mix.lock` file."}
    end
    {result, _} = Code.eval_file(mix_lock_path)

    [:phoenix]
    |> Enum.reduce(%{}, fn
      (pkg, acc) ->
        pkg_info = result[pkg]
        if is_tuple(pkg_info) do
          version = elem(pkg_info, 2) |> to_string
          if Version.parse(version) == :error do
            acc
          else
            Logger.info("Detected #{pkg} #{version}")
            Map.put(acc, pkg, version)
          end
        else
          acc
        end
    end)
  end

  defp get_phoenix_prefix(nil), do: nil
  defp get_phoenix_prefix(version) do
    if Version.compare(version, "1.3.0") == :lt, do: "phoenix", else: "phx"
  end

  defp get_tool_versions(workspace_dir, default_erlang_version, default_elixir_version) do
    tool_versions_path = Path.join(workspace_dir, ".tool-versions")
    {erlang_version, elixir_version} =
      if File.regular?(tool_versions_path) do
        tool_versions_content = File.read!(tool_versions_path)
        erlang_tool_version =
          Regex.run(~r{^erlang\s+(.+)$}m, tool_versions_content)
          |> case do
            nil -> nil
            [_, version] -> version
          end
        elixir_tool_version =
          Regex.run(~r{^elixir\s+(.+)$}m, tool_versions_content)
          |> case do
            nil -> nil
            [_, version] -> version
          end
        if erlang_tool_version && !elixir_tool_version do
          Logger.warn(
            "You have set the erlang version but not the elixir version in" <>
            " your .tool-versions file. It is recommended to specify the" <>
            " elixir version also, because the default may change at any time.")
        end
        if elixir_tool_version && !erlang_tool_version do
          Logger.warn(
            "You have set the elixir version but not the erlang version in" <>
            " your .tool-versions file. It is recommended to specify the" <>
            " erlang version also, because the default may change at any time.")
        end
        {erlang_tool_version || default_erlang_version,
         elixir_tool_version || default_elixir_version}
      else
        {default_erlang_version, default_elixir_version}
      end
    Logger.info("Using Erlang #{erlang_version} and Elixir #{elixir_version}.")
    {erlang_version, elixir_version}
  end

  defp get_env_variables(app_config) do
    app_config
    |> Map.get("env_variables")
    |> ensure_map
    |> Enum.reduce(%{},
      fn ({k, v}, acc) ->
        k_str = to_string(k)
        v_str = to_string(v)
        unless Regex.match?(~r{\A[a-zA-Z]\w*\z}, k_str) do
          throw {:usage_error, "Illegal environment variable name: `#{k_str}`."}
        end
        Map.put(acc, k_str, v_str)
      end)
  end

  defp get_install_packages(runtime_config, app_config) do
    install_packages =
      runtime_config
      |> Map.get_lazy("packages", fn -> Map.get(app_config, "packages") end)
      |> List.wrap
    Enum.each(install_packages,
      fn pkg ->
        unless Regex.match?(~r{\A[\w.-]+\z}, pkg) do
          throw {:usage_error, "Illegal debian package name: `#{pkg}`."}
        end
      end)
    install_packages
  end

  defp get_cloud_sql_instances(beta_settings) do
    cloud_sql_instances =
      beta_settings
      |> Map.get("cloud_sql_instances")
      |> List.wrap
      |> Enum.flat_map(fn inst -> String.split(inst, ",") end)
    Enum.each(cloud_sql_instances,
      fn name ->
        unless Regex.match?(~r{\A[\w:.-]+\z}, name) do
          throw {:usage_error, "Illegal cloud sql instance name: `#{name}`."}
        end
      end)
    cloud_sql_instances
  end

  defp get_entrypoint(runtime_config, app_config, phoenix_prefix, release_app) do
    Map.get_lazy(runtime_config, "entrypoint", fn ->
      Map.get_lazy(app_config, "entrypoint", fn ->
        default_entrypoint(phoenix_prefix, release_app)
      end)
    end)
    |> validate_entrypoint
    |> decorate_entrypoint
  end

  defp default_entrypoint(nil, nil) do
    warn_default_entrypoint("mix run --no-halt")
  end
  defp default_entrypoint(phoenix_prefix, nil) do
    warn_default_entrypoint("mix #{phoenix_prefix}.server")
  end
  defp default_entrypoint(_phoenix_prefix, release_app) do
    ["/app/bin/#{release_app}", "foreground"]
  end

  defp warn_default_entrypoint(entrypoint) do
    Logger.warn("No entrypoint specified. Guessing a default: `#{entrypoint}`.")
    Logger.warn("To use a different entrypoint, add an `entrypoint` field to your config.")
    entrypoint
  end

  defp validate_entrypoint(entrypoint) when is_list(entrypoint) do
    Enum.map(entrypoint, &validate_entrypoint/1)
  end
  defp validate_entrypoint("") do
    throw {:usage_error, "Entrypoint may not be empty."}
  end
  defp validate_entrypoint(entrypoint) when is_binary(entrypoint) do
    if String.contains?(entrypoint, "\n") do
      throw {:usage_error, "Entrypoint may not contain a newline."}
    end
    entrypoint
  end

  defp decorate_entrypoint(entrypoint) when is_list(entrypoint) do
    Poison.encode!(entrypoint)
  end
  defp decorate_entrypoint(entrypoint) when is_binary(entrypoint) do
    cond do
      String.starts_with?(entrypoint, "exec ") ->
        entrypoint
      Regex.match?(~r{;|&&|\|}, entrypoint) ->
        entrypoint
      true ->
        "exec #{entrypoint}"
    end
  end

  defp get_brunch_dir(_workspace_dir, nil), do: nil
  defp get_brunch_dir(workspace_dir, _phoenix_version) do
    apps_dir = Path.join(workspace_dir, "apps")
    app_dirs = if File.dir?(apps_dir) do
      apps_dir
      |> File.ls!
      |> Enum.map(fn child -> Path.join(apps_dir, child) end)
      |> Enum.filter(fn path -> File.dir?(path) end)
    else
      []
    end

    [workspace_dir | app_dirs]
    |> Enum.flat_map(fn dir -> [dir, Path.join(dir, "assets")] end)
    |> Enum.find(fn dir ->
      File.regular?(Path.join(dir, "package.json")) && File.regular?(Path.join(dir, "brunch-config.js"))
    end)
    |> case do
      nil -> nil
      ^workspace_dir -> "."
      brunch_dir -> Path.relative_to(brunch_dir, workspace_dir)
    end
  end

  defp get_build_scripts(runtime_config, brunch_dir, phoenix_prefix) do
    runtime_config
    |> Map.get_lazy("build", fn -> default_build_scripts(brunch_dir, phoenix_prefix) end)
    |> List.wrap
    |> validate_build_scripts
  end

  defp default_build_scripts(nil, _phoenix_prefix), do: []
  defp default_build_scripts(".", phoenix_prefix) do
    ["npm install && node_modules/brunch/bin/brunch build --production && mix #{phoenix_prefix}.digest"]
  end
  defp default_build_scripts(brunch_dir, phoenix_prefix) do
    ["cd #{brunch_dir} && npm install && node_modules/brunch/bin/brunch build --production && cd .. && mix #{phoenix_prefix}.digest"]
  end

  defp validate_build_scripts(scripts) do
    Enum.each(scripts, fn script ->
      if String.contains?(script, "\n") do
        throw {:usage_error, "A build script may not contain a newline."}
      end
    end)
    scripts
  end

  defp ensure_map(value) when is_map(value), do: value
  defp ensure_map(_value), do: %{}
end
