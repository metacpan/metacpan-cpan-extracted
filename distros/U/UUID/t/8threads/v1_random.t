#
# make sure v1 is hidden and same in threads.
#
use strict;
use warnings;
use version 0.77;
use Config;

BEGIN {
    unless ($Config{useithreads}) {
        print "1..0 # SKIP no ithreads\n";
        exit 0;
    }
    my $v = version->parse($Config{version});
    if ($v >= '5.9.5' and $v < '5.10.1') {
        # See note in t/5persist/threads.t.
        print "1..0 # SKIP threads broken in Perl_parser_dup\n";
        exit 0;
    }
    if ($Config{osname} eq 'openbsd' and $Config{osvers} eq '7.0') {
        print "1..0 # SKIP OpenBSD 7.0 threads broken?\n";
        exit 0;
    }
}

use threads;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(:mac=random);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';


my $uu = UUID::uuid1();
ok 1, 'got something';
note $uu;

# 2d2281bc-b455-11ee-8325-5526d7fe9526
is substr($uu, 14, 1), '1', 'its v1';
is substr(unpack("B*", pack("H*", substr($uu, 19, 2))), 0, 2), '10', 'its dce';
is substr(unpack("B*", pack("H*", substr($uu, 24, 2))), 7, 1), '1', 'mcast set';

# all same.
note 'spawning';
threads->create( \&doit, substr($uu, 24), $_ )->join
    for 1..9;

sub doit {
    note "in doit()";
    my ($node, $i) = @_;
    note "generating $i";
    my $ut = UUID::uuid1();
    note "uuid $i: $ut";
    my $n1 = substr $ut, 24;
    note "node $i: $n1";
    is $n1, $node, "same $i";
}

done_testing;
