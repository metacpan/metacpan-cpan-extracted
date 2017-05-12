use strict;
use Test::More tests => 56;
use vars qw($Seed);

# Store the seed so we can repeat the test if we fail
BEGIN {
    $Seed = $ENV{TIE_HASH_CANNABINOL_SEED} || rand;
    srand($Seed);
}

END {
    print STDOUT "# Seed was: $Seed\n";
}

BEGIN { use_ok 'Tie::Hash::Cannabinol' }

my $EP = .1; # epsilon

my %hash : Stoned;

my @keys = qw(one two three four);

@hash{@keys} = 1 .. 4;

# keys() not random
{
    my @keys = keys %hash;
    for (1..20) {
        is_deeply [sort keys %hash], [sort @keys];
    }
}

# each(), keys() and values() all produce the same length list
{
    my $each_cnt;
    $each_cnt++ while each %hash;
    is $each_cnt, keys   %hash;
    is $each_cnt, values %hash;
}


# values() always in expected range
for (1..20) {
    no warnings 'uninitialized';
    like join('', values %hash), qr/^[1-4]*$/;
}


# If we forget something, do we remember it again?
TEST: {
    # Forget something...
    1 while defined $hash{3};

    # Try to remember it again.
    for (1..20) {
        if( defined $hash{3} ) {
            pass;
            last TEST;
        }
    }
    fail;
}


# Ensure we're forgetting 25% of the time.
{
    my @values;
    my $iters = 1000;
    push(@values, grep(defined, values %hash)) for 1..$iters;

    cmp_ok( abs( @values - ($iters * keys(%hash) * 3/4) ) / $iters, '<=', $EP);
}


# exists() returns randomly for keys that exist and also don't exist
for my $key (0..5) {
    my $iters = 1000;
    my $exists = 0;
    $exists += exists($hash{$key}) ? 1 : -1 for 1..$iters;

    cmp_ok( abs( $exists/$iters ), '<=', $EP );
}

    
# fetching should be random
{
    my %dist;
    my $iters    = 2000;
    for (1..$iters) {
        no warnings 'uninitialized';
        $dist{$_}++ for values %hash;
    }

    # Values fetched should be evenly distributed except for undef
    for my $k (keys %dist) {
        next unless defined $k;
        cmp_ok( abs( ($dist{$k} - ($iters * 3/4)) / $iters ), '<=', $EP );
    }

    # Should get undef 25% of the time.
    cmp_ok( abs( ($dist{''} - ($iters * keys(%hash) * 1/4)) / $iters ),
            '<=', $EP );
}
