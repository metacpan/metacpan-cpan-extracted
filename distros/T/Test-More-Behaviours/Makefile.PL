use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::More::Behaviours',
    AUTHOR              => 'Rija Menage <cpan@rijam.sent.as>',
    VERSION_FROM        => 'lib/Test/More/Behaviours.pm',
    ABSTRACT_FROM       => 'lib/Test/More/Behaviours.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-More-Behaviours-*' },
);
