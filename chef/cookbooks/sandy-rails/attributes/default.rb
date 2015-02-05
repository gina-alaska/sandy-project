default['unicorn_config_path'] = '/etc/unicorn'

default['sandy']['account'] = "webdev"
default['sandy']['environment'] = "production"
default['sandy']['packages'] = Mash.new
default['sandy']['ruby']['version'] = '2.1.1'
default['sandy']['ruby']['package'] = 'gina-ruby-21'
default['sandy']['git-repo'] = 'git://github.com/gina-alaska/sandy-rails'
default['sandy']['git-revision'] = 'master'
default['sandy']['git-action'] = 'checkout'

#Path configuration
default['sandy']['paths'] = {
  application:   '/www/sandy',
  config:        '/www/sandy/config',
  initializers:  '/www/sandy/config/initializers',
  public:        '/www/sandy/public',
}


#Rails configuration
default['sandy']['rails']['secret_key_base'] = 'b4b8fefeb6fc52226822bf3e293b250733b73d82388822a32d477a04ba4ce956dc251e656b3182ae8b21dbedce3c7d406488d12d2f4d4eaf4db40e115de3c675'
default['sandy']['rails']['application_class_name'] = ''
default['sandy']['rails']['shared_dirs'] = %w{tmp public config config/initializers}
default['sandy']['rails']['symlinks'] = {
  "config/database.yml" => "config/database.yml",
  "config/initializers/sidekiq.rb" => "config/initializers/sidekiq.rb"
}
# default['sandy']['rails']['google_key'] = ""
# default['sandy']['rails']['google_secret'] = ""
# default['sandy']['rails']['github_key'] = ""
# default['sandy']['rails']['github_secret'] = ""


override['chruby']['default'] = 'embedded'

default['sandy']['secrets']['scratch_path'] = "/tmp/scratch"
default['sandy']['secrets']['shared_path'] = "/tmp/shared"

default['sandy']['worker']['user']
default['sandy']['worker']['scripts-path'] = '/opt/processing-scripts'
default['sandy']['worker-log-dir'] = '/var/log/sidekiq'
default['sandy']['worker']['scripts-git-repo'] = 'git://github.com/gina-alaska/sandy-utils'
default['sandy']['worker']['scripts-git-revision'] = 'master'
default['sandy']['worker']['scripts-git-action'] = 'checkout'
default['sandy']['worker']['queues']['default'] = 1

default['sandy']['database']['hostname'] = "localhost"

default['sandy']['redis']['url'] = 'redis://localhost:6379'
default['sandy']['redis']['namespace'] = 'sandy'