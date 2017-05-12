use 5.008_001;
use strict;
use warnings;
use inc::Module::Install;
use Module::Install::XSUtil;
use Module::Install::Repository;

all_from 'lib/warnings/unused.pm';

use_ppport;

requires 'XSLoader'   => 0.06;

test_requires 'Test::More' => 0.62;
test_requires 'Test::Warn' => 0.11;

auto_set_repository;

author_tests 'xt';

WriteMakefile(
	clean => {FILES => q{warnings-unused-*
				*.gcov *.gcda *.gcno
				*.stackdump cover_db}
		},
);
