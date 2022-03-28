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
