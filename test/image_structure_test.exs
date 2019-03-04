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

defmodule ImageStructureTest do
  use ExUnit.Case
  import TestHelper

  structure_tests("elixir-ubuntu18/structure-test.json", "elixir-os")
  structure_tests("elixir-asdf/structure-test.json", "elixir-asdf")
  structure_tests("elixir-base/structure-test.json", "elixir-base")
  structure_tests("elixir-builder/structure-test.json", "elixir-builder")
end
