#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'idi';

my $s = get_score();

b(100);
is_deeply [$s->Score]->[-1], ['set_tempo', 0, 600000], 'b';

is $s->Channel, 0, 'c';
c(1);
is $s->Channel, 1, 'c';

is $s->Duration, 96, 'd';
d(32);
is $s->Duration, 32, 'd';

n(qw(qn C));
is_deeply [$s->Score]->[-1], ['note', 0, 96, 1, 60, 64], 'n';

r('qn');

n(qw(qn C));
is_deeply [$s->Score]->[-1], ['note', 96 * 2, 96, 1, 60, 64], 'n';

is $s->Octave, 5, 'o';
o(0);
is $s->Octave, 0, 'o';

p(qw(2 42));
is_deeply [$s->Score]->[-1], ['patch_change', 96 * 3, 2, 42], 'p';

t('3/4');
is_deeply [$s->Score]->[-1], ['time_signature', 96 * 3, 3, 2, 18, 8], 't';

is $s->Volume, 64, 'v';
v(127);
is $s->Volume, 127, 'v';

w();
ok -e 'idi.mid', 'w';

x('c2');
is $s->Channel, 2, 'x';

#use Data::Dumper::Compact qw(ddc);
#warn __PACKAGE__,' L',__LINE__,' ',ddc($s);

done_testing();
