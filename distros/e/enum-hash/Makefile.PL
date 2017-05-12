use 5.000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'enum::hash',
    VERSION_FROM => 'hash.pm',
    PREREQ_PM    => {
                     Carp       => 0,
                     Test::More => 0,
    },
);

