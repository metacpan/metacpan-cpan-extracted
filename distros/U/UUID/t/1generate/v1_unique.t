#
# make sure v1 mac is hidden and same.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(:mac=unique);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';


my %seen = ();

my $uu = UUID::uuid1();
ok 1, 'got something';
note $uu;

# 2d2281bc-b455-11ee-8325-5526d7fe9526
is substr($uu, 14, 1), '1', 'its v1';
is substr(unpack("B*", pack("H*", substr($uu, 19, 2))), 0, 2), '10', 'its dce';
is substr(unpack("B*", pack("H*", substr($uu, 24, 2))), 7, 1), '1', 'mcast set';

my $node = substr $uu, 24;
++$seen{$node};

# all different.
doit($_)
    for 1..9;

sub doit {
    my ($i) = @_;
    ok 1, "doit $_";
    my $ut = UUID::uuid1();
    my $n  = substr $ut, 24;
    note $n;
    ok !exists($seen{$n}), "unique $i";
    ++$seen{$n};
}

done_testing;
