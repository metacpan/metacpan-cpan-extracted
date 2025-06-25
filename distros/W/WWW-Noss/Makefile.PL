use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use DBD::SQLite;

my %WriteMakefileArgs = (
    NAME             => 'WWW::Noss',
    AUTHOR           => q{Samuel Young <samyoung12788@gmail.com>},
    VERSION_FROM     => 'lib/WWW/Noss.pm',
    ABSTRACT_FROM    => 'lib/WWW/Noss.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'DBD::SQLite' => '0',
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'File::Spec' => '0',
        # for UNLINK
        'File::Temp' => '0.10',
    },
    PREREQ_PM => {
        'Cwd' => '0',
        'DateTime' => '0',
        'DateTime::Format::Mail' => '0',
        'DateTime::Format::RFC3339' => '0',
        'DBD::SQLite' => '0',
        # for 'AutoInactiveDestroy'
        'DBI' => '1.614',
        'Getopt::Long' => '0',
        'File::Basename' => '0',
        'File::Copy' => '0',
        'File::Spec' => '0',
        # for UNLINK
        'File::Temp' => '0.10',
        'JSON' => '0',
        # for any, none, all
        'List::Util' => '1.33',
        # for retrieving data structures from children
        'Parallel::ForkManager' => '0.7.6',
        'POSIX' => '0',
        # for load_xml()
        'XML::LibXML' => '1.70',
    },
    EXE_FILES => [
        'bin/noss',
        'bin/nossui',
    ],
    MAN1PODS => {
        'bin/noss'       => 'blib/man1/noss.1',
        'doc/nossui.pod' => 'blib/man1/nossui.1',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                url => 'https://codeberg.org/1-1sam/noss.git',
                web => 'https://codeberg.org/1-1sam/noss',
                type => 'git',
            },
            bugtracker => {
                web => 'https://codeberg.org/1-1sam/noss/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Noss-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

# for RETURNING clause
unless ($DBD::SQLite::sqlite_version_number >= 3035000) {
    die "noss requires at least sqlite version 3.35.0\n";
}

WriteMakefile(%WriteMakefileArgs);
