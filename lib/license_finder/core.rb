require 'forwardable'

require 'license_finder/logger'
require 'license_finder/license'

require 'license_finder/configuration'
require 'license_finder/package_manager'
require 'license_finder/decisions'
require 'license_finder/decisions_factory'
require 'license_finder/decision_applier'
require 'license_finder/scanner'

module LicenseFinder
  # Coordinates setup
  class Core
    attr_reader :project_config

    extend Forwardable
    def_delegators :decision_applier, :acknowledged, :unapproved, :blacklisted, :any_packages?

    def initialize(project_config)
      @project_config = project_config
      @scanner = Scanner.new(options)
    end

    def modifying
      yield
      decisions.save!(GlobalConfiguration.decisions_file_path)
    end


    def project_name
      decisions.project_name || project_config.project_path.basename.to_s
    end

    def project_path
      project_config.project_path
    end

    def decisions
      @decisions ||= DecisionsFactory.decisions
    end

    def prepare_projects
      logger = options[:logger]
      package_managers = @scanner.active_package_managers

      package_managers.each do |manager|
        logger.debug manager.class, 'Running prepare on project'
        manager.prepare
        logger.debug manager.class, 'Finished prepare on project', color: :green
      end
    end

    private

    # The core of the system. The saved decisions are applied to the current
    # packages.
    def decision_applier
      # lazy, do not move to `initialize`
      # Needs to be lazy loaded to prvent multiple decision appliers being created each time
      @applier ||= DecisionApplier.new(decisions: decisions, packages: current_packages)
    end

    def current_packages
      # lazy, do not move to `initialize`
      @scanner.active_packages
    end

    def options
      {
        logger: GlobalConfiguration.logger,
        project_path: project_config.project_path,
        ignored_groups: decisions.ignored_groups,
        go_full_version: GlobalConfiguration.go_full_version,
        gradle_command: GlobalConfiguration.gradle_command,
        gradle_include_groups: GlobalConfiguration.gradle_include_groups,
        maven_include_groups: GlobalConfiguration.maven_include_groups,
        maven_options: GlobalConfiguration.maven_options,
        pip_requirements_path: GlobalConfiguration.pip_requirements_path,
        rebar_command: GlobalConfiguration.rebar_command,
        rebar_deps_dir: GlobalConfiguration.rebar_deps_dir,
        mix_command: GlobalConfiguration.mix_command,
        mix_deps_dir: GlobalConfiguration.mix_deps_dir,
        prepare: GlobalConfiguration.prepare,
        prepare_no_fail: GlobalConfiguration.prepare_no_fail
      }
    end
  end
end
