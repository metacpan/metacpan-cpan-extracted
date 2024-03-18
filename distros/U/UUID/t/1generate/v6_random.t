#
# make sure v6 mac is hidden and same.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(:mac=random);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';


my $uu = UUID::uuid6();
ok 1, 'got something';
note $uu;

# 2d2281bc-b455-11ee-8325-5526d7fe9526
is substr($uu, 14, 1), '6', 'its v6';
is substr(unpack("B*", pack("H*", substr($uu, 19, 2))), 0, 2), '10', 'its dce';
is substr(unpack("B*", pack("H*", substr($uu, 24, 2))), 7, 1), '1', 'mcast set';

# all same.
for (1..9) {
    my $ut = UUID::uuid6();
    my $n1 = substr $uu, 24;
    my $n2 = substr $ut, 24;
    is $n2, $n1, "same $_";
}

done_testing;
