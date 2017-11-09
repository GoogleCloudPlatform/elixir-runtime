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

defmodule GenerateDockerfileSrcTest do
  use ExUnit.Case

  test "Generate dockerfile" do
    File.cd!("elixir-generate-dockerfile/src", fn ->
      IO.puts("**** Preparing generate-dockerfile tests.")
      assert_command("mix", ["deps.clean", "--all"])
      assert_command("mix", ["clean"])
      File.rm_rf("mix.lock")
      assert_command("mix", ["deps.get"])
      IO.puts("**** Running generate-dockerfile tests.")
      assert_command("mix", ["test"])
      IO.puts("**** Completed generate-dockerfile tests.")
    end)
  end

  defp assert_command(cmd, args) do
    {_, status} = System.cmd(cmd, args, into: IO.stream(:stdio, :line))
    assert status == 0
  end
end
