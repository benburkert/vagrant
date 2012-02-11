require 'tempfile'

require 'vagrant/util/line_ending_helpers'
require 'vagrant/util/template_renderer'

module Vagrant
  module Guest
    class Gentoo < Linux
      # Make the TemplateRenderer top-level
      include Vagrant::Util
      include Vagrant::Util::LineEndingHelpers

      def configure_networks(networks)
        # Remove any previous host only network additions to the interface file
        vm.channel.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/conf.d/net > /tmp/vagrant-network-interfaces")
        vm.channel.sudo("cat /tmp/vagrant-network-interfaces > /etc/conf.d/net")

        # Configure each network interface
        networks.each do |network|
          entry = TemplateRenderer.render("guests/gentoo/network_#{network[:type]}",
                                          :options => network)

          # Convert to proper lineendings
          entry = dos_to_unix(entry)

          # Upload the entry to a temporary location
          temp = Tempfile.new("vagrant")
          temp.write(entry)
          temp.close

          vm.channel.upload(temp.path, "/tmp/vagrant-network-entry")

          # Configure the interface
          vm.channel.sudo("ln -fs /etc/init.d/net.lo /etc/init.d/net.eth#{network[:interface]}")
          vm.channel.sudo("/etc/init.d/net.eth#{network[:interface]} stop 2> /dev/null")
          vm.channel.sudo("cat /tmp/vagrant-network-entry >> /etc/conf.d/net")
          vm.channel.sudo("/etc/init.d/net.eth#{network[:interface]} start")
        end
      end
    end
  end
end
