#!/usr/bin/env ruby

require 'libvirt'
require 'securerandom'
require 'nokogiri'
require 'clamp'

Clamp do
  subcommand 'pool', "Manage Storage Pools" do
    subcommand 'list', 'List available storage pools' do

      def execute
        connection = Libvirt::open('qemu+ssh://root@kog7.gina.alaska.edu/system?socket=/var/run/libvirt/libvirt-sock')

        connection.list_all_storage_pools.each do |pool|
          puts pool.name
        end

      end
    end
  end
  subcommand 'volume', 'Manage Storage Volumes' do
    subcommand 'list', 'List storage volumes' do
      option ['-p','--pool'], "P", 'Limit to named pool'

      def execute
        connection = Libvirt::open('qemu+ssh://root@kog7.gina.alaska.edu/system?socket=/var/run/libvirt/libvirt-sock')
        connection.list_all_storage_pools.each do |pool|
          puts pool.name
          puts "----------------"
          if pool.active?
            pool.list_volumes.each do |vol|
              volInfo = pool.lookup_volume_by_name(vol)
              puts "#{vol} - #{volInfo.info.capacity} - #{volInfo.info.allocation}"
            end
          else
            puts "Volume inactive"
          end
          puts "----------------\n\n"
        end
      end
    end
  end
  subcommand 'domain', 'Manage Domains (VMs)' do
    subcommand 'list', 'List domains' do
      option ['-h', '--host'], 'H', 'Only list domains on this host'#,default: VMCluster.hosts

      def execute
        connection = Libvirt::open('qemu+ssh://root@kog7.gina.alaska.edu/system?socket=/var/run/libvirt/libvirt-sock')

        connection.list_all_domains.each do |dom|
          puts "#{dom.name} -- #{dom.active? ? 'Running' : 'Halted'}"
        end
      end
    end
    subcommand 'create', 'Create Domain' do
      option ['-h', '--host'], 'H', 'Create domain on this host', required: true
      option ['-n', '--name'], 'N', 'Name of domain', required: true
      option ['-m', '--memory'], 'M', 'Amount of memory to give domain, in MB', default: 2048
      option ['-c', '--cpu'], 'C', 'Number of CPUs to give domain', default: 2
      option ['-d', '--disk'], 'D', 'Disk to use (pool/name)', multiple: true
      option ['-f', '--format'], 'F', 'Image format', default: 'raw'
      option ['-t', '--template'], 'T', 'Image template to use'

      def execute
        connection = Libvirt::open('qemu+ssh://root@kog7.gina.alaska.edu/system?socket=/var/run/libvirt/libvirt-sock')
        if connection.list_all_domains.map(&:name).include?(@name)
          abort("Domain #{@name} already exists")
        end
        conn = Smog.connect(@host)
        conn = Smog::Cluster.connect(cname)
        conn.create_domain(name, memory, cpu, disks)
        conn.list_domains(false) #only show running
        conn.list_pools
        conn.list_volumes
        conn.create_domain
        conn.create_volume
        conn.create_volume_from_template


        Smog::Domain.create(host, info) #returns domain
        domain.migrate_to(host)
        comain.add_volume
          #Creates disks on hosts if they don't exist/
          #

      end
    end

    subcommand 'connect', 'Open VNC to Domain' do
      def execute
        # connection = Libvirt::open('qemu+ssh://root@kog7.gina.alaska.edu/system?socket=/var/run/libvirt/libvirt-sock')

      end
    end

  end
end

# connection = Libvirt::open('qemu+ssh://root@kog7.gina.alaska.edu/system?socket=/var/run/libvirt/libvirt-sock')
#
# # Parse storage-pool xml template && create pool unless exists
# pool_list = connection.list_all_storage_pools.map(&:name)
#
# pool = if pool_list.include?('vm')
#   connection.lookup_storage_pool_by_name('vm')
# else
#   pool_xml = File.read('templates/pool.xml') % {
#     name: 'vm',
#     host: 'pod-wrrb2.x.gina.alaska.edu',
#     path: '/vm'
#   }
#   connection.define_storage_pool_xml(pool_xml)
# end
# pool.build unless pool.active?
# pool.create unless pool.active?
#
# # Parse storage xml template && create volume(from template?) unless exists?
# unless pool.list_volumes.include?('demo.img')
#   volume_xml = File.read('templates/volume.xml') % {
#     name: 'demo.img',
#     size: 20 * 1024 * 1024,
#     allocation: 0,
#     pool: pool.name,
#     format: 'raw'
#   }
#   pool.create_volume_xml(volume_xml)
# end
#
# # Parse domain xml template && create domain unless exists
# domain_list = connection.list_all_domains.map(&:name)
#
# dom = if domain_list.include?('demo')
#   connection.lookup_domain_by_name('demo')
# else
#   domain_xml = File.read("templates/domain.xml") % {
#     name: 'demo',
#     uuid: SecureRandom.uuid,
#     memory: 8192 * 1024,
#     cpu: 2,
#     gluster_host: 'pod-wrrb3.x.gina.alaska.edu',
#     pool: 'vm',
#     bridge: 'br0'
#   }
#   connection.define_domain_xml(domain_xml)
# end
#
# dom.create unless dom.active?
#
# dom_xml = Nokogiri::XML(dom.xml_desc)
# port = (dom_xml/'graphics').first[:port]
# websocket = (dom_xml/'graphics').first[:websocket]
