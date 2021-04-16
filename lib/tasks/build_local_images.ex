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

  @os_name "ubuntu18"
  @prebuilt_erlang_versions ["22.3.4.17"]
  @base_erlang_version "22.3.4.17"
  @base_elixir_version "1.11.4-otp-22"
  @old_distillery_elixir_version "1.8.2-otp-22"
  @asdf_version "0.8.0"
  @nodejs_version "14.16.1"
  @gcloud_version "334.0.0"

  @prebuilt_erlang_image_prefix "elixir-prebuilt-erlang-"

  use Mix.Task

  def run(args) do
    {opts, _leftover} =
      OptionParser.parse!(
        args,
        strict: [
          prebuilt_images_tag: :string
        ],
        aliases: [i: :prebuilt_images_tag]
      )

    prebuilt_images_tag = Keyword.get(opts, :prebuilt_images_tag, nil)

    File.cd!("elixir-#{@os_name}", fn ->
      {_, 0} =
        System.cmd(
          "docker",
          ["build", "--no-cache", "--pull", "-t", "elixir-os", "."],
          into: IO.stream(:stdio, :line)
        )
    end)

    File.cd!("elixir-asdf", fn ->
      {_, 0} =
        System.cmd(
          "docker",
          [
            "build",
            "--no-cache",
            "-t",
            "elixir-asdf",
            "--build-arg",
            "asdf_version=#{@asdf_version}",
            "."
          ],
          into: IO.stream(:stdio, :line)
        )
    end)

    if prebuilt_images_tag == nil do
      File.cd!("elixir-prebuilt-erlang", fn ->
        Enum.each(@prebuilt_erlang_versions, fn version ->
          {_, 0} =
            System.cmd(
              "docker",
              [
                "build",
                "--no-cache",
                "-t",
                "#{@prebuilt_erlang_image_prefix}#{version}",
                "--build-arg",
                "erlang_version=#{version}",
                "."
              ],
              into: IO.stream(:stdio, :line)
            )
        end)
      end)
    else
      Enum.each(@prebuilt_erlang_versions, fn version ->
        image = "gcr.io/gcp-elixir/runtime/#{@os_name}/prebuilt/otp-#{version}"

        {_, 0} =
          System.cmd(
            "docker",
            ["pull", "#{image}:#{prebuilt_images_tag}"],
            into: IO.stream(:stdio, :line)
          )

        {_, 0} =
          System.cmd(
            "docker",
            [
              "tag",
              "#{image}:#{prebuilt_images_tag}",
              "#{@prebuilt_erlang_image_prefix}#{version}"
            ],
            into: IO.stream(:stdio, :line)
          )
      end)
    end

    File.cd!("elixir-base", fn ->
      {dockerfile, 0} =
        System.cmd("sed", [
          "-e",
          "s|@@PREBUILT_ERLANG_IMAGE@@|#{@prebuilt_erlang_image_prefix}#{@base_erlang_version}|g",
          "Dockerfile-prebuilt.in"
        ])

      :ok = File.write!("Dockerfile", dockerfile)

      {_, 0} =
        System.cmd(
          "docker",
          [
            "build",
            "--no-cache",
            "-t",
            "elixir-base",
            "--build-arg",
            "erlang_version=#{@base_erlang_version}",
            "--build-arg",
            "elixir_version=#{@base_elixir_version}",
            "."
          ],
          into: IO.stream(:stdio, :line)
        )
    end)

    File.cd!("elixir-builder", fn ->
      {_, 0} =
        System.cmd(
          "docker",
          [
            "build",
            "--no-cache",
            "-t",
            "elixir-builder",
            "--build-arg",
            "nodejs_version=#{@nodejs_version}",
            "--build-arg",
            "gcloud_version=#{@gcloud_version}",
            "."
          ],
          into: IO.stream(:stdio, :line)
        )
    end)

    File.cd!("elixir-generate-dockerfile", fn ->
      prebuilt_erlang_images_str =
        @prebuilt_erlang_versions
        |> Enum.map(fn version ->
          "#{version}=#{@prebuilt_erlang_image_prefix}#{version}"
        end)
        |> Enum.join(",")

      {_, 0} =
        System.cmd(
          "docker",
          [
            "build",
            "--no-cache",
            "-t",
            "elixir-generate-dockerfile",
            "--build-arg",
            "os_image=elixir-os",
            "--build-arg",
            "asdf_image=elixir-asdf",
            "--build-arg",
            "builder_image=elixir-builder",
            "--build-arg",
            "prebuilt_erlang_images=#{prebuilt_erlang_images_str}",
            "--build-arg",
            "default_erlang_version=#{@base_erlang_version}",
            "--build-arg",
            "default_elixir_version=#{@base_elixir_version}",
            "--build-arg",
            "old_distillery_elixir_version=#{@old_distillery_elixir_version}",
            "."
          ],
          into: IO.stream(:stdio, :line)
        )
    end)
  end
end
