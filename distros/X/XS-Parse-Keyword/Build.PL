use strict;
use warnings;

use lib 'inc';
use Module::Build::with::XSTests;

my $build = Module::Build::with::XSTests->new(
   module_name => 'XS::Parse::Keyword',
   requires => {
      'perl' => '5.014', # PL_keyword_plugin
   },
   test_requires => {
      'Test::Fatal' => 0,
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
