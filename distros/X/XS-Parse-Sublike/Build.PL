use v5;
use strict;
use warnings;

use lib 'inc';
use Module::Build::with::XSTests;

my @extra_compiler_flags = qw( -Ishare/include -Iinclude -Ihax );

# Perl 5.36 made -std=c99 standard; before then we'll have to request it specially
push @extra_compiler_flags, qw( -std=c99 ) if $^V lt v5.36.0;

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

use Config;
if( $Config{ccname} eq "gcc" ) {
   # Enable some extra gcc warnings, largely just for author interest
   push @extra_compiler_flags, qw( -Wall -Wno-unused-function -Wno-unused-value );
}

my $build = Module::Build::with::XSTests->new(
   module_name => 'XS::Parse::Sublike',
   requires => {
      'perl' => '5.016', # pad_add_name_pvn
         # Not actually needed but used by hax/lexer-additions.c.inc
   },
   test_requires => {
      'Sub::Util' => 0,
      'Test2::V0' => '0.000147',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   share_dir => {
      module => { 'XS::Parse::Sublike' => [ 'share' ] },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
   c_source => [ "src/" ],
);

$build->create_build_script;
