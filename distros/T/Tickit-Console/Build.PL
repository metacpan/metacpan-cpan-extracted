use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Console',
   requires => {
      'Object::Pad' => '0.43',
      'String::Tagged' => '0.10',
      'Tickit' => 0,
      'Tickit::Window' => '0.45', # rendering order
      'Tickit::Widget::Entry' => 0,
      'Tickit::Widget::Scroller' => '0.04',
      'Tickit::Widget::Tabbed' => '0.024', # BUILDARGS
      'perl' => '5.026', # signatures in Object::Pad
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
