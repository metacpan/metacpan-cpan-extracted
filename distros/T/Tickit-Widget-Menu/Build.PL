use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::Menu',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.42',

      'Tickit::RenderBuffer' => '0.43', # flush_to_term, in unit tests
      'Tickit::Test' => 0,
      'Tickit::Widget' => '0.36',
      'Tickit::Window' => '0.49',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Tickit::Window' => '0.57',
   },
   auto_configure_requires => 1,
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.freenode.net/#tickit",
      },
   },
);

$build->create_build_script;
