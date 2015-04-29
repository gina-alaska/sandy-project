#!/usr/bin/env ruby

require 'clamp'
require 'nokogiri'

Clamp do
  subcommand 'create-disk', "Create the disk for the VM"  do
    option ["-s", "--size"], "SIZE", "Size of VM disk", default: '20G'
    option ['-h', '--host'], "HOST", "VM Host to create vm on", required: true
    option ['-p', '--pool'], "PATH", "Name of pool to create image in", default: 'gluster-pool'

    parameter "NAME", "Name of VM", attribute_name: :name

    def execute
      puts "Executing: "

      system "ssh #{host} sudo virsh vol-create-as #{pool} #{name} #{size}"
      system "ssh #{host} sudo setfattr -n 'user.glusterfs.bd' -v 'lv:#{size}B' /var/lib/libvirt/images/#{pool}/#{name}"
    end

  end

  subcommand 'create', "Create a VM" do
    option ['-h', '--host'], "HOST", "Host to create VM on", required: true
    option ['-c', '--cpus'], "CPUS", "CPU count", default: 1 do |c|
      Integer(c)
    end
    option ['-m', '--memory'], "MEMORY", "Memory to give the VM in megabytes", default: 4096
    option ['-s', '--size'], "DISK SIZE", "Disk size for root volume", default: '20G'
    option ['--[no-]start'], :flag, "Start the vm", default: true

    parameter "NAME", 'Name of VM'

    def execute
      xml = Nokogiri::XML(File.open('template.xml'))

      xml.at_css('name').content = name
      xml.at_css('memory').content = memory * 1024
      xml.at_css('currentMemory').content = memory * 1024
      xml.at_css('vcpu').content = cpus
      xml.at_css('disk source')['name'] = "vm-pool/#{name}.img"

      File.open("#{name}.xml", "w") do |f|
        f << xml.to_xml
      end

      #Create the disk image
      #Copy the xml
      storage = "/var/lib/libvirt/images/gluster-pool"
      system "ssh #{host} sudo qemu-img create -f raw #{storage}/#{name}.img #{size}"
      system "ssh #{host} sudo setfattr -n 'user.glusterfs.bd' -v 'lv:#{size}B' #{storage}/#{name}.img"
      system "scp #{name}.xml #{host}:"
      system "ssh #{host} sudo virsh #{start? ? 'create' : 'define'} #{name}.xml"
    end

  end
end
