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

require "json"
require "optparse"
require "psych"

class AppConfig
  DEFAULT_WORKSPACE_DIR = "/workspace"
  DEFAULT_APP_YAML_PATH = "./app.yaml"
  DEFAULT_SERVICE_NAME = "default"

  class Error < ::StandardError
  end

  attr_reader :workspace_dir
  attr_reader :app_yaml_path
  attr_reader :project_id
  attr_reader :service_name
  attr_reader :env_variables
  attr_reader :cloud_sql_instances
  attr_reader :build_scripts
  attr_reader :runtime_config
  attr_reader :raw_entrypoint
  attr_reader :entrypoint
  attr_reader :install_packages

  def initialize workspace_dir
    @workspace_dir = workspace_dir
    init_app_config  # Must be called first
    # init_framework_detection
    init_env_variables
    init_packages
    init_cloud_sql_instances
    init_entrypoint  # Must be called after init_framework_detection
    init_build_scripts  # Must be called after init_entrypoint
  end

  private

  def init_app_config
    @project_id = ::ENV["PROJECT_ID"] || "(unknown)"
    @app_yaml_path = ::ENV["GAE_APPLICATION_YAML_PATH"] || DEFAULT_APP_YAML_PATH
    config_file = "#{@workspace_dir}/#{@app_yaml_path}"
    begin
      @app_config = ::Psych.load_file config_file
    rescue
      raise AppConfig::Error,
        "Could not read app engine config file: #{config_file.inspect}"
    end
    @runtime_config = @app_config["runtime_config"] || {}
    @beta_settings = @app_config["beta_settings"] || {}
    @lifecycle = @app_config["lifecycle"] || {}
    @service_name = @app_config["service"] || DEFAULT_SERVICE_NAME
  end

  def init_env_variables
    @env_variables = @app_config["env_variables"] || {}
    @env_variables.each do |k, v|
      if k !~ %r{\A[a-zA-Z]\w*\z}
        raise AppConfig::Error,
          "Illegal environment variable name: #{k.inspect}"
      end
    end
  end

  def init_build_scripts
    raw_build_scripts = @lifecycle["build"] || @runtime_config["build"]
    @build_scripts = raw_build_scripts ?
        Array(raw_build_scripts) : default_build_scripts
    @build_scripts.each do |script|
      if script.include? "\n"
        raise AppConfig::Error,
          "Illegal newline in build command: #{script.inspect}"
      end
    end
  end

  def default_build_scripts
    []
  end

  def init_cloud_sql_instances
    @cloud_sql_instances = Array(@beta_settings["cloud_sql_instances"])
    @cloud_sql_instances.each do |name|
      if name !~ %r{\A[\w:.-]+\z}
        raise AppConfig::Error,
          "Illegal cloud sql instance name: #{name.inspect}"
      end
    end
  end

  def init_entrypoint
    @raw_entrypoint = @runtime_config["entrypoint"] || @app_config["entrypoint"]
    if !@raw_entrypoint
      raise AppConfig::Error, "Entrypoint not specified"
    end
    if @raw_entrypoint.include? "\n"
      raise AppConfig::Error,
        "Illegal newline in entrypoint: #{@raw_entrypoint.inspect}"
    end
    @entrypoint = decorate_entrypoint @raw_entrypoint
  end

  # Prepare entrypoint for rendering into the dockerfile.
  # If the provided entrypoint is an array, render it in exec format.
  # If the provided entrypoint is a string, we have to render it in shell
  # format. Now, we'd like to prepend "exec" so signals get caught properly.
  # However, there are some edge cases that we omit for safety.
  def decorate_entrypoint entrypoint
    return JSON.generate entrypoint if entrypoint.is_a? Array
    return entrypoint if entrypoint.start_with? "exec "
    return entrypoint if entrypoint =~ /;|&&|\|/
    "exec #{entrypoint}"
  end

  def init_packages
    @install_packages = Array(
      @runtime_config["packages"] || @app_config["packages"]
    )
    @install_packages.each do |pkg|
      if pkg !~ %r{\A[\w.-]+\z}
        raise AppConfig::Error, "Illegal debian package name: #{pkg.inspect}"
      end
    end
  end
end
