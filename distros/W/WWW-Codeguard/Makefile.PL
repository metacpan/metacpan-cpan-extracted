use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Codeguard',
    AUTHOR           => [
        'Rishwanth Yeddula <ryeddula@cpan.org>',
        'David Oswald <davido@cpan.org>',
        'James Jacobson <shames@cpan.org>'
    ],
    VERSION_FROM     => 'lib/WWW/Codeguard.pm',
    ABSTRACT_FROM    => 'lib/WWW/Codeguard.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008009,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'       => 0,
        'Test::MockModule' => 0,
        'JSON'             => 0,
        'parent'           => 0, # this is core as of 5.10.1, so specifing this for 5.8 installs
    },
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
        'JSON'           => 0,
        'Net::OAuth'     => 0,
        'HTTP::Request'  => 0,
        'parent'         => 0, # this is core as of 5.10.1, so specifing this for 5.8 installs
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/daoswald/www-codeguard.git',
                web  => 'https://github.com/daoswald/www-codeguard',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Codeguard-*' },
);
