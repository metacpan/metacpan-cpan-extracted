use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::JugemKey::Auth',
    AUTHOR              => 'Gosuke Miyashita <gosukenator@gmail.com>',
    VERSION_FROM        => 'lib/WebService/JugemKey/Auth.pm',
    ABSTRACT_FROM       => 'lib/WebService/JugemKey/Auth.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'               => 0,
        'URI'                      => 0,
        'LWP::UserAgent'           => 0,
        'Digest::HMAC'             => 0,
        'Digest::SHA1'             => 0,
        'DateTime'                 => 0,
        'DateTime::Format::W3CDTF' => 0,
        'XML::Atom::Entry;'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-JugemKey-Auth-*' },
);
