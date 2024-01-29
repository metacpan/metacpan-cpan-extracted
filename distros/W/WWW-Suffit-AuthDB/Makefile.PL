#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'CTK'                   => 2.09,    # Ubuntu = libctk-perl                  RHEL = perl-CTK
        'Mojolicious'           => 7.94,    # Ubuntu = libmojolicious-perl          RHEL = perl-Mojolicious
        'WWW::Suffit'           => 1.06,    # Ubuntu = libwww-suffit-perl           RHEL = perl-WWW-Suffit
        'Net::IP'               => 1.00,    # Ubuntu = libnet-ip-perl               RHEL = perl-Net-IP
    };

WriteMakefile(
    'NAME'              => 'WWW::Suffit::AuthDB',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/WWW/Suffit/AuthDB.pm',
    'ABSTRACT_FROM'     => 'lib/WWW/Suffit/AuthDB.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/www-suffit-authdb/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                    type => 'git',
                    url  => 'https://abalama@git.code.sf.net/p/www-suffit-authdb/code',
                    web  => 'https://sourceforge.net/p/www-suffit-authdb/code/ci/master/tree/',
                  },
        },
    },
);

1;
