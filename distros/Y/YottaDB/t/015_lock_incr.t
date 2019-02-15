use strict;
use warnings;

use Test::More;
use YottaDB qw/:all/;

unless (exists $ENV{TEST_DB}) {
	plan skip_all => 'environment variable TEST_DB not set';
} else {
	plan tests => 1;
	y_lock_incr (3.1415926535, "a", 1) or die "timeout";
	y_lock_decr ("a", 1);
	ok (1);
}
