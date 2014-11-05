# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.5.0"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname = "sandy-dev-berkshelf"
  config.omnibus.chef_version = :latest
  config.berkshelf.enabled = true

  #Shared folders
  sandy_root = File.expand_path(File.dirname(__FILE__), '..')
  sandy_opt_cspp = File.join(sandy_root,'cspp')
  config.vm.synced_folder sandy_root, "/home/vagrant/sandy-project"

  FileUtils.mkdir_p(sandy_opt_cspp) unless ::File.exists?(sandy_opt_cspp)
  config.vm.synced_folder sandy_opt_cspp, "/opt/cspp"

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to exclusively install and copy to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  config.vm.box = "opscode_centos-6.4_provisionerless"
  config.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/opscode_centos-6.4_provisionerless.box"

  config.vm.network :private_network, type: "dhcp"
  #Force ip4/6 requests to be made seperatly
  config.vm.provision :shell, inline: "if [ ! $(grep single-request-reopen /etc/sysconfig/network) ]; then echo RES_OPTIONS=single-request-reopen >> /etc/sysconfig/network && service network restart; fi"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    # vb.gui = true

    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  config.vm.provision :chef_solo do |chef|
    chef.roles_path = ["./roles"]
    chef.json = {
      postgresql: {
        password: {
          postgres: "s4nd1-d3v-D4taBa53"
        }
      },
      chruby: {
        default: 'embedded'
      },
      users: [
        'vagrant'
      ],
      rtstps: {
        user: 'vagrant',
        source: 'http://mirrors.gina.alaska.edu/SSEC/CSPP/RT-STPS_5.3.tar.gz'
      },
      cspp: {
        user: 'vagrant',
        "snpp-sdr" => {
          components: {
            app: {url: 'http://mirrors.gina.alaska.edu/SSEC/CSPP/CSPP_SDR_V2.0.tar.gz'},
            "static-terrain" => { url: 'http://mirrors.gina.alaska.edu/SSEC/CSPP/CSPP_SDR_V2.0_STATIC.tar.gz'},
            cache: {url: 'http://mirrors.gina.alaska.edu/SSEC/CSPP/CSPP_SDR_V2.0_CACHE.tar.gz'}
          }
        }
      }
    }

    chef.run_list = [
      # "role[sandy-dev-allinone]",
      "rtstps::default",
      "cspp::snpp_sdr"
    ]
  end
end
