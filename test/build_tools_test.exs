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

defmodule BuildToolsTest do
  use ExUnit.Case
  import TestHelper

  test "Build tools image" do
    File.cd!("test/build_tools_data", fn ->
      build_docker_image(fn image ->
        docker_run = ["docker", "run", "--rm", image]
        assert_cmd_output(docker_run ++ ["node", "--version"],
          ~r{^v\d+\.\d+}, show: true)
        assert_cmd_output(docker_run ++ ["yarn", "--version"],
          ~r{^\d+\.\d+}, show: true)
        assert_cmd_output(docker_run ++ ["cloud_sql_proxy", "--version"],
          ~r{Cloud SQL Proxy}, show: true)
        assert_cmd_output(docker_run ++ ["gcloud", "--version"],
          ~r{Google Cloud SDK}, show: true)
        assert_cmd_succeeds(docker_run ++ ["access_cloud_sql", "--lenient"],
          show: true)
      end)
    end)
  end
end
