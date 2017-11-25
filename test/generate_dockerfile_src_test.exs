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
  import TestHelper

  test "Generate dockerfile" do
    File.cd!("elixir-generate-dockerfile/src", fn ->
      IO.puts("**** Preparing generate-dockerfile tests.")
      assert_cmd_succeeds(["mix", "deps.clean", "--all"], show: true)
      assert_cmd_succeeds(["mix", "clean"], show: true)
      File.rm_rf("mix.lock")
      assert_cmd_succeeds(["mix", "deps.get"], show: true)
      IO.puts("**** Running generate-dockerfile tests.")
      assert_cmd_succeeds(["mix", "test"], show: true, stream: true)
      IO.puts("**** Completed generate-dockerfile tests.")
    end)
  end
end
