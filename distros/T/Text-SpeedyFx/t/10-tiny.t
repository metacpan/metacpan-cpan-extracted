#!perl
use strict;
use utf8;
use warnings;

use Test::More;

use Text::SpeedyFx;

my $sfx = Text::SpeedyFx->new(1, 8);
isa_ok($sfx, qw(Text::SpeedyFx));
can_ok($sfx, qw(hash hash_fv hash_min));

my $r = $sfx->hash(q(Hello, World!));
isa_ok($r, q(HASH));

ok(
    @$r{828691033,2983498205} == (1,1),
    q(hello world)
);

done_testing(4);
