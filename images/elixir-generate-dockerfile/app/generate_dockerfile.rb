#!/rbenv/shims/ruby

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

require "erb"
require "optparse"

require_relative "app_config.rb"

class GenerateDockerfile
  DEFAULT_WORKSPACE_DIR = "/workspace"
  DEFAULT_BASE_IMAGE = "gcr.io/google-appengine/elixir"
  DEFAULT_BUILD_TOOLS_IMAGE = "gcr.io/gcp-runtimes/elixir/build-tools"
  GENERATOR_DIR = ::File.absolute_path(::File.dirname __FILE__)
  DOCKERIGNORE_PATHS = [
    ".dockerignore",
    ".git",
    ".hg",
    ".svn",
    "Dockerfile",
    "_build/",
    "deps/",
    "node_modules/",
    "priv/static/",
    "test/"
  ]

  def initialize args
    @workspace_dir = DEFAULT_WORKSPACE_DIR
    @base_image = DEFAULT_BASE_IMAGE
    @build_tools_image = DEFAULT_BUILD_TOOLS_IMAGE
    @testing = false
    ::OptionParser.new do |opts|
      opts.on "-t" do
        @testing = true
      end
      opts.on "--workspace-dir=PATH" do |path|
        @workspace_dir = ::File.absolute_path path
      end
      opts.on "--base-image=IMAGE" do |image|
        @base_image = image
      end
      opts.on "--build-tools-image=IMAGE" do |image|
        @build_tools_image = image
      end
    end.parse! args
    ::Dir.chdir @workspace_dir
    begin
      @app_config = AppConfig.new @workspace_dir
    rescue AppConfig::Error => ex
      ::STDERR.puts ex.message
      exit 1
    end
    @timestamp = ::Time.now.utc.strftime "%Y-%m-%d %H:%M:%S UTC"
  end

  def main
    write_dockerfile
    write_dockerignore
    if @testing
      system "chmod -R a+w #{@app_config.workspace_dir}"
    end
  end

  def write_dockerfile
    b = binding
    write_path = "#{@app_config.workspace_dir}/Dockerfile"
    if ::File.exist? write_path
      ::STDERR.puts "Unable to generate Dockerfile because one already exists."
      exit 1
    end
    template = ::File.read "#{GENERATOR_DIR}/Dockerfile.erb"
    content = ::ERB.new(template, nil, "<>").result(b)
    ::File.open write_path, "w" do |file|
      file.write content
    end
    puts "Generated Dockerfile"
  end

  def write_dockerignore
    write_path = "#{@app_config.workspace_dir}/.dockerignore"
    if ::File.exist? write_path
      existing_entries = ::IO.readlines write_path
    else
      existing_entries = []
    end
    desired_entries = DOCKERIGNORE_PATHS + [@app_config.app_yaml_path]
    ::File.open write_path, "a" do |file|
      (desired_entries - existing_entries).each do |entry|
        file.puts entry
      end
    end
    if existing_entries.empty?
      puts "Generated .dockerignore"
    else
      puts "Updated .dockerignore"
    end
  end

  def escape_quoted str
    str.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
  end

  def render_env hash
    hash.map{ |k,v| "#{k}=\"#{escape_quoted v}\"" }.join(" \\\n    ")
  end
end

GenerateDockerfile.new(::ARGV).main
