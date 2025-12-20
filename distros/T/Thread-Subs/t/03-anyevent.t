#!perl
use 5.014;
use warnings;
use threads;
use threads::shared;
use Test::More;
use Thread::Subs;
use Time::HiRes qw(time);

BEGIN {
    plan skip_all => "Test requires AnyEvent"
        unless eval "use AnyEvent; 1";
}

sub nap { select(undef, undef, undef, $_[0] * 0.01); return @_ }

sub test :Thread { &nap }
sub dies :Thread { nap(5); die "@_\n" }

my $x;
is(scalar(Thread::Subs::startup(5)), 1, "One worker pool started");

# Limit delay if AnyEvent::Loop hits its race condition.
my $wakeup = AE::timer 1, 1, sub { };

AE::postpone { $x = 'post' };
is($x, undef, "Postponed op has not executed");
test(5)->ae_cv->recv;
is($x, 'post', "Postponed op ran while waiting");

$x = '';
my $t = AE::timer 0, 0.02, sub { $x .= '~' };
my @cv;
for my $n (1, 5, 3, 7) {
    my $cv = test($n)->ae_cv;
    $cv->cb(sub{ $x .= $n });
    push @cv, $cv;
}
shift(@cv)->recv while @cv;
undef $t;
# Most likely result is "~1~3~5~7", but no guarantee.
cmp_ok($x =~ tr/~//d, '>', 1, "Timer ran");
like($x, qr/^[1357]{4}$/, "Callbacks executed");

my @v = test(1,2,3,4)->ae_cv->recv;
is_deeply(\@v, [1,2,3,4], "Returned list is correct");

eval { dies('DOOMED')->ae_cv->recv };
like($@, qr/DOOMED/, "Exceptions handled correctly");

done_testing();
