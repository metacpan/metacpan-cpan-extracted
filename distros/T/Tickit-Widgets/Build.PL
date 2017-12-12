use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widgets',
   dist_abstract => "a collection of Tickit::Widget implementations",
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'perl' => '5.010',
      'List::Util' => '1.33',
      'Parser::MGC' => 0,
      'Struct::Dumb' => 0,
      'Tickit::Event' => '0.63',
      'Tickit::RenderBuffer' => 0,
      'Tickit::Utils' => '0.29',
      'Tickit::Window' => '0.57', # $win->bind_event
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
