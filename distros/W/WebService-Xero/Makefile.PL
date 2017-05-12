use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::Xero',
    AUTHOR           => q{Peter Scott <peter@computerpros.com.au>},
    VERSION_FROM     => 'lib/WebService/Xero.pm',
    ABSTRACT_FROM    => 'lib/WebService/Xero.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'   => 0.88,
        'Config::Tiny' => 0,
        'JSON'     => 0,
    },
    PREREQ_PM => {
        'Config::Tiny'        => 0,
        'Crypt::OpenSSL::RSA' => 0,
        'File::Slurp'         => 0,
        'XML::Simple'         => 0,
        'Digest::MD5'         => 0,
        'URI::Encode'         => 0,
        'HTTP::Request'       => 0,
        'JSON'                => 0, ## not sure if need to include JSON::PP or JSON::PP here or build?
        'Data::Random'        => 0,
        'Net::OAuth'          => 0,
        'Mozilla::CA'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Xero-*' },
);
