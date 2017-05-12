# -*- Mode: Perl -*-

package Legs;
sub run { "running" };
sub walk { "walking" };
use mcoder new => 'new';

package Man;

use mcoder::proxy legs => qw(run walk);
use mcoder::get qw(legs arms fast good);
use mcoder::set qw(legs arms);
use mcoder::bool::set qw(fast good);
use mcoder::bool::unset qw(fast good);
use mcoder new => 'new';
use mcoder::array::get qw(sons);
use mcoder::array::set qw(sons);

package testing;

use Test::More tests => 11;

my $l;
ok ($l=Legs->new(), "new legs");

my $m;
ok ($m=Man->new(), "new man");

$m->set_legs($l);
is($l, $m->legs, "man legs");

is($m->run, "running", "running");

is($m->walk, "walking", "walking");

$m->set_fast;
ok($m->fast, "fast");

$m->unset_fast;
ok(!$m->fast, "slow");

$m->set_good(4);
ok($m->good, "good");

$m->set_good(0);
ok(!$m->good, "bad");

is_deeply([$m->sons], [], 'undefined sons');

my @sons=qw(foo bar son1 pepe);
$m->set_sons(@sons);
is_deeply([$m->sons], \@sons, 'sons')
