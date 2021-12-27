use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::App::Plugin::EscapePrefix',
   requires => {
      'Tickit' => '0.64',
      'Tickit::Term' => 0,
      'Tickit::Test' => '0.70',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
