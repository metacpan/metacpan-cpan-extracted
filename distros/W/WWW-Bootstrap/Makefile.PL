use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Bootstrap',
    AUTHOR           => q{Thomas Berger <perl@lokis-chaos.de>},
    VERSION_FROM     => 'lib/WWW/Bootstrap.pm',
    ABSTRACT_FROM    => 'lib/WWW/Bootstrap.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'CSS::LESS::Filter' => 0,
        'Path::Extended'    => 0,
        'HTTP::Tiny'        => 0,
        'Archive::Zip'      => 0,
        'Moose'             => 0,
        'namespace::autoclean' => 0,
    },
    CONFIGURE => sub {
        system('which npm >/dev/null 2>&1') and 
            die "npm not found, please install node.js";
        return {};
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Bootstrap-*' },
);
