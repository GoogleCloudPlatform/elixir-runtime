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

defmodule Mix.Tasks.BuildLocalImages do
  @moduledoc """
  Mix task that builds images locally.
  """

  @shortdoc "Build images locally."

  @prebuilt_erlang_image_base "elixir-prebuilt-erlang-"
  @prebuilt_erlang_versions ["20.1"]
  @base_erlang_version "20.1"
  @base_elixir_version "1.5.2-otp-20"

  use Mix.Task

  def run(_args) do
    File.cd!("elixir-debian", fn ->
      {_, 0} = System.cmd("docker",
        ["build", "--no-cache", "--pull", "-t", "elixir-debian", "."],
        into: IO.stream(:stdio, :line))
    end)
    File.cd!("elixir-asdf", fn ->
      {_, 0} = System.cmd("docker",
        ["build", "--no-cache", "-t", "elixir-asdf", "."],
        into: IO.stream(:stdio, :line))
    end)
    File.cd!("elixir-prebuilt-erlang", fn ->
      Enum.each(@prebuilt_erlang_versions, fn version ->
        {_, 0} = System.cmd("docker",
          ["build", "--no-cache", "-t", "#{@prebuilt_erlang_image_base}#{version}",
            "--build-arg", "erlang_version=#{version}", "."],
          into: IO.stream(:stdio, :line))
      end)
    end)
    File.cd!("elixir-base", fn ->
      {dockerfile, 0} = System.cmd("sed",
        ["-e", "s|$PREBUILT_ERLANG_IMAGE|#{@prebuilt_erlang_image_base}#{@base_erlang_version}|g",
         "Dockerfile-prebuilt.in"])
      :ok = File.write!("Dockerfile", dockerfile)
      {_, 0} = System.cmd("docker",
        ["build", "--no-cache", "-t", "elixir-base",
          "--build-arg", "erlang_version=#{@base_erlang_version}",
          "--build-arg", "elixir_version=#{@base_elixir_version}",
          "."],
        into: IO.stream(:stdio, :line))
    end)
    File.cd!("elixir-builder", fn ->
      {_, 0} = System.cmd("docker",
        ["build", "--no-cache", "-t", "elixir-builder", "."],
        into: IO.stream(:stdio, :line))
    end)
    File.cd!("elixir-generate-dockerfile", fn ->
      prebuilt_erlang_versions_str = Enum.join(@prebuilt_erlang_versions, ",")
      {_, 0} = System.cmd("docker",
        ["build", "--no-cache", "-t", "elixir-generate-dockerfile",
          "--build-arg", "debian_image=elixir-debian",
          "--build-arg", "asdf_image=elixir-asdf",
          "--build-arg", "builder_image=elixir-builder",
          "--build-arg", "prebuilt_erlang_image_base=#{@prebuilt_erlang_image_base}",
          "--build-arg", "prebuilt_erlang_image_tag=latest",
          "--build-arg", "prebuilt_erlang_versions=#{prebuilt_erlang_versions_str}",
          "--build-arg", "default_erlang_version=#{@base_erlang_version}",
          "--build-arg", "default_elixir_version=#{@base_elixir_version}",
          "."],
        into: IO.stream(:stdio, :line))
    end)
  end
end
