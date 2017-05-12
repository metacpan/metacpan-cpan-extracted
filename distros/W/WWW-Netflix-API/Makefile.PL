use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Netflix::API',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/WWW/Netflix/API.pm',
    ABSTRACT_FROM       => 'lib/WWW/Netflix/API.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                   => 0,
        'Class::Accessor'              => 0,
        'Net::OAuth'                   => 0.13,
        'LWP::Simple'                  => 0,
        'HTTP::Request::Common'        => 0,
        'LWP::UserAgent'               => 0,
        'WWW::Mechanize'               => 0,
        'URI::Escape'                  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Netflix-API-*' },
);
