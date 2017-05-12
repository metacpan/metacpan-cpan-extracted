use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/XS/MagicExt.pm';

use_ppport 3.19;
cc_warnings;

install_headers 'magic_ext.h';

test_requires 'Test::More' => 0.88;

tests 't/*.t';
author_tests 'xt';

auto_set_repository if -d '.git';

clean_files qw(
	XS-MagicExt-* *.stackdump
	*.gcda *.gcno *.gcov
	nytprof *.out
	cover_db
);

WriteAll check_nmake => 0;
