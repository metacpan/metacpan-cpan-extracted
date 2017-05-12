use inc::Module::Install;
  
# Define metadata
name           'WebService-CloudFlare-Host';
all_from       'lib/WebService/CloudFlare/Host.pm';
license        'bsd';

# Specific dependencies
requires       'Data::Dumper'   => 0;
requires       'Try::Tiny'      => 0;
requires       'Moose'          => 0;
requires       'LWP'            => 0;

WriteAll;
