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

require "cwm/dialog"
require "registration/widgets/registration_code"

Yast.import "OSRelease"

module MigrationSle
  module Dialogs
    # Dialog to search for packages
    #
    # This dialog embeds a {Registration::Widgets::PackageSearch} returning
    # the list of selected packages.
    class Registration < CWM::Dialog
      # Constructor
      def initialize
        textdomain "migration_sle"
        super
      end


      # @macro seeAbstractWidget
      def contents
        VBox(
          Heading(heading),
          VSpacing(2),
          HSquash(
            MinWidth(
              35,
              ::Registration::Widgets::RegistrationCode.new
            )
          )
        )
      end

      # Returns the list of selected packages
      #
      # @return [Symbol] Dialog's result (:next or :abort)
      #   packages. If the user aborted the dialog, it returns an empty array.
      #
      # @macro seeAbstractWidget
      def run
        ret = super
        # @selected_packages = ret == :next ? controller.selected_packages : []
        ret
      end

      # @macro seeDialog
      def abort_button
        Yast::Label.CancelButton
      end

      def next_button
        # TRANSLATORS: push button label
        _("&Migrate")
      end

      # @macro seeDialog
      def back_button
        ""
      end

      # @macro seeDialog
      def help
        # TRANSLATORS: help text for the main dialog of the online search feature
        _("<p><b>Online Migration to SLES</b></p>\n" \
          "<p></p>\n" \
          "<p></p>\n")
      end

    private

      def heading
        from_system = Yast::OSRelease.ReleaseInformation
        version_major, version_minor = Yast::OSRelease.ReleaseVersion.split(".", 2)
        to_system = "SUSE Linux Enterprise Server #{version_major}"

        if version_minor.to_i > 0
          to_system << " SP" << version_minor
        end

        _("Migrate from %{from_system} to %{to_system}") % {
          from_system: from_system,
          to_system: to_system
        }
      end
    end
  end
end
