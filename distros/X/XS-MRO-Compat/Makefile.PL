use strict;
use warnings;
use inc::Module::Install;

name 'XS-MRO-Compat';
all_from 'lib/XS/MRO/Compat.pm';

requires 'MRO::Compat';
requires 'Class::C3::XS' if $] < 5.010;

test_requires 'Test::More' => 0.86;

use_ppport 3.19;

install_headers 'mro_compat.h';

tests 't/*.t';
author_tests 'xt';

auto_set_repository;

clean_files qw(
		XS-MRO-Compat-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
);

WriteAll check_nmake => 0;
