use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Untappd::API',
    AUTHOR              => 'Rafael Oliveira Lopes <rlopes@cpan.org>',
    VERSION_FROM        => 'lib/Untappd/API.pm',
    ABSTRACT_FROM       => 'lib/Untappd/API.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0.88,
        'Moo'           => 0,
        'Hijk'          => 0,
    },
    META_MERGE      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Untappd-API',
            repository  => 'http://github.com/rafaelol/untappd-api',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Untappd-API-*' },
);


WriteMakefile( %options );

