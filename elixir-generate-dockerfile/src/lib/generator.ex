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

defmodule GenerateDockerfile.Generator do
  alias GenerateDockerfile.AppConfig
  require Logger

  @default_workspace_dir "/workspace"
  @default_template_dir "../app"
  @common_dockerignore [
    ".dockerignore",
    "Dockerfile",
    ".git",
    ".hg",
    ".svn",
    "_build",
    "deps",
    "erl_crash.dump"
  ]
  @phoenix_dockerignore [
    "priv/static"
  ]
  @brunch_dockerignore [
    "npm-debug.log",
    "node_modules"
  ]

  def execute(opts) do
    os_image = Keyword.get(opts, :os_image, System.get_env("DEFAULT_OS_IMAGE"))
    asdf_image = Keyword.get(opts, :asdf_image, System.get_env("DEFAULT_ASDF_IMAGE"))
    builder_image = Keyword.get(opts, :builder_image, System.get_env("DEFAULT_BUILDER_IMAGE"))

    default_erlang_version =
      Keyword.get(opts, :default_erlang_version, System.get_env("DEFAULT_ERLANG_VERSION"))

    default_elixir_version =
      Keyword.get(opts, :default_elixir_version, System.get_env("DEFAULT_ELIXIR_VERSION"))

    prebuilt_erlang_images =
      Keyword.get_values(opts, :prebuilt_erlang_images) ++
        case System.get_env("DEFAULT_PREBUILT_ERLANG_IMAGES") do
          nil -> []
          str -> String.split(str, ",")
        end

    workspace_dir = Keyword.get(opts, :workspace_dir, @default_workspace_dir) |> Path.expand()

    template_dir =
      Keyword.get(opts, :template_dir, @default_template_dir)
      |> Path.expand()

    File.cd!(workspace_dir, fn ->
      start_app_config(workspace_dir, default_erlang_version, default_elixir_version)

      assigns =
        build_assigns(
          prebuilt_erlang_images,
          os_image,
          asdf_image,
          builder_image
        )

      write_dockerfile(workspace_dir, template_dir, assigns)
      desired_dockerignore_entries = determine_desired_dockerignore_entries()
      write_dockerignore(workspace_dir, desired_dockerignore_entries)
    end)

    :ok
  end

  defp start_app_config(_workspace_dir, "", _default_elixir_version) do
    GenerateDockerfile.error("Missing default erlang version")
  end

  defp start_app_config(_workspace_dir, _default_erlang_version, "") do
    GenerateDockerfile.error("Missing default elixir version")
  end

  defp start_app_config(workspace_dir, default_erlang_version, default_elixir_version) do
    {:ok, _} =
      AppConfig.start_link(
        workspace_dir: workspace_dir,
        default_erlang_version: default_erlang_version,
        default_elixir_version: default_elixir_version
      )

    case AppConfig.status() do
      {:error, msg} -> GenerateDockerfile.error(msg)
      :ok -> nil
    end
  end

  defp build_assigns(
         prebuilt_erlang_images,
         os_image,
         asdf_image,
         builder_image
       ) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    packages = AppConfig.get!(:install_packages) |> Enum.join(" ")
    erlang_version = AppConfig.get!(:erlang_version)
    elixir_version = AppConfig.get!(:elixir_version)

    prebuilt_erlang_image =
      Enum.find_value(prebuilt_erlang_images, fn str ->
        case String.split(str, "=", parts: 2) do
          [^erlang_version, image] -> image
          _ -> nil
        end
      end)

    [
      os_image: os_image,
      asdf_image: asdf_image,
      builder_image: builder_image,
      timestamp: timestamp,
      erlang_version: erlang_version,
      elixir_version: elixir_version,
      prebuilt_erlang_image: prebuilt_erlang_image,
      app_yaml_path: AppConfig.get!(:app_yaml_path),
      project_id: AppConfig.get!(:project_id),
      project_id_for_display: AppConfig.get!(:project_id_for_display),
      project_id_for_example: AppConfig.get!(:project_id_for_example),
      service_name: AppConfig.get!(:service_name),
      release_app: AppConfig.get!(:release_app),
      builder_packages: packages,
      runtime_packages: packages,
      env_variables: AppConfig.get!(:env_variables) |> render_env,
      mix_env: AppConfig.get!(:mix_env),
      cloud_sql_instances: AppConfig.get!(:cloud_sql_instances) |> Enum.join(","),
      build_scripts: AppConfig.get!(:build_scripts) |> render_commands,
      entrypoint: AppConfig.get!(:entrypoint)
    ]
  end

  defp write_dockerfile(workspace_dir, template_dir, assigns) do
    template_name =
      if AppConfig.get!(:release_app) == nil do
        "Dockerfile-simple.eex"
      else
        "Dockerfile-release.eex"
      end

    template_path = Path.join(template_dir, template_name)
    dockerfile = EEx.eval_file(template_path, [assigns: assigns], trim: true)
    write_path = Path.join(workspace_dir, "Dockerfile")

    if File.exists?(write_path) do
      GenerateDockerfile.error("Unable to generate Dockerfile because one already exists.")
    end

    File.write!(write_path, dockerfile)
    Logger.info("Generated Dockerfile.")
  end

  defp escape_quoted(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
  end

  defp render_env(map) do
    map
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn key ->
      value = Map.fetch!(map, key)
      "#{key}=\"#{escape_quoted(value)}\""
    end)
    |> Enum.join(" \\\n    ")
  end

  defp render_commands(cmds) do
    cmds
    |> Enum.map(fn cmd -> "RUN #{cmd}" end)
    |> Enum.join("\n")
  end

  defp determine_desired_dockerignore_entries() do
    brunch_dir = AppConfig.get!(:brunch_dir)

    brunch_entries =
      case brunch_dir do
        nil -> []
        "." -> @brunch_dockerignore
        brunch_dir -> Enum.map(@brunch_dockerignore, &Path.join(brunch_dir, &1))
      end

    phoenix_entries = if brunch_dir == nil, do: [], else: @phoenix_dockerignore
    [AppConfig.get!(:app_yaml_path) | @common_dockerignore] ++ brunch_entries ++ phoenix_entries
  end

  defp write_dockerignore(workspace_dir, desired_entries) do
    write_path = Path.join(workspace_dir, ".dockerignore")

    existing_entries =
      if File.exists?(write_path) do
        write_path
        |> File.read!()
        |> String.split("\n", trim: true)
      else
        []
      end

    File.open!(write_path, [:append], fn io ->
      Enum.each(desired_entries -- existing_entries, fn entry ->
        IO.puts(io, entry)
      end)
    end)

    if length(existing_entries) == 0 do
      Logger.info("Generated .dockerignore file.")
    else
      Logger.info("Updated .dockerignore file.")
    end
  end
end
