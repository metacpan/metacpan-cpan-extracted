use strict;
use warnings;
use lib '.';
use inc::Module::Install;

name 'Test-LeakTrace';
all_from 'lib/Test/LeakTrace.pm';

requires 'Exporter'   => 5.57;
requires 'Test::More' => 0.62;

tests 't/*.t';
author_tests 'xt';

auto_set_repository;

if($Module::Install::AUTHOR){
	makemaker_args(DEFINE => '-DTESTING_PTR_TABLE_COMPAT');
}

WriteMakefile(
	OBJECT => '$(O_FILES)',

	clean  => {FILES => q(
		Test-LeakTrace-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},
);
