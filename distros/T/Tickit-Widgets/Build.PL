use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widgets',
   dist_abstract => "a collection of Tickit::Widget implementations",
   requires => {
      'perl' => '5.010',
      'List::Util' => '1.33',
      'Parser::MGC' => 0,
      'Struct::Dumb' => 0,
      'Tickit::RenderBuffer' => 0,
      'Tickit::Utils' => '0.29',
      'Tickit::Window' => '0.57', # $win->bind_event
   },
   build_requires => {
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
