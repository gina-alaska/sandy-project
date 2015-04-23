include_recipe 'rubies'

%w(bundle bundler ruby).each do |rb|
  link "/usr/bin/#{rb}" do
    to "/opt/rubies/ruby-2.2.0/bin/#{rb}"
  end
end
