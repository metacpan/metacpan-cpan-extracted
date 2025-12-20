#!perl
use 5.014;
use warnings;
use threads;
use threads::shared;
use Test::More;
use Thread::Subs;
use Time::HiRes qw(time);

BEGIN {
    plan skip_all => "Test requires Mojo::Promise"
        unless eval "use Mojo::Promise; 1";
}

sub nap { select(undef, undef, undef, $_[0] * 0.01); return @_ }

sub test :Thread { &nap }
sub dies :Thread { nap(5); die "@_\n" }

Thread::Subs::startup(5);

test(1)->mojo_promise->then(
    sub { is_deeply([@_], [1], "Promise resolved") },
    sub { fail("Promise resolved") },
    )->wait;

dies('DOOMED')->mojo_promise->then(
    sub { fail("Promise rejected") },
    sub { like("@_", qr/DOOMED/, "Promise rejected") },
    )->wait;

my $x = '';
my $p = Mojo::Promise->all(
    map {
        my $n = $_;
        test($n)->mojo_promise->then(sub { $x .= $n })
    } (1,5,3,7)
    );
$p->ioloop->recurring(0.02 => sub { $x .= '~' });
$p->wait;
# Most likely result is "~1~3~5~7", but no guarantee
cmp_ok($x =~ tr/~//d, '>', 1, "Timer ran");
like($x, qr/^[1357]{4}$/, "Callbacks executed");

done_testing();
