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
  PREREQ_PM => {qw(
    Carp                     0
    Archive::Tar             0
    File::Spec::Functions    0
    File::Basename           0
    File::Path               0
    MIME::Base64             0
    IO::Uncompress::Gunzip   0
    HTTP::Tiny               0
  )},
  test => {TESTS => 't/*.t'}
);
