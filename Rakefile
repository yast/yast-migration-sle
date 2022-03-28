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

require "yast/rake"

Yast::Tasks.configuration do |conf|
  conf.skip_license_check << /\.desktop$/
  conf.skip_license_check << /\.svg$/
  conf.skip_license_check << /test/

  # this package works only in openSUSE Leap, Tumbleweed or SLE is not supported
  conf.obs_api = "https://api.opensuse.org"
  conf.obs_target = "openSUSE_Leap_15.4"
  conf.obs_sr_project = "openSUSE:Leap:15.4"
  conf.obs_project = "YaST:openSUSE:15.4"
end
