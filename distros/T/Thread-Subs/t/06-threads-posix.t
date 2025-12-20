#!perl
use 5.014;
use warnings;
BEGIN { eval("use threads::posix") or $::ERR = $@ }
use threads::shared;
use Test::More;
BEGIN {
    unless (threads::posix->can('create')) {
        diag("use threads::posix failed: $::ERR") if $::ERR;
        plan skip_all => "Test requires threads::posix";
    }
}
use Thread::Subs;
use Time::HiRes qw(time);

sub nap { select(undef, undef, undef, $_[0] * 0.01); return @_ }

sub test  :Thread                { &nap }
sub dies  :Thread                { nap(5); die "@_\n" }
sub clim1 :Thread(clim=1)        { &nap }
sub qlim1 :Thread(qlim=1)        { &nap }
sub both  :Thread(clim=1 qlim=1) { &nap }
sub t2t   :Thread                { Thread::Subs::shim(\&test)->(@_)->recv }

{
    package Foo;
    use threads::shared;
    use Thread::Subs;
    sub new { shared_clone(bless []) }
    sub give :Thread(clim=1 pool=PKG) { my $self = shift; push @$self, @_; return $self }
    sub take :Thread(clim=1 pool=PKG) { return shift @{$_[0]} }
}

sub both_slack { Thread::Subs::queue_slack('main::both') }

sub skip_all { plan skip_all => "Abandoning test: @_" }

sub all_idle_ok {
    my $lim = time + 2.0;
    while (time < $lim) {
        return pass("Queues empty and workers idle")
            if Thread::Subs::is_idle();
        nap(1);
    }
    return skip_all("workers taking too long to finish");
}

# Some tests rely on DEFAULT pool having 10 workers
is(scalar(Thread::Subs::startup(10)), 2, "Started two pools");

my $ERR = '';
$SIG{CONT} = do {
    my $sig = $SIG{CONT};
    sub { eval { &$sig }; $ERR .= $@ if $@ }
};
sub do_callbacks { $SIG{CONT}->('CONT') }
my $WARN = '';
$SIG{__WARN__} = sub { $WARN .= "@_" };

my (@r, $x);

@r = map { test($_) } 0..9;
$x = join('-', map { $_->recv } @r);
is($x, '0-1-2-3-4-5-6-7-8-9', "Blocking recv");

&all_idle_ok;

$x = 0;
@r = map { test(9 - $_) } 0..9;
$_->cb(sub { $x++ })
    for @r;
eval { $_->recv for @r };
ok(!$@, "No exceptions");
&do_callbacks;
is($x, 10, "Callbacks");

&all_idle_ok;

ok($x = dies('foo'), "Called sub with exception");
ok(!$x->ready, "Not ready yet");
is($x->data, "foo\n", "Exception string returned");
ok($x->failed, "Has failed");
eval { $x->recv };
ok($@, "Recv raises exception");

&all_idle_ok;

$x = '';
for (2,4,6,8) { test($_) } # other work, untested
for (4,2,3,1) { my $n = $_; clim1($n)->cb(sub { $x .= "s$n" }) } # sequential
for (2,4,6,8) { test($_) } # other work, untested
&all_idle_ok;
&do_callbacks;
is($x, 's4s2s3s1', "Expected order of completion");

cmp_ok(&both_slack, '==', 1, "Not blocked by queue limit");
$x = time + 0.05;
both(5); # should pass
test(2) for 1..4; # other work, untested
both(1); # should pass but remain in queue
cmp_ok(&both_slack, '==', 0, "Queue limit reached");
both(1); # should block until second both() starts
cmp_ok(time, '>', $x, "Blocked by queue limit");

&all_idle_ok;

is($ERR,  '', "No errors");
is($WARN, '', "No warnings");
dies("void");
$x = dies("scalar");
&all_idle_ok;
&do_callbacks;
like($ERR, qr/void$/, "Void context exception produces exception");
$ERR = '';
$x->fatal;
&do_callbacks;
like($ERR, qr/scalar$/, "Fatal method produces exception");
$x->warn;
&do_callbacks;
like($WARN, qr/scalar$/, "Warn method produces warning");

eval { Thread::Subs::shim(\&nap) };
ok($@, "Exception raised on attempt to shim non-thread sub");

do {
    $x = 0;
    my $t = time + 5.0;
    local $SIG{USR1} = sub { test(2)->cb(sub { $x++ }) };
    for (1..5) {
        test(2)->cb(sub { $x++ });
        kill USR1 => $$;
    }
    nap(2) until $x == 10 or time > $t;
    is($x, 10, "Called from signal");
};

do {
    $x = 0;
    test(2 * $_) for 1..4; # other work, untested
    test(2)->cb(sub { test(2)->cb(sub { test(2)->cb(sub { $x = 1 }) }) });
    test(2 * $_) for 1..4; # other work, untested
    local $SIG{ALRM} = sub { $x ||= -1 };
    alarm 5;
    nap(2) until $x;
    alarm 0;
    is($x, 1, "Called from callback");
};

is(t2t(2)->recv, 2, "Thread to thread");

$x = Foo->new;
$x->give(111,222,333);
is_deeply([map { $x->take->recv } (1,2,3)], [111,222,333], "Threaded object works");

$x = time;
test(2);
ok(eval { Thread::Subs::stop_and_wait(); 1 }, "Stop workers");
diag($@) if $@;
cmp_ok(time - $x, '>=', 0.02, "Waited for worker");

eval { test(1) };
ok($@, "Exception raised when shim called afer shutdown");

is_deeply([Thread::Subs::running_workers()], [], "All workers stopped");
done_testing();
