use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::BigDoor',
    AUTHOR              => 'Alex L. Demidov <alexeydemidov@gmail.com>',
    VERSION_FROM        => 'lib/WWW/BigDoor.pm',
    ABSTRACT_FROM       => 'lib/WWW/BigDoor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Most'         => 0,
        'version'            => 0,
        'Digest::SHA'        => 0,
        'Hook::LexWrap'      => 0,
        'JSON'               => 0,
        'REST::Client'       => 0,
        'Smart::Comments'    => 0,
        'Test::Kwalitee'     => 0,
        'Test::MockModule'   => 0,
        'Test::MockObject'   => 0,
        'Test::NoWarnings'   => 0,
        'Test::Perl::Critic' => 0,
        'URI'                => 0,
        'UUID::Tiny'         => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BigDoor-*' },
);
