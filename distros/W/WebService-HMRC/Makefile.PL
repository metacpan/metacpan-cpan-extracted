use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::HMRC',
    AUTHOR           => q{Nick Prater <nick@npbroadcast.com>},
    VERSION_FROM     => 'lib/WebService/HMRC.pm',
    ABSTRACT_FROM    => 'lib/WebService/HMRC.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'JSON::MaybeXS' => 0,
        'List::Util' => 1.33,
        'LWP::Protocol::https' => 0,
        'LWP::UserAgent' => 0,
        'Moose' => 0,
        'namespace::autoclean' => 0,
        'Try::Tiny' => 0,
        'URI' => 0,
        'URI::Escape' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/nick-prater/WebService-HMRC.git',
                web => 'https://github.com/nick-prater/WebService-HMRC',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-HMRC-*' },
);
