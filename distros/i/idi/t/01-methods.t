#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'idi';

my $TICKS = 96;

my $s = g();
isa_ok $s, 'MIDI::Simple';

diag 'Turn off "play-on-end"';
e(0);

subtest b => sub {
  b(100);
  is_deeply [$s->Score]->[-1], ['set_tempo', 0, 600000], 'b';
};

subtest c => sub {
  is $s->Channel, 0, 'c';
  c(1);
  is $s->Channel, 1, 'c';
};

subtest c => sub {
  is $s->Duration, $TICKS, 'd';
  d(32);
  is $s->Duration, 32, 'd';
};

subtest n => sub {
  n(qw(qn C));
  is_deeply [$s->Score]->[-1], ['note', 0, $TICKS, 1, 60, 64], 'n';
  n([qw(qn C)]);
  is_deeply [$s->Score]->[-1], ['note', $TICKS, 96, 1, 60, 64], 'n';
  n([qw(qn C)], [qw(wn Cs)]);
  is_deeply [$s->Score]->[-1], ['note', $TICKS * 3, 384, 1, 61, 64], 'n';
};

r('qn'); # add a rest to the score

subtest n => sub {
  n(qw(qn C));
  is_deeply [$s->Score]->[-1], ['note', $TICKS * 8, 96, 1, 60, 64], 'n';
};

subtest o => sub {
  is $s->Octave, 5, 'o';
  o(0);
  is $s->Octave, 0, 'o';
};

subtest p => sub {
  p(qw(2 42));
  is_deeply [$s->Score]->[-1], ['patch_change', $TICKS * 9, 2, 42], 'p';
};

subtest t => sub {
  t('3/4');
  is_deeply [$s->Score]->[-1], ['time_signature', $TICKS * 9, 3, 2, 18, 8], 't';
  t('6/8');
  is_deeply [$s->Score]->[-1], ['time_signature', $TICKS * 9, 6, 3, 24, 8], 't';
};

subtest v => sub {
  is $s->Volume, 64, 'v';
  v(127);
  is $s->Volume, 127, 'v';
};

subtest w => sub {
  w();
  my @got = glob 'idi*.mid';
  like $got[0], qr/^idi-.{4}\.mid$/, 'w';
  w('idi.mid');
  ok -e 'idi.mid', 'w';
  unlink 'idi.mid';
};

subtest x => sub {
  x('c2');
  is $s->Channel, 2, 'x';
};

subtest u => sub {
  my $x = u(2, ['1010'], ['0101'], ['1111']);
  is @{$x->{Score}}, 21, 'u';
  is $x->{Score}[-1][3], 9, 'channel';
};

#use Data::Dumper::Compact qw(ddc);
#warn __PACKAGE__,' L',__LINE__,' ',ddc($s);

done_testing();
