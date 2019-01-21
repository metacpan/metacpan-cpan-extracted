use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'lib::rabs',
    VERSION_FROM    => 'lib/lib/rabs.pm',
    AUTHOR          => ['Alexey Golovlev <a.golovlev@crazypanda.ru>'],
    PREREQ_PM       => {
        'lib::abs'    => 0,
    },
    TEST_REQUIRES   => {
        'Test::More'  => 0,
    },
    META_MERGE => {
        dynamic_config => 0,
    },
    ABSTRACT_FROM   => 'lib/lib/rabs.pm',
    LICENSE         => 'perl',
    MIN_PERL_VERSION=> 5.010001,
);
