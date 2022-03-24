# Copyright (c) [2022] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"

require "migration/main_workflow"

Yast.import "Sequencer"
Yast.import "Report"
Yast.import "OSRelease"
Yast.import "Wizard"

require "migration/restarter"
require "migration/patches"
require "registration/helpers"
require "registration/registration"
require "registration/registration_ui"
require "registration/storage"

require "migration_sle/dialogs/registration"
require "migration_sle/repos_workflow"

module MigrationSle
  # The goal of this class is to provide main single entry point to start
  # the simplified SLE migration workflow.
  class MainWorkflow < ::Migration::MainWorkflow
    def run
      textdomain "migration_sle"

      begin
        Yast::Wizard.CreateDialog
        Yast::Sequencer.Run(workflow_aliases, WORKFLOW_SEQUENCE)
      ensure
        vendor_cleanup
        Yast::Wizard.CloseDialog
      end
    end

  private

    WORKFLOW_SEQUENCE = {
      "ws_start"                => "start",
      "start"                   => {
        start:                   "system_check",
        restart_after_update:    "registration",
        restart_after_migration: "migration_finish"
      },
      "system_check"            => {
        abort: :abort,
        next:  "online_update"
      },
      "online_update"           => {
        abort:   :abort,
        restart: "restart_after_update",
        next:    "registration"
      },
      "restart_after_update"    => {
        restart: :restart
      },
      "registration"            => {
        abort: :abort,
        next:  "create_pre_snapshot"
      },
      # copied from yast2-migration
      "create_pre_snapshot"     => {
        next: "create_backup"
      },
      "create_backup"           => {
        next: "repositories"
      },
      "repositories"            => {
        abort:    :abort,
        rollback: "rollback",
        next:     "license"
      },
      "license"                 => {
        abort: "rollback",
        next:  "proposals"
      },
      "proposals"               => {
        abort: "rollback",
        next:  "perform_migration"
      },
      "rollback"                => {
        abort: :abort,
        next:  :next
      },
      "perform_migration"       => {
        abort: :abort,
        next:  "restart_after_migration"
      },
      "restart_after_migration" => {
        restart: :restart
      },
      # NOTE: the steps after the YaST restart use the new code from
      # the updated (migrated) yast2-migration package!!
      "migration_finish"        => {
        abort: :abort,
        next:  "create_post_snapshot"
      },
      "create_post_snapshot"    => {
        next: "finish_dialog"
      },
      "finish_dialog"           => {
        abort: :abort,
        next:  :next
      }
    }.freeze

    # rubocop:disable Metrics/AbcSize
    def workflow_aliases
      {
        "start"                   => -> { start },
        "system_check"            => -> { system_check },
        "online_update"           => -> { online_update },
        "restart_after_update"    => -> { restart_yast(:restart_after_update) },
        "registration"            => -> { registration_step },
        # copied from yast2-migration
        "create_pre_snapshot"     => -> { create_pre_snapshot },
        "create_backup"           => -> { create_backup },
        "rollback"                => -> { rollback },
        "perform_migration"       => -> { perform_migration },
        "proposals"               => -> { proposals },
        "repositories"            => -> { repositories },
        "license"                 => -> { license },
        "restart_after_migration" => -> { restart_yast(:restart_after_migration) },
        # NOTE: the steps after the YaST restart use the new code from
        # the updated (migrated) yast2-migration package!!
        "migration_finish"        => -> { migration_finish },
        "create_post_snapshot"    => -> { create_post_snapshot },
        "finish_dialog"           => -> { finish_dialog }
      }
    end
    # rubocop:enable Metrics/AbcSize

    # check if the system is supported for migration (only openSUSE Leap is supported)
    # and that the installed base product can be correctly found by the package manager
    # @return [Symbol] worklow symbol, either :next or :abort
    def system_check
      if !opensuse_leap?
        # TRANSLATORS: Error message, this YaST module is designed only for openSUSE systems
        # the "%{target_system}" is replaced by the target system name, e.g.
        # "SUSE Linux Enterprise",
        # the "%{supported_system}" is replaced by the name of the supported system,
        # e.g. "openSUSE Leap"
        # the "%{current_system}" is replaced by current system name
        Yast::Report.Error(
          format(_("Migration to the %{target_system} product\n" \
                   "is supported only from the %{supported_system} system.\n\n"\
                   "The installed distribution: %{current_system}"),
            target_system:    MigrationSle::Dialogs::Registration::TARGET_SYSTEM,
            supported_system: "openSUSE Leap",
            current_system:   Yast::OSRelease.ReleaseInformation)
        )
        return :abort
      end

      Registration::SwMgmt.init
      if !Registration::SwMgmt.find_base_product
        Registration::Helpers.report_no_base_product
        return :abort
      end

      :next
    end

    # evaluate the starting point for the workflow, start from the beginning
    # or continue after restarting the YaST
    # return [Symbol] workflow symbol
    def start
      return :start unless Migration::Restarter.instance.restarted

      # reload the stored snapshot id (from the previous run)
      if Migration::Restarter.instance.data.is_a?(Hash)
        step = Migration::Restarter.instance.data[:step]
        return step if step
      end

      log.warn "No saved step found, starting from the beginning"
      :start
    end

    # schedule YaST restart
    # @param [String] step current step in the workflow
    # @return [Symbol] workflow symbol (always :restart)
    def restart_yast(step)
      # save the snapshot for later (after restart)
      Migration::Restarter.instance.restart_yast(step: step)
      :restart
    end

    def registration_step
      registration_dialog = MigrationSle::Dialogs::Registration.new

      ret = nil
      loop do
        ret = registration_dialog.run

        break if [:abort, :close].include?(ret)
        # already registered
        return :next if Registration::Registration.is_registered?

        reg_code = registration_dialog.reg_code
        # SMT/RMT URL entered
        if reg_code =~ /^https{0,1}:\/\//
          url = reg_code
          reg_code = ""
          log.info "Using registration URL: #{url}"
        end

        registration = Registration::Registration.new(url)
        registration_ui = Registration::RegistrationUI.new(registration)

        options = Registration::Storage::InstallationOptions.instance
        options.custom_url = url
        options.email = registration_dialog.email
        options.reg_code = reg_code

        success, _service = registration_ui.register_system_and_base_product

        break if success

        Registration::Helpers.reset_registration_status
      end

      ret
    end

    def repositories
      prepare_repos

      ReposWorkflow.new.main
    end

    def rollback
      Yast::Wizard.ClearContents
      super
    end

    # Running in an openSUSE Leap distribution?
    #
    # @return [Boolean] True if running in an openSUSE Leap distribution, false otherwise
    def opensuse_leap?
      os_id = Yast::OSRelease.id
      os_id.match?(/opensuse/i) && os_id.match?(/leap/i)
    end
  end
end
