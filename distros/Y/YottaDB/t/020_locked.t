use strict;
use warnings;

use Test::More;
use YottaDB::Lock;

unless (exists $ENV{TEST_DB}) {
	plan skip_all => 'environment variable TEST_DB not set';
} else {
	plan tests => 2;
        y_locked sub { }, 1, "^a", 1, 2, 3;
        y_locked { } 1, "^a", 1, 2, 3;
	ok (1);

        eval { y_locked { die "simsalabim" } "^a", 1, 2, 3; };
        ok ($@ =~ /simsalabim/);
}
