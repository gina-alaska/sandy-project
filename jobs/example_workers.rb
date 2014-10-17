require 'sidekiq'
require 'mixlib/shellout'
# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'x', :size => 1 }
end

# Sidekiq server is multi-threaded so our Redis connection pool size defaults to concurrency (-c)
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x' }
end

# Start up sidekiq via
# sidekiq -r ./example_worker.rb
# and then you can open up an IRB session like so:
# irb -r ./example_worker.rb
# where you can then say
# SleepWorker.perform_async
# LsWorker.perform_async '~/'
# 1.upto(5).each{|i| DbWorker.perform_async(i)}

class SleepWorker
  include Sidekiq::Worker

  def perform(duration = 5)
    sleep duration
    puts "Slept for #{duration} seconds"
  end
end

class LsWorker
  include Sidekiq::Worker

  def perform(directory)
    command = Mixlib::ShellOut.new("ls -al", cwd: directory)

    command.run_command
    command.error!

    puts command.stdout
  end
end

class DbWorker
  include Sidekiq::Worker

  def perform(id)
    s = ExampleModel.find(id)

    puts "Doing work on #{s.string}"
    sleep 3
    puts "Finished work on #{s.string}"
  end
end

class ExampleModel
  attr_accessor :string
  DB = {
    1 => {
      string: 'one'
    },
    2 => {
      string: 'two'
    },
    3 => {
      string: 'four'
    }
  }

  def initialize id
    instance = DB[id]
    raise "Instance not found" if instance.nil?
    @string = instance[:string]
  end

  def self.find(id)
    new(id)
  end
end
