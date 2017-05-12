use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    META_MERGE => {
        recommends => {
            'Test::MockTime' => 0,
            'Time::HiRes'   => 0,
        }
    },
    NAME                => 'Test::MockSleep',
    AUTHOR              => q{M. Nunberg <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/Test/MockSleep.pm',
    ABSTRACT_FROM       => 'lib/Test/MockSleep.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dir::Self' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-MockSleep-*' },
);
