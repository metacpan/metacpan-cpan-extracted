#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Acrux'                 => 0.07,    # Ubuntu = libacrux-perl                RHEL = perl-Acrux
        'Acrux::DBI'            => 0.03,    # Ubuntu = libacrux-dbi-perl            RHEL = perl-Acrux-DBI
        'DBI'                   => 1.63,    # Ubuntu = libdbi-perl                  RHEL = perl-DBI
        'DBD::SQLite'           => 1.00,    # Ubuntu = libdbd-sqlite3-perl          RHEL = perl-DBD-SQLite
    };

WriteMakefile(
    'NAME'              => 'WWW::Suffit::Model',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/WWW/Suffit/Model.pm',
    'ABSTRACT_FROM'     => 'lib/WWW/Suffit/Model.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/www-suffit-model/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                type => 'git',
                url  => 'https://abalama@git.code.sf.net/p/www-suffit-model/code',
                web  => 'https://sourceforge.net/p/www-suffit-model/code/ci/master/tree/',
            },
        },
    },
    clean => {
        FILES => '*.tmp *.db',
    },
);

1;
