use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::SegmentDisplay',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.19',

      'Tickit::Test' => '0.12',
      'Tickit::Widget' => '0.36',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
