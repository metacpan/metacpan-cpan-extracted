use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Varnish',
    AUTHOR              => 'Cosimo Streppone <cosimo@cpan.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Test/Varnish.pm',
    ABSTRACT_FROM       => 'lib/Test/Varnish.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTTP::Request' => 0,
        'HTTP::Response' => 0,
        'HTTP::Cookies' => 0,
        'LWP::UserAgent' => 0,
        'Getopt::Long' => 0,
        'URI' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'git://github.com/cosimo/perl5-test-varnish.git',
            bugtracker => 'mailto:bug-test-varnish@rt.cpan.org',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Varnish-*' },
);

