use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'URI::Unredirect',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/URI/Unredirect.pm',
    ABSTRACT_FROM => 'lib/URI/Unredirect.pm',
    PREREQ_PM     => {
        'Test::More'  => 0,
        'URI'         => 0,
        'URI::Escape' => 0,
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/uri-unredirect',
        },
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'URI-Unredirect-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);
