use v5;
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
      'perl' => '5.020', # experimental.pm; postderef
      'meta' => '0.008',

      'List::Util' => '1.33',
      'Object::Pad' => '0.808',
      'Parser::MGC' => 0,
      'Syntax::Keyword::Dynamically' => 0,
      'Tickit::Event' => '0.66', # $info->type newapi
      'Tickit::RenderBuffer' => 0,
      'Tickit::Utils' => '0.29',
      'Tickit::Window' => '0.57', # $win->bind_event
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
