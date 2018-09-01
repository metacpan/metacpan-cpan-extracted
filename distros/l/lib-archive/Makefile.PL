use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  NAME             => 'lib::archive',
  VERSION_FROM     => 'lib/lib/archive.pm',
  ABSTRACT         => 'load pure-Perl modules directly from TAR archives',
  AUTHOR           => 'Thomas Kratz <tomk@cpan.org>',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => 5.010001,
  META_MERGE       => {
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/tomk3003/lib-archive',
      bugtracker  => 'https://github.com/tomk3003/lib-archive/issues'
    },
    no_index => {directory => ['t']}
  },

  test => {TESTS => 't/*.t'}
);
