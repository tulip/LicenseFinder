require_relative 'platform'

module LicenseFinder
  class GlobalConfiguration
    class << self

      attr_accessor(
          :decisions_file,
          :go_full_version,
          :gradle_command,
          :gradle_include_groups,
          :maven_include_groups,
          :maven_options,
          :pip_requirements_path,
          :rebar_command,
          :rebar_deps_dir,
          :mix_command,
          :mix_deps_dir,
          :save_file,
          :prepare,
          :prepare_no_fail,
          :format,
          :columns,
          :aggregate_paths,
          :recursive,
          :logger,
          :decisions_file_path
      )

      def configure(config)
        @primary_config = config

        project_path = Pathname(@primary_config.fetch(:project_path, Pathname.pwd)).expand_path
        saved_config_file =  project_path.join('config', 'license_finder.yml')
        @saved_config = saved_config_file.exist? ? YAML.safe_load(saved_config_file.read) : {}

        @decision_file = get(:decisions_file)
        @go_full_version = get(:go_full_version)
        @gradle_command = get(:gradle_command)
        @gradle_include_groups = get(:gradle_include_groups)
        @maven_include_groups = get(:maven_include_groups)
        @maven_options = get(:maven_options)
        @pip_requirements_path = get(:pip_requirements_path)
        @rebar_command = get(:rebar_command)
        @prepare_no_fail = get(:prepare_no_fail)
        @prepare = get(:prepare) || @prepare_no_fail
        @save_file = get(:save)
        @aggregate_paths = get(:aggregate_paths)
        @recursive = get(:recursive)
        @format = get(:format)
        @columns = get(:columns)
        @mix_command = get(:mix_command) || 'mix'
        @rebar_deps_dir = project_path.join(get(:rebar_deps_dir) || 'deps').expand_path
        @mix_deps_dir = project_path.join(get(:mix_deps_dir) || 'deps').expand_path
        @decisions_file_path = project_path.join(get(:decisions_file) || 'doc/dependency_decisions.yml').expand_path
        @logger = LicenseFinder::Logger.new get(:logger)
      end

      def get(key)
        @primary_config[key.to_sym] || @saved_config[key.to_sym]
      end
    end
  end

  class ProjectConfiguration
    attr_reader :project_path, :saved_config

    def initialize(project_path)
      @project_path = Pathname(project_path || Pathname.pwd).expand_path
    end

    def valid_project_path?
      return @project_path.exist? if @project_path
      true
    end
  end
end
