# ------------------------------------------------------------------------------
# Copyright (c) 2022 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# ------------------------------------------------------------------------------
#

require "registration/ui/migration_repos_workflow"

module MigrationSle
  # The goal of this class is to provide main single entry point to start
  # the migration workflow.
  class ReposWorkflow < Registration::UI::MigrationReposWorkflow
    # the constructor
    def initialize
      super
      textdomain "migration_sle"
      Yast.import "Report"
    end

  private

    # select the SLES migration automatically, if there are multiple SLES
    # migrations let the user select one
    # @return [Symbol] workflow symbol (:next or :abort)
    def select_migration_products
      sles_migrations = find_sles_migrations
      case sles_migrations.size
      when 0
        # TRANSLATORS: error message
        Yast::Report.Error(_("No SUSE Linux Enterprise migration available.\n" \
                             "Maybe it is not available yet or your subscription\n" \
                             "is not allowed to migrate to SLE.\n\n" \
                             "Try it later or check your subscription."))
        :abort
      when 1
        self.selected_migration = sles_migrations.first
        log.info "Automatically selected migration: #{selected_migration}"
        :next
      else
        log.info "Multiple SLES migrations found, running the selection dialog..."
        super
      end
    end

    def find_sles_migrations
      # migrate to SLES with the same version as the current Leap
      version = Yast::OSRelease.ReleaseVersion

      migrations.select do |m|
        m.any? { |p| p.identifier == "SLES" && p.version == version }
      end
    end
  end
end
