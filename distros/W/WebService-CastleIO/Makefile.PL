use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::CastleIO',
    AUTHOR           => q{Dino Simone <dino@simone.is>},
    VERSION_FROM     => 'lib/WebService/CastleIO.pm',
    ABSTRACT_FROM    => 'lib/WebService/CastleIO.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'JSON' => 0,
	'REST::Client' => 0,
	'MIME::Base64' => 0,
	'Moose' => 0,
	'Moose::Util::TypeConstraints' => 0,
	'MooseX::Params::Validate' => 0
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-CastleIO-*' },
);
