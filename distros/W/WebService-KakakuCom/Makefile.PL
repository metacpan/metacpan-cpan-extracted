use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::KakakuCom',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/WebService/KakakuCom.pm',
    ABSTRACT_FROM       => 'lib/WebService/KakakuCom.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'               => 0,
        'Class::Accessor::Fast'    => 0,
        'Class::Data::Inheritable' => 0,
        'XML::Simple'              => 0,
        'Data::Page'               => 0,
        'LWP::UserAgent'           => 0,
        'Jcode'                    => 0,
        'Readonly'                 => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-KakakuCom-*' },
);
