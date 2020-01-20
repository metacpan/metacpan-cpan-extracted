use strict;
use warnings;

use Test::More;
use YottaDB qw/:all/;

unless (exists $ENV{TEST_DB}) {
	plan skip_all => 'environment variable TEST_DB not set';
} else {
	plan tests => 9;

	#
	# try transaction restart.
	# on restart "x" is restored but "y" not.
	#
	y_set x => 1;
	y_set y => 1;

	y_trans (sub {
        	        my $x = y_incr "x", 1;
                        my $y = y_incr "y", 1;
			my $round = y_get '$TRESTART';

			if (!$round) {
				ok ($x == $y); # at first x=2 y=2
				return y_tp_restart;
			} else {
				ok ($x < $y);  # 2nd round: x=2 y=3
			}
                       	y_ok;
                     },
		"BATCH",
		"x"
	);

	#
	# nested transactions
	#
	y_trans (sub {
			ok (1 == y_get '$TLEVEL');
			y_trans (sub {
					ok (2 == y_get '$TLEVEL');
					y_ok;
			         },
			         "BATCH"
			);
			ok (1 == y_get '$TLEVEL');
			y_ok;
		},
		"BATCH"
	);

	#
	# trying rollback..
	#
	my $glb = '^tmp001';
	y_set $glb, 1, 2, 3 => 42;
	my $rc = y_trans {
			    y_kill_tree $glb;
			    ok (0 == y_data $glb);
			    y_tp_rollback;
		 } "BATCH";
	ok (10 == y_data $glb);
	ok (42 == y_get $glb, 1, 2, 3);		
	y_kill_tree $glb;
	ok (0 == y_data $glb);

}
