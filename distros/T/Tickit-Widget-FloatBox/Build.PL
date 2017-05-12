use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::FloatBox',
   requires => {
      'Tickit::ContainerWidget' => 0,
   },
   build_requires => {
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
      'Tickit::Test' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
