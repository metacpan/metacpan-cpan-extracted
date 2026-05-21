#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Parity check against Tie::IxHash: random op sequences should
# produce identical Keys / Values output.  Skip if Tie::IxHash isn't
# installed (it's an optional dep of File::Raw::JSON, not core).

BEGIN {
    eval { require Tie::IxHash; 1 }
        or plan skip_all => "Tie::IxHash not installed (parity test optional)";
}

use Tie::OrderedHash;

my $SEED  = 1234567;
my $STEPS = 1000;
my $POOL  = 32;          # key universe size

srand($SEED);

tie my %ix, 'Tie::IxHash';
tie my %oh, 'Tie::OrderedHash';

my @ops;

for my $step (1 .. $STEPS) {
    my $key = 'k' . int(rand $POOL);
    my $op  = int(rand 4);
    if ($op == 0) {
        # store
        my $val = "v$step";
        $ix{$key} = $val;
        $oh{$key} = $val;
        push @ops, ['store', $key, $val];
    }
    elsif ($op == 1) {
        # delete
        my $r1 = delete $ix{$key};
        my $r2 = delete $oh{$key};
        push @ops, ['delete', $key, $r1, $r2];
        # IxHash returns undef for missing; OrderedHash same
        is($r1 // '', $r2 // '', "step $step: delete($key) returns match")
            if defined $r1 || defined $r2;
    }
    elsif ($op == 2) {
        # exists
        my $r1 = exists $ix{$key} ? 1 : 0;
        my $r2 = exists $oh{$key} ? 1 : 0;
        push @ops, ['exists', $key, $r1, $r2];
        if ($r1 != $r2) {
            fail("step $step: exists($key) divergence: $r1 vs $r2");
            last;
        }
    }
    else {
        # fetch
        my $r1 = $ix{$key};
        my $r2 = $oh{$key};
        push @ops, ['fetch', $key, $r1, $r2];
        if (($r1 // '__undef__') ne ($r2 // '__undef__')) {
            fail("step $step: fetch($key) divergence: '$r1' vs '$r2'");
            last;
        }
    }
}

# Final state must match end-to-end.
is_deeply([keys %ix],   [keys %oh],   'final keys: identical to Tie::IxHash');
is_deeply([values %ix], [values %oh], 'final values: identical');
is(scalar keys %ix, scalar keys %oh, 'final count: identical');

done_testing;
