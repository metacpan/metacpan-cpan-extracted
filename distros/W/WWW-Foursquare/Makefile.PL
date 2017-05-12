use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Foursquare',
    AUTHOR           => q{Pavel Vlasov <fxzuz@cpan.org>},
    VERSION_FROM     => 'lib/WWW/Foursquare.pm',
    ABSTRACT_FROM    => 'lib/WWW/Foursquare.pm',
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
        'JSON'                 => 2.50,
        'URI'                  => 0, 
        'LWP'                  => 6.01,
        'LWP::Protocol::https' => 0,
    },
    META_MERGE => {
        keywords => [ qw/foursquare 4sq www-foursquare/ ],
        resources => {
            homepage   => 'http://fxzuz.github.com/WWW-Foursquare',
            repository => 'https://github.com/fxzuz/WWW-Foursquare',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Foursquare-*' },
);
