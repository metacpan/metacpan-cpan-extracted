#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME                => 'XMLRPC::Fast',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/XMLRPC/Fast.pm',
    ABSTRACT_FROM       => 'lib/XMLRPC/Fast.pm',
    MIN_PERL_VERSION    => '5.10.0',
    PREREQ_PM => {
        'B'             => 0,
        'Encode'        => 0,
        'Exporter'      => 0,
        'MIME::Base64'  => 0,
        'XML::Parser'   => 0,
    },
    META_MERGE          => {
        resources       => {
            repository  => "https://github.com/maddingue/XMLRPC-Fast.git",
        },
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XMLRPC-Fast-*' },
);

