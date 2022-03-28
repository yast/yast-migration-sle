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

require "registration/ui/migration_repos_workflow"

module MigrationSle
  # The goal of this class is to provide main single entry point to start
  # the migration workflow.
  # It basically reuses the migration workflow from yast2-migration,
  # it just skips the migration selection dialog and automatically
  # selects a SLE migration when there is only one SLE migration possible.
  class ReposWorkflow < Registration::UI::MigrationReposWorkflow
    # the constructor
    def initialize
      super
      textdomain "migration_sle"
      Yast.import "Report"
    end

  private

    # select the SLE migration automatically, if there are multiple SLE
    # migrations let the user to select one
    # @return [Symbol] workflow symbol (:next or :abort)
    def select_migration_products
      sle_migrations = find_sle_migrations
      case sle_migrations.size
      when 0
        # TRANSLATORS: error message
        Yast::Report.Error(_("No SUSE Linux Enterprise migration available.\n" \
                             "Maybe it is not available yet or your subscription\n" \
                             "is not allowed to migrate to SLE.\n\n" \
                             "Try it later or check your subscription."))
        :abort
      when 1
        self.selected_migration = sle_migrations.first
        log.info "Automatically selected migration: #{selected_migration}"
        :next
      else
        log.info "Multiple SLE migrations found, running the selection dialog..."
        super
      end
    end

    # Select the SLE migrations from all possible migrations
    # @return [Array<OpenStruct>] SLE migrations
    def find_sle_migrations
      # migrate to SLE with the same version as the current Leap
      version = Yast::OSRelease.ReleaseVersion

      migrations.select do |m|
        m.any? { |p| p.identifier.start_with?("SLE") && p.version == version }
      end
    end
  end
end
