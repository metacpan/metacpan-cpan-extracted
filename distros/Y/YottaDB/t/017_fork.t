use strict;
use warnings;

use Test::More;
use YottaDB qw/:all/;

unless (exists $ENV{TEST_DB}) {
	plan skip_all => 'environment variable TEST_DB not set';
} else {
	plan tests => 2;

	y_set "^tmp002", 4141;
	my $pid = fork(); # ydb_child_init is called by at_fork handlers
	if (!defined $pid) {
	    warn "fork failed.";
	    ok (0);
	} elsif ($pid) {
	    # parent
	    waitpid $pid, 0;
	    ok (1);
	} else {
	    # child
	    y_set "^tmp002" => 4242;
	    exit (0);
	}
	ok (4242 == y_get "^tmp002");
	y_kill_tree "^tmp002";
}
