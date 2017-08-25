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

  @default_project_id "(unknown)"
  @default_workspace_dir "/workspace"
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

  def init(args) do
    try do
      workspace_dir = Keyword.get(args, :workspace_dir, @default_workspace_dir)
      data = build_data(workspace_dir)
      {:ok, data}
    catch
      {:usage_error, message} -> {:ok, %{error: message}}
    end
  end

  def handle_call({:get, key}, _from, data) do
    {:reply, Map.fetch(data, key), data}
  end

  defp build_data(workspace_dir) do
    project_id = System.get_env("PROJECT_ID") || @default_project_id

    deps_info = analyze_deps(workspace_dir)
    phoenix_prefix = get_phoenix_prefix(deps_info)

    app_yaml_path = System.get_env("GAE_APPLICATION_YAML_PATH") || @default_app_yaml_path
    app_config = load_config(workspace_dir, app_yaml_path)
    runtime_config = Map.get(app_config, "runtime_config") |> ensure_map
    beta_settings = Map.get(app_config, "beta_settings") |> ensure_map
    lifecycle = Map.get(app_config, "lifecycle") |> ensure_map

    service_name = Map.get(app_config, "service", @default_service_name)
    env_variables = get_env_variables(app_config)
    install_packages = get_install_packages(runtime_config, app_config)
    cloud_sql_instances = get_cloud_sql_instances(beta_settings)
    entrypoint = get_entrypoint(runtime_config, app_config, phoenix_prefix)
    build_scripts = get_build_scripts(lifecycle, runtime_config, workspace_dir, phoenix_prefix)

    %{
      workspace_dir: workspace_dir,
      project_id: project_id,
      app_yaml_path: app_yaml_path,
      runtime_config: runtime_config,
      service_name: service_name,
      env_variables: env_variables,
      install_packages: install_packages,
      cloud_sql_instances: cloud_sql_instances,
      entrypoint: entrypoint,
      build_scripts: build_scripts
    }
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

  defp get_phoenix_prefix(%{phoenix: version}) do
    if Version.compare(version, "1.3.0") == :lt, do: "phoenix", else: "phx"
  end
  defp get_phoenix_prefix(_), do: nil

  defp get_env_variables(app_config) do
    Map.get(app_config, "env_variables")
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
      Map.get_lazy(runtime_config, "packages", fn ->
        Map.get(app_config, "packages")
      end)
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
    cloud_sql_instances = Map.get(beta_settings, "cloud_sql_instances")
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

  defp get_entrypoint(runtime_config, app_config, phoenix_prefix) do
    Map.get_lazy(runtime_config, "entrypoint", fn ->
      Map.get_lazy(app_config, "entrypoint", fn ->
        e = default_entrypoint(phoenix_prefix)
        Logger.warn("No entrypoint specified. Guessing a default: `#{e}`.")
        Logger.warn("To use a different entrypoint, add an `entrypoint` field to your config.")
        e
      end)
    end)
    |> validate_entrypoint
    |> decorate_entrypoint
  end

  defp default_entrypoint(nil), do: "mix run --no-halt"
  defp default_entrypoint(phoenix_prefix), do: "mix #{phoenix_prefix}.server"

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

  defp get_build_scripts(lifecycle, runtime_config, workspace_dir, phoenix_prefix) do
    Map.get_lazy(lifecycle, "build", fn ->
      Map.get_lazy(runtime_config, "build", fn ->
        default_build_scripts(workspace_dir, phoenix_prefix)
      end)
    end)
    |> List.wrap
    |> validate_build_scripts
  end

  defp default_build_scripts(_workspace_dir, nil), do: []
  defp default_build_scripts(workspace_dir, phoenix_prefix) do
    cond do
      File.regular?(Path.join(workspace_dir, "package.json")) &&
          File.regular?(Path.join(workspace_dir, "brunch-config.js")) ->
        Logger.info("Installing brunch build and phoenix digest as a default build step.")
        ["npm install && node_modules/brunch/bin/brunch build --production && mix #{phoenix_prefix}.digest"]
      File.regular?(Path.join([workspace_dir, "assets", "package.json"])) &&
          File.regular?(Path.join([workspace_dir, "assets", "brunch-config.js"])) ->
        Logger.info("Installing brunch build and phoenix digest as a default build step.")
        ["cd assets && npm install && node_modules/brunch/bin/brunch build --production && cd .. && mix #{phoenix_prefix}.digest"]
      true ->
        []
    end
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
