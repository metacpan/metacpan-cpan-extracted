#!perl
use strict;
use utf8;
use warnings;

use Test::More;

use Text::SpeedyFx;

my $fv = Text::SpeedyFx::Result->new;
isa_ok($fv, q(HASH));
like(tied %$fv, qr(^Text::SpeedyFx::Result=SCALAR\b)x, q(tied));
like(scalar %$fv, qr(^0/[0-9]+$), q(SCALAR context: ) . scalar %$fv);

my %hash;
while (<DATA>) {
    chomp;
    my ($key, $val) = split /\t/x;
    $hash{$key} = $val;
    $fv->{$key} = $val;
}

is_deeply(\%hash, $fv, q(trie match hash));

is($fv->{2535669352}, 1868568026, q(FETCH));
is($fv->{9876543210}, undef, q(FETCH miss));
is(delete $fv->{1198795427}, 1321107448, q(DELETE));
is(delete $fv->{1234567890}, undef, q(DELETE miss));
ok(exists $fv->{670278006}, q(EXISTS));
my $flag = not exists $fv->{1198795427};
ok($flag, q(not EXISTS));

is((each %$fv)[0], 89612897, q(lowest key is the first));

# croaks with:
# Assertion failed: (head->triebins[bitidx]==r), function sfxaa_tree_s_NEDTRIE_NEXT, file SpeedyFx.xs, line 35.
#is(delete $fv->{89612897}, 61333046, q(DELETE lowest key));
#is((each %$fv)[0], 391754347, q(now, second lowest key is the first));

%$fv = ();
is(scalar keys %$fv, 0, q(CLEAR));

@{$fv}{keys %hash} = values %hash;
is_deeply(\%hash, $fv, q(trie match hash, again));

undef $fv;
is($fv, undef, q(DESTROY));

done_testing(14);

__DATA__
546742292	2255718447
522490336	386028540
2535669352	1868568026
3512077234	4293520797
2900433233	3379613537
1846263179	2174164644
1198795427	1321107448
89612897	61333046
1156338747	2294651930
2693563844	2678611216
391754347	1225844449
913722147	4159236363
2836997650	999092185
670278006	2764255123
3580574881	2592003771
2736404182	285509046
3794340040	2034651595
1276889442	3013957536
3270397091	3122233786
2969347637	2711370095
