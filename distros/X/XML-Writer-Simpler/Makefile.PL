use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'XML::Writer::Simpler',
    AUTHOR           => q{Michael McClimon <michael@mcclimon.org>},
    VERSION_FROM     => 'lib/XML/Writer/Simpler.pm',
    ABSTRACT_FROM    => 'lib/XML/Writer/Simpler.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'XML::Writer'       => 0.6,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-Writer-Simpler-*' },
);
