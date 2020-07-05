use 5.012;
use UniEvent;
use Time::HiRes qw/time/;
use Panda::Lib;

my $loop = UE::Loop->default_loop;
my $r = UE::Resolver->new($loop, {
    #query_timeout => 1,
    workers => 1,
});

our $active = 1000000;
our $counter = 0;
our $errcnt = 0;
our $start = time;
our $resp = {
    node       => 'ya.ru',
    service    => 80,
    use_cache  => 1,
    timeout    => 100,
    on_resolve => sub {
        my (undef, $err, $req) = @_;
        $counter++;
        $errcnt++ if $err;
    },
};

my $timer = UE::Timer->new($loop);
$timer->callback(sub {
    warn sprintf("counter = $counter, err = $errcnt, queue = %s, time = %0.2f\n", $r->queue_size, time - $start);
    $counter = 0;
    $errcnt = 0;
    $start = time;
});
$timer->start(1);

my $timer2 = UE::Timer->new($loop);
$timer2->callback(sub {
    #if ($active == 0) { $active = 1; }
    #elsif ($active == 1) { $active = 1000000; }
    #else { $active += 1000; }
    $active += 10000;
    warn "injected, total = $active";
    for (my $i = 0; $i < $active; ++$i) {
        send_next();
    }
});
$timer2->start(2);
$timer2->call_now;

$loop->run;

sub send_next {
    $r->resolve($resp);
}
