require 5.006001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 'XML::Descent',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/XML/Descent.pm',
  ABSTRACT_FROM => 'lib/XML/Descent.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'        => 0,
    'XML::TokeParser'   => 0,
    'Test::Differences' => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'XML-Descent-*' },
);

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}
