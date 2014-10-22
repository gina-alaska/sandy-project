default['sandy-worker']['ruby-version'] = '2.1.1'
default['sandy-worker']['user'] = 'processing'
default['sandy-worker']['worker-dir'] = '/jobs'
default['sandy-worker']['log-dir'] = '/var/log/sidekiq'
default['sandy-worker']['git-repo'] = 'git://github.com/gina-alaska/sandy-project'
default['sandy-worker']['git-revision'] = 'master'
default['sandy-worker']['queues']['default'] = 1


override['chruby']['rubies'] = {
  '2.1.1' => true,
  '1.9.3-p392' => false
}
