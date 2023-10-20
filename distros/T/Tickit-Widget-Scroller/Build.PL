use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::Scroller',
   requires => {
      'perl' => '5.026', # signatures
      'Object::Pad' => '0.800',

      'String::Tagged' => 0,
      'Tickit::RenderBuffer' => '0.43', # flush_to_term
      'Tickit::Widget' => '0.35',
      'Tickit::Window' => '0.57',
      'Tickit::Pen' => '0.19',
   },
   test_requires => {
      'Test2::V0' => 0,
      'Tickit::Test' => '0.12',
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
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
