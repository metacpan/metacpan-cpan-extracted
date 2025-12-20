#!perl
use 5.014;
use warnings;
use threads;
use Digest::MD5 qw(md5_hex);
use POSIX qw(pause);
use Test::More;
use Thread::Subs;
use Time::HiRes qw(alarm);

# Multiple submitters (client pool) hammer a qlim-and-clim-constrained
# sub (server pool).  Exercises all the limiters under contention.
# Actively interrupted by alarm() and callbacks.

my $SUBMITTERS      = $ENV{STRESS_SUBMITTERS}      // 10;
my $WORKERS         = $ENV{STRESS_WORKERS}         // 6;
my $REQUESTS_EACH   = $ENV{STRESS_REQUESTS_EACH}   // 100;

sub find_partial_md5 :Thread(pool=server, qlim=20) {
    my ($string, $target) = @_;
    my $x = 0;
    ++$x until substr(md5_hex("$string $x"), 0, length($target)) eq $target;
    return "$string $x";
}

sub submitter :Thread(pool=client) {
    state $worker = Thread::Subs::shim(\&find_partial_md5);
    my ($id) = @_;
    my @work = map { $worker->("test-$id-$_", '000') } 1..$REQUESTS_EACH;
    my $passed = 0;
    for (@work) { $passed++ if md5_hex($_->recv) =~ /^000/ }
    return $passed;
}

Thread::Subs::define(\&find_partial_md5, clim => $WORKERS - 1);
my %pool = Thread::Subs::startup(
    client => $SUBMITTERS,
    server => $WORKERS, # one will be idle
    );
is($pool{client}, $SUBMITTERS, "$SUBMITTERS submitters");
is($pool{server}, $WORKERS, "$WORKERS workers");

$SIG{ALRM} = sub {
    note "Queue: ".join(' ',Thread::Subs::queue_slack());
    alarm(0.1);
};
$SIG{ALRM}->();
my $total = 0;
my $results = 0;
my @test;
for my $n (1..$SUBMITTERS) {
    my $cb = sub { $results++; note "Submitter #$n returned ".$_[0]->recv };
    push @test, submitter($n)->cb($cb);
}
pause until $results == $SUBMITTERS;
alarm(0);

$total += $_->recv for @test;
my $expected = $SUBMITTERS * $REQUESTS_EACH;
is($total, $expected, "All $expected results correct");
Thread::Subs::stop_and_wait();
done_testing();
