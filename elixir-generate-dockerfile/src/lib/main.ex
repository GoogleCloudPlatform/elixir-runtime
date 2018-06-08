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

defmodule GenerateDockerfile do
  require Logger

  def main(args) do
    {opts, leftover, unknown} =
      OptionParser.parse(
        args,
        switches: [
          workspace_dir: :string,
          os_image: :string,
          asdf_image: :string,
          builder_image: :string,
          prebuilt_erlang_images: :keep,
          default_erlang_version: :string,
          default_elixir_version: :string,
          template_dir: :string
        ],
        aliases: [p: :prebuilt_erlang_images]
      )

    if length(leftover) > 0 do
      error("Unprocessed args: #{inspect(leftover)}")
    end

    if length(unknown) > 0 do
      error("Unrecognized switches: #{inspect(unknown)}")
    end

    GenerateDockerfile.Generator.execute(opts)
    Logger.flush()
  end

  def error(msg) do
    Logger.error(msg)
    Logger.flush()
    System.halt(1)
  end
end
