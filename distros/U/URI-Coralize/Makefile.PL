use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'URI::Coralize',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/URI/Coralize.pm',
    ABSTRACT_FROM => 'lib/URI/Coralize.pm',
    PREREQ_PM     => {
        'Test::More' => 0,
        'URI'        => 0,
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/uri-coralize',
        },
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'URI-Coralize-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);
