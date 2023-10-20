use v5;
use strict;
use warnings;

use Module::Build;

my @extra_compiler_flags;

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

my $build = Module::Build->new(
   module_name => 'meta',
   configure_requires => {
      'Module::Build' => "0.4004", # test_requires
   },
   requires => {
      'perl' => '5.014',
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   extra_compiler_flags => \@extra_compiler_flags,
);

$build->create_build_script;
