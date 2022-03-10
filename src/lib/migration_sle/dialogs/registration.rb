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
    # The initial dialog for the Leap to SLES migration.
    class Registration < CWM::Dialog
      attr_reader :email, :reg_code

      # Constructor
      def initialize
        textdomain "migration_sle"

        @reg_code_widget = ::Registration::Widgets::RegistrationCode.new
        super
      end

      # @macro seeAbstractWidget
      def contents
        VBox(
          VStretch(),
          Heading(heading),
          VSpacing(2),
          HSquash(
              VBox(
                # TRANSLATORS: input field label
                MinWidth(35, InputField(Id(:email), _("&E-mail Address"), "")),
                VSpacing(2),
                MinWidth(35, reg_code_widget)
              )
            ),
          VSpacing(4),
          HBox(
            HSpacing(6),
            HStretch(),
            MinWidth(
              40,
              Label(Opt(:autoWrap),
                format(
                  # TRANSLATORS: description of the module, displayed directly in the dialog
                  _("This module can migrate the system from %{from_system}" \
                    " to %{to_system} online. See more details in the help text."),
                  from_system: current_system,
                  to_system:   target_system
                ))
            ),
            HStretch()
          )
        )
      end

      # Returns the user input result
      #
      # @return [Symbol] Dialog's result (:next or :abort)
      #
      # @macro seeDialog
      def run
        ret = super

        @reg_code = reg_code_widget.value
        @email = Yast::UI.QueryWidget(Id(:email), :Value)

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
        # hide the [Back] button, this is the very first dialog
        ""
      end

      # @macro seeDialog
      # rubocop:disable Layout/HeredocIndentation, Metrics/MethodLength
      def help
        # TRANSLATORS: help text for the main dialog of the online search feature
        text = _(<<-HELP
<h2>Online Migration to %{to_system}</h2>
<p>
  This YaST module can migrate your system to the %{to_system}
  (SLE) product. The migration is done online, in the currently
  running system.
</p>

<h3>The Advantages of the Enterprise Product</h3>
<p>
  The %{to_system} provides several advantages, the most important
  ones are:
  <ul>
    <li>Certified system</li>
    <li>Technical support (up to 24/7)</li>
    <li>Security updates</li>
    <li>Optional long term service support (LTSS)</li>
  </ul>
</p>

<h3>Obtaining a Subscription</h3>
<p>
  There are several ways how to buy a SLE product, it is also possible
  to buy a subscription online. See <i>%{web}</i> for more details.
</p>

<h3>Notes</h3>
<p>
  It is recommended to close all unused applications and to stop
  all server services before starting the migration.
</p>

<h3>Migration Process</h3>
<p>
  The migration has several steps:
  <ol>
    <li>Registering the openSUSE Leap product</li>
    <li>Adding the SLE repositories</li>
    <li>Installing the SLE packages</li>
  </ol>
</p>

<p>
  After the migration is finished the system should be manually restarted.
</p>

<h3>Input Fields</h3>
</p>
  Enter the registration code and E-mail address. If you want to use
  a local RMT registration server enter its URL instead of
  the registration code. Leave the E-mail address empty in that case.
</p>
        HELP
                )
        # rubocop:enable Layout/HeredocIndentation, Metrics/MethodLength

        format(text, to_system: target_system, web: "https://www.suse.com/support/")
      end

    private

      attr_reader :reg_code_widget

      def current_system
        Yast::OSRelease.ReleaseName
      end

      def target_system
        "SUSE Linux Enterprise"
      end

      def heading
        from_system = Yast::OSRelease.ReleaseInformation

        format(
          _("Migrate from %{from_system} to %{to_system}"),
          from_system: from_system,
          to_system:   target_system
        )
      end
    end
  end
end
