use v5;
use strict;
use warnings;

use lib 'inc';
use Module::Build::with::XSTests;

my @extra_compiler_flags = qw( -I. -Ihax );

# Perl 5.36 made -std=c99 standard; before then we'll have to request it specially
push @extra_compiler_flags, qw( -std=c99 ) if $^V lt v5.36.0;

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

my $build = Module::Build::with::XSTests->new(
   module_name => 'XS::Parse::Sublike',
   requires => {
      'perl' => '5.016', # pad_add_name_pvn
         # Not actually needed but used by hax/lexer-additions.c.inc
   },
   test_requires => {
      'Sub::Util' => 0,
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
);

$build->create_build_script;
