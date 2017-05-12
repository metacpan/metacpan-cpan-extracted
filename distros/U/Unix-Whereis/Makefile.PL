use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Unix::Whereis',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Unix/Whereis.pm',
    ABSTRACT_FROM => 'lib/Unix/Whereis.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'  => 0,
        'File::Temp'  => 0,
        'File::Slurp' => 0,

        'File::Spec' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Unix-Whereis-*' },
);
