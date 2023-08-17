use v5;
use strict;
use warnings;

use Module::Build;

my @extra_compiler_flags = qw( -Ihax );

my $build = Module::Build->new(
   module_name => 'builtin::Backport',
   requires => {
      'perl' => '5.018',
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

   # Only build the .xs file on non-latest perls
   ( $^V ge v5.38.0 ? ( xs_files => {} ) : () ),

   # Do not index the actual builtin.pm file for now, until we work out the
   # best way to share this on CPAN with core perl
   no_index => { package => [qw( builtin )] },

   extra_compiler_flags => \@extra_compiler_flags,
);

$build->create_build_script;
