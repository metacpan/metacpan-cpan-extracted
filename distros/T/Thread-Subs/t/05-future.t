#!perl
use 5.014;
use warnings;
use threads;
use threads::shared;
use Test::More;
use Thread::Subs;
use Time::HiRes qw(time);

BEGIN {
    plan skip_all => "Test requires Future"
        unless eval "use Future; 1";
}

sub nap { select(undef, undef, undef, $_[0] * 0.01); return @_ }

sub test :Thread { &nap }
sub dies :Thread { nap(5); die "@_\n" }

my ($f, $x);
Thread::Subs::startup(5);

$x = test(2);
$f = $x->future;
ok(!$f->is_ready, "Not ready yet");
$x->data; # block
$x->run_callback_queue; # force callback
ok($f->is_ready, "Ready now");
is($f->get, 2, "Future resolved as expected");

$f = dies('KABOOM')->future;
ok(!$f->is_ready, "Not ready yet");
nap(1) until $f->is_ready;
eval { $f->get };
like($@, qr/KABOOM/, "Future dies as expected");
ok($f->is_failed, "Future is failed");

$x = '';
my @fut = map {
    test($_)->future->on_done(sub { $x .= "<@_>" });
} (1,5,3,7,4);
$fut[-1]->cancel;
Thread::Subs::stop_and_wait();
# Most likely result is '<1><3><5><7>', but order not guaranteed
like($x, qr/^(?:<[1357]>){4}$/, "Futures executed and canceled correctly");

done_testing();
