use strict;
use warnings;
use inc::Module::Install;

name 'WeakRef-Auto';
all_from 'lib/WeakRef/Auto.pm';

requires 'XSLoader' => 0.06;
requires 'Exporter' => 5.57;

test_requires 'Test::More' => 0.62;

tests 't/*.t';
author_tests 'xt';

WriteMakefile(
	OBJECT => '$(O_FILES)',

	clean  => {FILES => q(
		WeakRef-Auto-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},
);
