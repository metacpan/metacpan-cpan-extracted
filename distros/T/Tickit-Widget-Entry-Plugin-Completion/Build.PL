use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::Entry::Plugin::Completion',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.75',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Tickit::Test' => 0,
      'Tickit::Widget' => '0.55',
      'Tickit::Widget::Entry' => '0.33',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
