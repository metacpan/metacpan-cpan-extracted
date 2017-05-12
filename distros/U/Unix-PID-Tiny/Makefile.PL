use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Unix::PID::Tiny',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Unix/PID/Tiny.pm',
    ABSTRACT_FROM => 'lib/Unix/PID/Tiny.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Unix-PID-Tiny-*' },
);
