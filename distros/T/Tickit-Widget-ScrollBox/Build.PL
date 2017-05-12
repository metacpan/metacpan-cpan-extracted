use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::ScrollBox',
   requires => {
      'Tickit::SingleChildWidget' => '0.36',
      'Tickit::Style' => '0.35',
      'Tickit::Window' => '0.39',
   },
   build_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
      'Tickit::Test' => '0.38', # bugfix to ICH/DCH scrollrect
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.freenode.net/#tickit",
      },
   },
);

$build->create_build_script;
