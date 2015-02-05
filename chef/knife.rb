log_level                :info
log_location             STDOUT
node_name                'scott'
client_key               "#{ENV['HOME']}/.chef/sandy-#{ENV['USER']}.pem"
validation_client_name   'chef-validator'
validation_key           "#{ENV['HOME']}/.chef/sandy-chef-validator.pem"
chef_server_url          'https://10.19.16.159'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )

cookbook_path ["cookbooks"]

cookbook_copyright "UAF-GINA"
cookbook_license "apachev2"
cookbook_email "support+chef@gina.alaska.edu"

knife[:editor]  = ENV['EDITOR'] || 'vim'
