use strict;
use inc::Module::Install;

all_from 'lib/XS/Assert.pm';

install_headers 'xs_assert.h';

cc_warnings;

test_requires 'Test::More' => 0.42;

tests 't/*.t';
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
	XS-Assert-* *.stackdump
	*.gcda *.gcno *.gcov
	nytprof *.out
	cover_db
);

WriteAll check_nmake => 0;

