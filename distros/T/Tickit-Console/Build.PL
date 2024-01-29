use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Console',
   requires => {
      'perl' => '5.026', # signatures in Object::Pad

      'Object::Pad' => '0.800',
      'String::Tagged' => '0.10',
      'Tickit' => 0,
      'Tickit::Window' => '0.45', # rendering order
      'Tickit::Widget::Entry' => 0,
      'Tickit::Widget::Scroller' => '0.04',
      'Tickit::Widget::Tabbed' => '0.024', # BUILDARGS
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test2::V0' => '0.000148',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
