use strict;
use warnings;

use lib 'inc';
use Module::Build::with::XSTests;

my $build = Module::Build::with::XSTests->new(
   module_name => 'XS::Parse::Sublike',
   requires => {
      'perl' => '5.016', # pad_add_name_pvn
         # Not actually needed but used by hax/lexer-additions.c.inc
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => [qw( -I. -Ihax )],
);

$build->create_build_script;
