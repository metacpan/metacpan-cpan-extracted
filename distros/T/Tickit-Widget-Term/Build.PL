use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::Term',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.51',
      'Syntax::Keyword::Match' => 0,

      'Convert::Color::RGB8' => 0,
      'Convert::Color::XTerm' => 0,
      'List::Util' => 0,
      'Term::VTerm' => '0.07',
      'Tickit' => '0.71',
      'Tickit::Widget' => '0.32',
   },
   test_requires => {
      'IO::Pty' => '1.12',
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
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
