use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $eumm_version = eval ExtUtils::MakeMaker->VERSION(); # Force versions like 7.12_34 into 7.1234. See perldoc perlmodstyle
my $authors = [
    'Rishwanth Yeddula <ryeddula@cpan.org>',
    'David Oswald <davido@cpan.org>',
    'James Jacobson <shames@cpan.org>'
];

WriteMakefile(
    NAME             => 'WWW::Codeguard',
    AUTHOR           => ($eumm_version < 6.5702 ? $authors->[0] : $authors),
    VERSION_FROM     => 'lib/WWW/Codeguard.pm',
    ABSTRACT_FROM    => 'lib/WWW/Codeguard.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008009,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.30', # Multiple authors require EU::MM 6.57_02 or newer.
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
