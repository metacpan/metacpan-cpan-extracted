use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Txodds',
    AUTHOR        => q{"Foxcool" <"">},
    VERSION_FROM  => 'lib/WWW/Txodds.pm',
    ABSTRACT_FROM => 'lib/WWW/Txodds.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent'        => 0,
        'XML::LibXML::Simple'   => 0,
        'Carp'                  => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Txodds-*' },
);
