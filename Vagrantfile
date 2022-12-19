# -*- mode: ruby -*-
# vi: set ft=ruby :


$move_certs_script = <<-'SCRIPT'
mkdir -p /etc/kubernetes/pki
mv /home/vagrant/ca.crt /etc/kubernetes/pki/ca.crt
chown root /etc/kubernetes/pki/ca.crt
chmod 644 /etc/kubernetes/pki/ca.crt
mv /home/vagrant/ca.key /etc/kubernetes/pki/ca.key
chown root /etc/kubernetes/pki/ca.key
chmod 600 /etc/kubernetes/pki/ca.key
SCRIPT

$discovery_ca_hash_cmd =
    'openssl x509 -pubkey -in pki/ca.crt' +
    ' | openssl rsa -pubin -outform der 2>/dev/null' +
    ' | openssl dgst -sha256 -hex' +
    ' | sed \'s/^.* //\''

$cp_ip = "192.168.57.3"
$cp_hostname = "azkaban-cp"
$podnet_cidr = "172.16.0.0/16"
$svcnet_cidr = "172.17.0.0/16"
$svcnet_dns_ip = "172.17.0.10"
$discovery_ca_hash = `#{$discovery_ca_hash_cmd}`
$bootstrap_token = "n8yeln.n3lh3i5i9xnz9m89"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  config.vm.define "cp", primary: true do |node|
    node.vm.box = "generic/ubuntu2004"

    hostname = "#{$cp_hostname}-01"

    node.vm.provider "libvirt" do |lv|
      lv.features = ['acpi',  'gic version=\'3\'']
      lv.driver = "qemu"
      lv.machine_type = "virt-6.0"
      lv.memory = "2048"
      lv.nvram = "/var/lib/libvirt/qemu/nvram/vagrant.fd"
      lv.loader = "/usr/share/edk2/aarch64/QEMU_EFI-silent-pflash.raw"
      lv.qemuargs :value => '-machine'
      lv.qemuargs :value => 'virt,accel=hvf,highmem=off'
      lv.inputs = []  # Force NO default PS/2 mouse
      lv.input :type => "tablet", :bus => "usb"
      lv.input :type => "keyboard", :bus => "usb"
      lv.usb_controller :model => "nec-xhci"
    end

    node.vm.hostname = hostname

    # node.vm.network "private_network", ip: $cp_ip, name: "vboxnet1"

    # node.vm.provision "shell", path: "install.sh", args: ["install_k8s"]
    # node.vm.provision "file", source: "pki/ca.crt", destination: "ca.crt"
    # node.vm.provision "file", source: "pki/ca.key", destination: "ca.key"
    # node.vm.provision "shell", inline: $move_certs_script
    # node.vm.provision "shell", path: "install.sh",
    #                   args: ["init_cp", $cp_ip, $cp_hostname, $cp_ip, hostname, $podnet_cidr, $svcnet_cidr, $svcnet_dns_ip, $bootstrap_token]
    # node.vm.provision "shell", inline: "cp -r /root/.kube /home/vagrant/.kube && chown vagrant -R /home/vagrant/.kube"
  end

  # (1..2).each do |i|
  #   config.vm.define "worker-#{i}" do |node|
  #     node.vm.box = "ubuntu/focal64"

  #     hostname = "azkaban-worker-%02d" % i
  #     node_ip = "192.168.57.%d" % (10 + i)

  #     node.vm.provider "virtualbox" do |vb|
  #       vb.memory = "1024"
  #       vb.name = "v-#{hostname}"
  #     end
  #     node.vm.hostname = hostname
  #     node.vm.network "private_network", ip: node_ip, name: "vboxnet1"

  #     node.vm.provision "shell", path: "install.sh", args: ["install_k8s"]
  #     node.vm.provision "shell", path: "install.sh",
  #                       args: ["join_worker", $cp_ip, $cp_hostname, node_ip, $bootstrap_token, $discovery_ca_hash]
  #   end
  # end

  config.vm.define "cp", primary: true do |node|

  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"


  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
