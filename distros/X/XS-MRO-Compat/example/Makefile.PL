use blib '..';

use strict;
use warnings;
use inc::Module::Install;

name 'MyMRO';

author 'Goro Fuji';
license 'perl';

all_from 'MyMRO.pm';

requires_xs 'XS::MRO::Compat';
use_ppport 3.19;
cc_warnings;

test_requires 'Test::More' => 0.62;

tests 't/*.t';


clean_files qw(
	MyMRO-* *.stackdump
	*.gcda *.gcno *.gcov
	cover_db
);

WriteAll check_nmake => 0;

