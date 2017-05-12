use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Timer::Runtime',
    AUTHOR              => q{Adam Wohld <adam@radarlabs.com>},
    VERSION_FROM        => 'lib/Timer/Runtime.pm',
    ABSTRACT_FROM       => 'lib/Timer/Runtime.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Time::Local'  => 0,
        'Time::Elapse' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'   => 0,
        'Time::Local'  => 0,
        'Time::Elapse' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Timer-Runtime-*' },
);
