#
# make sure v6 is hidden and same in threads.
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
use threads::shared;
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
share(%seen);

my $uu = UUID::uuid6();
ok 1, 'got something';
note $uu;

# 2d2281bc-b455-11ee-8325-5526d7fe9526
is substr($uu, 14, 1), '6', 'its v6';
is substr(unpack("B*", pack("H*", substr($uu, 19, 2))), 0, 2), '10', 'its dce';
is substr(unpack("B*", pack("H*", substr($uu, 24, 2))), 7, 1), '1', 'mcast set';

my $node = substr $uu, 24;
note "parent: $node";
{ lock %seen; ++$seen{$node} }

# all same.
note 'spawning';
threads->create( \&doit, $_ )->join
    for 1..9;

sub doit {
    note "in doit()";
    my ($i) = @_;
    note "generating $i";
    my $ut = UUID::uuid6();
    note "uuid $i: $ut";
    my $n1 = substr $ut, 24;
    note "node $i: $n1";
    lock %seen;
    ok !exists($seen{$n1}), "unique $i";
    ++$seen{$n1};
}

done_testing;
