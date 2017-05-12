use strict;
use inc::Module::Install;

name                  'VCS-CSync';
all_from              'lib/VCS/CSync.pm';
requires              'Params::Util' => '0.26';
requires              'Config::Tiny' => '2.01';
requires              'File::Flat'   => '1.00';
requires              'Getopt::Long' => 0;
requires              'File::Spec'   => '0.82';
build_requires        'Test::More'   => '0.47';
build_requires        'Test::Script' => 0;
requires_external_bin 'cvs';
requires_external_bin 'chmod';
install_script        'script/csync';

WriteAll;

