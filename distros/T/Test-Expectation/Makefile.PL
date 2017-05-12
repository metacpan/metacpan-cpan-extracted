use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Test::Expectation',
    VERSION_FROM      => 'lib/Test/Expectation.pm',
    PREREQ_PM         => {
        Test::More => '0.86',
        Sub::Override => '0.08',
    },
    ($] >= 5.005 ?
       (AUTHOR         => 'Stephen Hardisty <moowahaha@hotmail.com>') : ()),
);
