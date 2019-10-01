#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DB-SQL-Migrations-Advanced',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/DB/SQL/Migrations/Advanced.pm',
    ABSTRACT_FROM    => 'lib/DB/SQL/Migrations/Advanced.pm',
    LICENSE          => 'MIT',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojo::Base' => 0,
        'DBIx::MultiStatementDo' => 0,
        'File::Basename' => 0,
        'File::Slurp' => 0,
        'Test::More' => 0,
    },
    META_MERGE   => {
        no_index       => {directory => ['t']},
        resources => {
            bugtracker => {
                web => 'https://gitlab.com/AuroraSoftware/db-sql-migrations-advanced/issues'
            },
            license    => ['https://opensource.org/licenses/MIT'],
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/AuroraSoftware/db-sql-migrations-advanced.git',
                web  => 'https://gitlab.com/AuroraSoftware/db-sql-migrations-advanced',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DB-SQL-Migrations-Advanced-*' },
    test      => {TESTS => 't/*.t'},
);
