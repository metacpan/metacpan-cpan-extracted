use strict;
use warnings;

use lib 'inc';
use Module::Build::with::XSTests;

my $MIN_PERL = '5.014'; # PL_keyword_plugin

# MSWin32 needs at least perl 5.22
#   https://rt.cpan.org/Ticket/Display.html?id=136577
$MIN_PERL = '5.022' if $^O eq "MSWin32";

my $build = Module::Build::with::XSTests->new(
   module_name => 'XS::Parse::Keyword',
   requires => {
      'perl' => $MIN_PERL,
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
