#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Test::LeakTrace',
    VERSION_FROM => 'lib/Test/LeakTrace.pm',
	AUTHOR       => 'FUJI Goro',
    LICENSE      => 'perl',
    PREREQ_PM    => {
      'Exporter' => 5.57,
    },
    TEST_REQUIRES => {
        'Test::More' => 0.62
    },

	OBJECT => '$(O_FILES)',
	clean  => {FILES => q(
		Test-LeakTrace-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},

    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/release/Test-LeakTrace',
            repository => {
                type => 'git',
                url  => 'https://github.com/gfx/p5-Test-LeakTrace.git',
                web  => 'https://github.com/gfx/p5-Test-LeakTrace',
            },
            bugtracker => {
                web => 'https://github.com/gfx/p5-Test-LeakTrace/issues',
            },
        },
    }):()),
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);
