use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'arXiv',
    AUTHOR              => q{arXiv.org <simeon@cpan.org>},
    VERSION_FROM        => 'lib/arXiv.pm',
    ABSTRACT_FROM       => 'lib/arXiv.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'arXiv-*' },
    test                => { TESTS => 't/*.t t/*/*.t'}
);
