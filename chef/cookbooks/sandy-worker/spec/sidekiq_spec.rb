describe "sandy-worker::sidekiq" do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
  let(:ruby_version) { "2.1.1" }

  it 'installs runit' do
    expect(chef_run).to include_recipe('runit')
  end
  
  it 'installs ruby' do
    expect(chef_run).to include_recipe('chruby::system')
  end

  it 'creates the worker user' do
    expect(chef_run).to add_user('processing')
  end

  it 'installs bundler' do
    expect(chef_run).to install_gem_package('bundler').
      with( gem_binary: "/opt/rubies/#{ruby_version}/bin/gem")
  end

  it 'checks out the worker code' do
    expect(chef_run).to checkout_git('/home/processing/sandy-project').
      with( repo: 'git://github.com/gina-alaska/sandy-project',
            revision: 'master')
  end

  it 'runs bundle install in the correct directory' do
    expect(chef_run).to run_execute('bundle install').
      with( command: 'chruby-exec #{ruby_version} -- bundle install',
            cwd: '/home/processing/sandy-project/jobs')
  end

  it 'creates the sidekiq configuration' do
    expect(chef_run).to create_directory('/home/processing/sandy-project/jobs/config').
      with( owner: 'processing', group: 'processing', mode: 0755 )
    expect(chef_run).to create_template('/home/processing/sandy-project/jobs/config/sidekiq.yml').
      with( owner: 'processing', group: 'processing', mode: 0644,
            variables: { queues: { default: 1} })
  end

  it 'creates and starts the sidekiq service' do
    expect(chef_run).to create_runit_service('sidekiq').
      with( log: true, default_logger: true, options: {
        user: 'processing',
        rubyversion: ruby_version,
        workerdir: '/home/processing/sandy-project/jobs'
      })
  end



end
