use strict;
use warnings;
use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME                => 'WWW::Bebo::API',
    AUTHOR              => 'Clayton Scott <clscott@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Bebo/API.pm',
    ABSTRACT_FROM       => 'lib/WWW/Bebo/API.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'version'           => 0,
        'Crypt::SSLeay'     => 0,
        'Digest::MD5'       => 0,
        'JSON::Any'         => 0,
        'Time::HiRes'       => 0,
        'LWP::UserAgent'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Bebo-API-*' },
);
