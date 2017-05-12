use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'provide',
  AUTHOR              => q{Belden Lyman <belden@cpan.org>},
  VERSION_FROM        => 'lib/provide.pm',
  ABSTRACT            => 'easily choose between different version-specific implementations',
  LICENSE => 'perl',
  PL_FILES            => {},
  META_MERGE => {
    resources => {
      bugtracker => 'https://github.com/belden/perl-provide/issues',
    },
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
