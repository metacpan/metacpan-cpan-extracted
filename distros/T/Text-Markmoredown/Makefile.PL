use strict;
use warnings;
use utf8;

use 5.012;

use ExtUtils::MakeMaker;

WriteMakefile
(
  NAME             => 'Text::Markmoredown',
  AUTHOR           => 'Kiavash',
  VERSION_FROM     => 'lib/Text/Markmoredown.pm',
  ABSTRACT         => 'MarkMoreDown parser',
  LICENSE          => 'mit',
  EXE_FILES        => [
      "bin/markmod"
  ],
  MIN_PERL_VERSION => 5.008,
  CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'       => 0,
  },
  PREREQ_PM => {
        'Digest::MD5'           => 0,
        'HTML::Entities'        => 0,
        'Text::ASCIIMathML'     => 0,
},

  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
          type => 'git',
          url  => 'https://github.com/kiamazi/markmoredown.git',
          web  => 'https://github.com/kiamazi/markmoredown',
      },
    },
  },
);


1;
