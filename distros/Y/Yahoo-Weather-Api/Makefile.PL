use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Yahoo::Weather::Api',
    AUTHOR           => q{Sushrut Pajai <spajai@cpan.org>},
    VERSION_FROM     => 'lib/Yahoo/Weather/Api.pm',
    ABSTRACT_FROM    => 'lib/Yahoo/Weather/Api.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'     => 0,
        'JSON'           => '2.0',
        'XML::Validate'  => 0,
        'JSON::Parse'    => 0,
        'URL::Builder'   => '0.06',
        'XML::LibXML'    => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'     => 0,
        'JSON'           => '2.0',
        'XML::Validate'  => 0,
        'JSON::Parse'    => 0,
        'URL::Builder'   => '0.06',
        'XML::LibXML'    => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
        'Carp'           => 0,
        'URL::Builder'   => '0.06',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Yahoo-Weather-Api-*' },
);
