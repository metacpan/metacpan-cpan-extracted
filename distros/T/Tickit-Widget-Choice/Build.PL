use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::Choice',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.74', # 0.73 + bugfix

      'Tickit::RenderBuffer' => 0,
      'Tickit::Style' => 0,
      'Tickit::Widget' => 0,
      'Tickit::Widget::Menu' => '0.09',
   },
   build_requires => {
      'Test::More' => '0.88', # done_testing
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
