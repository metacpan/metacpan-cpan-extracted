use 5.10.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::ThreatStack',
    AUTHOR           => q{Dino Simone <dino@simone.is>},
    VERSION_FROM     => 'lib/WebService/ThreatStack.pm',
    ABSTRACT_FROM    => 'lib/WebService/ThreatStack.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'JSON' => 0,
        'REST::Client' => 0,
        'Moose' => 0,
        'Moose::Util::TypeConstraints' => 0,
        'MooseX::Params::Validate' => 0
    },    
    PREREQ_PM => {
        'JSON' => 0,
        'REST::Client' => 0,
        'Moose' => 0,
        'Moose::Util::TypeConstraints' => 0,
        'MooseX::Params::Validate' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-ThreatStack-*' },
);
