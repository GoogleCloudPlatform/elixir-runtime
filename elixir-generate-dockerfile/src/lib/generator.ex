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
  @default_debian_image "gcr.io/gcp-elixir/runtime/debian"
  @default_base_image "gcr.io/gcp-elixir/runtime/base"
  @default_builder_image "gcr.io/gcp-elixir/runtime/builder"
  @default_template_dir "../app"
  @common_dockerignore [
    ".dockerignore",
    "Dockerfile",
    ".git",
    ".hg",
    ".svn"
  ]

  def execute(opts) do
    workspace_dir = get_arg(opts, :workspace_dir, @default_workspace_dir)
    debian_image = get_arg(opts, :debian_image, @default_debian_image)
    base_image = get_arg(opts, :base_image, @default_base_image)
    builder_image = get_arg(opts, :builder_image, @default_builder_image)
    template_dir =
      Keyword.get(opts, :template_dir, @default_template_dir)
      |> Path.expand

    File.cd!(workspace_dir, fn ->
      start_app_config(workspace_dir)
      write_dockerfile(workspace_dir, template_dir, debian_image, base_image, builder_image)
      write_dockerignore(workspace_dir)
    end)

    :ok
  end

  defp get_arg(opts, arg, default) do
    value = Keyword.get(opts, arg, "")
    if value == "", do: default, else: value
  end

  defp start_app_config(workspace_dir) do
    {:ok, _} = AppConfig.start_link(workspace_dir: workspace_dir)
    case AppConfig.status() do
      {:error, msg} -> GenerateDockerfile.error(msg)
      :ok -> nil
    end
  end

  defp write_dockerfile(workspace_dir, template_dir, debian_image, base_image, builder_image) do
    timestamp = DateTime.utc_now |> DateTime.to_iso8601
    packages = AppConfig.get!(:install_packages) |> Enum.join(" ")
    release_app = AppConfig.get!(:release_app)
    assigns = [
      workspace_dir: workspace_dir,
      debian_image: debian_image,
      base_image: base_image,
      builder_image: builder_image,
      timestamp: timestamp,
      app_yaml_path: AppConfig.get!(:app_yaml_path),
      project_id: AppConfig.get!(:project_id),
      project_id_for_display: AppConfig.get!(:project_id_for_display),
      project_id_for_example: AppConfig.get!(:project_id_for_example),
      service_name: AppConfig.get!(:service_name),
      release_app: release_app,
      builder_packages: packages,
      runtime_packages: packages,
      env_variables: AppConfig.get!(:env_variables) |> render_env,
      cloud_sql_instances: AppConfig.get!(:cloud_sql_instances) |> Enum.join(","),
      build_scripts: AppConfig.get!(:build_scripts) |> render_commands,
      entrypoint: AppConfig.get!(:entrypoint)
    ]
    template_name =
      if release_app == nil do
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

  defp write_dockerignore(workspace_dir) do
    write_path = Path.join(workspace_dir, ".dockerignore")
    existing_entries = if File.exists?(write_path) do
      write_path
        |> File.read!
        |> String.split("\n", trim: true)
    else
      []
    end
    desired_entries = [ AppConfig.get!(:app_yaml_path) | @common_dockerignore]
    File.open!(write_path, [:append], fn (io) ->
      Enum.each(desired_entries -- existing_entries, fn (entry) ->
        IO.puts(io, entry)
      end)
    end)
    if length(existing_entries) == 0 do
      Logger.info("Generated .dockerignore")
    else
      Logger.info("Updated .dockerignore")
    end
  end
end
