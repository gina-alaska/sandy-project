#Unicorn configuration
default['unicorn'] = {
  preload_app: true,
  config_path: '/etc/unicorn/sandy.rb',
  listen:      '/www/sandy/tmp/sockets',
  pid:         '/www/sandy/tmp/pids/unicorn.pid',
  stdout_path: '/www/sandy/log/unicorn.stdout.log',
  stderr_path: '/www/sandy/log/unicorn.stderr.log',
  worker_timeout: 60,
  working_directory: '/www/sandy',
  before_fork: '
defined?(ActiveRecord::Base) and
   ActiveRecord::Base.connection.disconnect!

   old_pid = "#{server.config[:pid]}.oldbin"
   if old_pid != server.pid
     begin
       sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
       Process.kill(sig, File.read(old_pid).to_i)
     rescue Errno::ENOENT, Errno::ESRCH
     end
   end

sleep 1
  ',
  after_fork: '
defined?(ActiveRecord::Base) and
  ActiveRecord::Base.establish_connection
  '
}
