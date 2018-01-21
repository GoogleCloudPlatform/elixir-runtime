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

defmodule GenerateDockerfile.Mixfile do
  use Mix.Project

  def project do
    [
      app: :generate_dockerfile,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  def application do
    [
      applications: [
        :logger,
        :yaml_elixir
      ]
    ]
  end

  def escript do
    [
      main_module: GenerateDockerfile
    ]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 1.3"},
      {:poison, "~> 3.1"}
    ]
  end
end
