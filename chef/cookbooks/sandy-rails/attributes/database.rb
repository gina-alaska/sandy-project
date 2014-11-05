#Database configuration
override['postgresql']['enable_pgdg_yum'] = true
override['postgresql']['version'] = "9.3"
override['postgresql']['dir'] = '/var/lib/pgsql/9.3/data'
override['postgresql']['client']['packages'] = %w{postgresql93 postgresql93-devel}
override['postgresql']['server']['packages'] = %w{postgresql93-server}
override['postgresql']['server']['service_name'] = 'postgresql-9.3'
override['postgresql']['contrib']['packages'] = %w{postgresql93-contrib}


default['sandy']['database']['name'] = 'sandy-kitchen'
default['sandy']['database']['database'] = 'sandy-kitchen'
default['sandy']['database']['username'] = 'sandy'
default['sandy']['database']['password'] = nil
default['sandy']['database']['adapter'] = 'postgresql'
default['sandy']['database']['client_encoding'] = 'UTF8'
default['sandy']['database']['pool'] = 5
default['sandy']['database']['schema_search_path'] = 'sandy,public'
