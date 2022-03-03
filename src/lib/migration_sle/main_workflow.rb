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
require "registration/registration"

require "migration_sle/dialogs/registration"

module MigrationSle
  # The goal of this class is to provide main single entry point to start
  # the migration workflow.
  class MainWorkflow < ::Migration::MainWorkflow
    def run
      # Yast::Debugger.start
      textdomain "migration_sle"

      begin
        Yast::Wizard.CreateDialog
        Yast::Sequencer.Run(aliases, WORKFLOW_SEQUENCE)
      ensure
        vendor_cleanup
        Yast::Wizard.CloseDialog
      end
    end

  private

    WORKFLOW_SEQUENCE = {
      "ws_start"             => "start",
      "start"                   => {
        start:                   "system_check",
        restart_after_update:    "registration"
        # restart_after_migration: "migration_finish"
      },
      "system_check"         => {
        abort:                   :abort,
        next:                    "online_update",
      },
      "online_update"        => {
        abort:   :abort,
        restart: "restart_after_update",
        next:    "registration"
      },
      "restart_after_update" => {
        restart: :restart
      },
      "registration"         => {
        abort: :abort,
        next:  "migration"
      },
      "migration"            => {
        abort: :abort,
        next:  :next
      }
    }.freeze

    def aliases
      {
        "start"                => -> { start },
        "system_check"         => -> { system_check },
        "online_update"        => -> { online_update },
        "restart_after_update" => -> { restart_yast(:restart_after_update) },
        "registration"         => -> { registration },
        "migration"            => -> { migration }
      }
    end

    def system_check
      return :next if opensuse_leap?

      # TRANSLATORS: Error message, this YaST module is designed only for openSUSE systems
      # %s is replaced by the product name from /etc/os-release file
      Yast::Report.Error(_("Migration to the SUSE Linux Enterprise Server product\n" \
                           "is supported only from the openSUSE Leap distribution.\n\n"\
                           "Installed distribution: %s") % Yast::OSRelease.ReleaseInformation)
      :abort
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

    def registration
      # already registered
      return :next if Registration::Registration.is_registered?
      # Yast::Debugger.start

      MigrationSle::Dialogs::Registration.run
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
