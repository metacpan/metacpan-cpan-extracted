use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;
use XS::Parse::Infix::Builder;

my $build = Module::Build->new(
   module_name => "XS::Parse::Keyword::FromPerl",
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.39',
      'XS::Parse::Infix::Builder' => 0,
   },
   requires => {
      'perl' => '5.026',
      'meta' => '0.003_002',
      'XS::Parse::Keyword' => '0.39',
      'XS::Parse::Infix' => '0.35',
      ( $^V lt v5.36.0 ? ( 'builtin::Backport' => 0 ) : () ),
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   extra_compiler_flags => [qw( -I. -Ihax -ggdb )],
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
);

if( eval { require Devel::MAT::Dumper::Helper and
            Devel::MAT::Dumper::Helper->VERSION( '0.44' ) } ) {
   Devel::MAT::Dumper::Helper->extend_module_build( $build );
}

XS::Parse::Keyword::Builder->extend_module_build( $build );
XS::Parse::Infix::Builder->extend_module_build( $build );

$build->create_build_script;
