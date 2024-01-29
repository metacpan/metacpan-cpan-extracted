#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Mojolicious'           => 7.94,    # Ubuntu = libmojolicious-perl          RHEL = perl-Mojolicious
        'Mojolicious::Plugin::ConfigGeneral' => 1.02, # RHEL = perl-Mojolicious-Plugin-ConfigGeneral
        'WWW::Suffit'           => 1.06,    # Ubuntu = libwww-suffit-perl           RHEL = perl-WWW-Suffit
        'WWW::Suffit::API'      => 1.00,    # Ubuntu = libwww-suffit-api-perl       RHEL = perl-WWW-Suffit-API
        'WWW::Suffit::Plugin::BasicAuth'        => 1.00,    # Ubuntu = libwww-suffit-plugin-basicauth-perl      RHEL = perl-WWW-Suffit-Plugin-BasicAuth
        'WWW::Suffit::Plugin::CommonHelpers'    => 1.00,    # Ubuntu = libwww-suffit-plugin-commonhelpers-perl  RHEL = perl-WWW-Suffit-Plugin-CommonHelpers
        'WWW::Suffit::Plugin::ServerInfo'       => 1.01,    # Ubuntu = libwww-suffit-plugin-serverinfo-perl     RHEL = perl-WWW-Suffit-Plugin-ServerInfo
        'WWW::Suffit::Plugin::Syslog'           => 1.00,    # Ubuntu = libwww-suffit-plugin-syslog-perl         RHEL = perl-WWW-Suffit-Plugin-Syslog
    };

WriteMakefile(
    'NAME'              => 'WWW::Suffit::Server',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/WWW/Suffit/Server.pm',
    'ABSTRACT_FROM'     => 'lib/WWW/Suffit/Server.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/www-suffit-server/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                    type => 'git',
                    url  => 'https://abalama@git.code.sf.net/p/www-suffit-server/code',
                    web  => 'https://sourceforge.net/p/www-suffit-server/code/ci/master/tree/',
                  },
        },
    },
);

1;
