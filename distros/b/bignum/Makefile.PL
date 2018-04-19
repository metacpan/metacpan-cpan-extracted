#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs =
  (
   'NAME'               => 'bignum',
   'VERSION_FROM'       => 'lib/bignum.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.010,
   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.64,
                           },
   'BUILD_REQUIRES'     => {
                            'ExtUtils::MakeMaker' => 6.64,
                           },
   'PREREQ_PM'          => {
                            'Math::BigInt'        => 1.999812,
                            'Math::BigRat'        => 0.12,
                            #'Math::BigInt::Lite'  => 0.09,      # optional
                           },
   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.88,
                           },
   'LICENSE'            => 'perl_5',
   'LIBS'               => [''],        # e.g., '-lm'
   'DEFINE'             => '',          # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',          # e.g., '-I/usr/include/other'
   'SIGN'               => 1,
  );

# Install over the core version? (Cf. CPAN RT #119199 and #119225.)

$WriteMakefileArgs{INSTALLDIRS} = 'perl'
  if $] >= 5.008 && $] < 5.012;

WriteMakefile(%WriteMakefileArgs);
