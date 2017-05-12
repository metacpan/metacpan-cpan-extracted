use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'WWW::RaptureReady',
  AUTHOR              => q{blair christensen <blair.christensen@gmail.com>},
  VERSION_FROM        => 'lib/WWW/RaptureReady.pm',
  ABSTRACT_FROM       => 'lib/WWW/RaptureReady.pm',
  ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'=> 'perl')
    : ()),
  EXE_FILES           => [ 'bin/rapture-ready.pl' ],
  PL_FILES            => {},
  PREREQ_PM => {
    'LWP::UserAgent'  => 0, 
    'Test::More'      => 0
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'WWW-RaptureReady-*' },
);

