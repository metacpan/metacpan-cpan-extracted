use inc::Module::Install '1.06';

name 'WWW-Getsy';
all_from 'lib/WWW/Getsy.pm';

requires 'Net::OAuth::Simple' => '1.5';
requires 'Moose' => '1.21';
requires 'MooseX::Declare' => '0.34';
requires 'MooseX::Types';
requires 'File::HomeDir';
requires 'JSON::XS';
requires 'MooseX::Getopt';
requires 'Data::Dumper';
requires 'MooseX::NonMoose';

# generate README file
if ($Module::Install::AUTHOR) {
  system('pod2text lib/WWW/Getsy.pm > README');
}

install_script 'bin/getsy';

auto_install;
auto_provides_class;
WriteAll;

