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

  @erlang_package_version "1:20.1-1"
  @elixir_package_version "1.5.2-1"

  use Mix.Task

  def run(_args) do
    File.cd!("elixir-base", fn ->
      {_, 0} = System.cmd("docker", ["build", "--no-cache", "--pull", "-t", "elixir-base",
          "--build-arg", "ERLANG_PACKAGE_VERSION=#{@erlang_package_version}",
          "--build-arg", "ELIXIR_PACKAGE_VERSION=#{@elixir_package_version}",
          "."], into: IO.stream(:stdio, :line))
    end)
    File.cd!("elixir-build-tools", fn ->
      {_, 0} = System.cmd("docker", ["build", "--no-cache", "-t", "elixir-build-tools",
          "."], into: IO.stream(:stdio, :line))
    end)
    File.cd!("elixir-generate-dockerfile", fn ->
      {_, 0} = System.cmd("docker", ["build", "--no-cache", "-t", "elixir-generate-dockerfile",
          "."], into: IO.stream(:stdio, :line))
    end)
  end
end
