use inc::Module::Install;

name     'dyatel';
all_from 'lib/Dyatel.pm';
author   q{Andrey Kostenko <andrey@kostenko.name>};
license  'perl';

build_requires 'Test::More';
requires 'Sys::Syslog';
requires 'Class::Accessor';
requires 'Data::Dumper';
requires 'Net::Twitter::Stream';
requires 'WWW::Mechanize';
requires 'YAML';
install_script 'dyatel';

auto_install;

WriteAll;

