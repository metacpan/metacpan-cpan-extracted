use strict;
use warnings;

use Test::More;
use YottaDB qw/:all/;

unless (exists $ENV{TEST_DB}) {
	plan skip_all => 'environment variable TEST_DB not set';
} else {
	plan tests => 1;

        y_lock 0, [ "^tmp", 1, 2, 3],
                  [ "^schufa", 1, 2, 3, 4, 5, 6, 7, 8 ],
                  [ "^full" ];

        pipe my $RD, my $WD;
        my $pid = fork;
        die unless defined $pid;

        if ($pid) {
                close $WD;
                waitpid $pid, 0;
        } else {
                close $RD;
                my $ok = 0;
            y_lock 0, ["^tmp",1] or ++$ok;
            y_lock 0, ["^free"]  and ++$ok;
            syswrite $WD, $ok==2, 1;
            exit (0);
        }
	sysread $RD, my $s, 1 or die;
	ok (1 == $s);
}
