default['dhcp']['allows'] = ['bootp', 'booting', 'unknown-clients']

default['dhcp']['options']['domain-name'] = '"sandy"'
default['dhcp']['options']['domain-name-servers'] = '8.8.8.8'
default['dhcp']['options']['domain-search'] = '"sandy"'

default['dhcp']['parameters']['default-lease-time'] = "6400"
default['dhcp']['parameters']['max-lease-time'] = "86400"
