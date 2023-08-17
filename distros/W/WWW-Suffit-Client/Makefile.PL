#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Mojolicious'           => 7.94,    # Ubuntu = libmojolicious-perl          RHEL = perl-Mojolicious
        'WWW::Suffit'           => 1.00,
        'WWW::Suffit::UserAgent'=> 1.00,
    };

WriteMakefile(
    'NAME'              => 'WWW::Suffit::Client',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/WWW/Suffit/Client.pm',
    'ABSTRACT_FROM'     => 'lib/WWW/Suffit/Client.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/www-suffit-client/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                    type => 'git',
                    url  => 'https://abalama@git.code.sf.net/p/www-suffit-client/code',
                    web  => 'https://sourceforge.net/p/www-suffit-client/code/ci/master/tree/',
                  },
        },
    },
    clean => {
        FILES => '*.tmp',
    },
);

1;
