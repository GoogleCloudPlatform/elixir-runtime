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

defmodule BaseStructureTest do
  use ExUnit.Case
  import TestHelper
  require Poison.Parser

  @config_file "elixir-base/structure-test.json"

  @config_file
  |> File.read!()
  |> Poison.Parser.parse!()
  |> Map.fetch!("commandTests")
  |> Enum.each(fn test_definition ->
    @test_name test_definition["name"]
    @test_command test_definition["command"]
    @test_expectations test_definition["expectedOutput"]
    test(@test_name) do
      [binary | args] = @test_command
      output = assert_cmd_succeeds(
        ["docker", "run", "--rm", "--entrypoint=#{binary}", "elixir-base" | args])
      Enum.each(@test_expectations, fn expectation ->
        regex = Regex.compile!(expectation)
        assert Regex.match?(regex, output)
      end)
    end
  end)
end
