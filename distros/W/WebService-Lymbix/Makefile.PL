use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService::Lymbix',
    AUTHOR        => q{Omid Houshyar <ohoushyar@gmail.com>},
    VERSION_FROM  => 'lib/WebService/Lymbix.pm',
    ABSTRACT_FROM => 'lib/WebService/Lymbix.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Carp'           => 0,
        'Encode'         => 0,
        'Mouse'          => 0,
        'LWP::UserAgent' => 6,
        'HTTP::Request'  => 6,
        'Test::Most'     => 0.25,
        'JSON'           => 0,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'WebService-Lymbix-*' },
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/ohoushyar/webservice-lymbix',
            bugtracker => 'https://github.com/ohoushyar/webservice-lymbix/issues',
            repository => 'git://github.com/ohoushyar/webservice-lymbix',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
);
