use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Console',
   requires => {
      'String::Tagged' => '0.10',
      'Tickit' => 0,
      'Tickit::Window' => '0.45', # rendering order
      'Tickit::Widget::Entry' => 0,
      'Tickit::Widget::Scroller' => '0.04',
      'Tickit::Widget::Tabbed' => '0.015', # rendering order
      'perl' => '5.010',
   },
   build_requires => {
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
