use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Throw::Back',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Throw/Back.pm',
    ABSTRACT_FROM => 'lib/Throw/Back.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Throw-Back-*' },
);
