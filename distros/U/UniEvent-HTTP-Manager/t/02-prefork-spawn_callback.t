use 5.012;
use warnings;

use lib 't/lib';
use IPCToken;
use UniEvent::HTTP::Manager;
use Test::More;

my $t = IPCToken->new(1);
my $l = UE::Loop->default;

my $mgr = UniEvent::HTTP::Manager->new({
    worker_model => UniEvent::HTTP::Manager::WORKER_PREFORK,
    min_servers  => 1,
    max_servers  => 1,
    server       => { locations => [{host => '127.0.0.1', port => 0}], },
}, $l);
$mgr->spawn_callback(sub {
    note "spawn_callback, $$";
    my $server = shift;
    $t->dec;
    POSIX::_exit(0);
});

my $h = UniEvent::Idle->new($l);
$h->event->add(sub {
    note "idle_callback, $$";
    my $err = $t->await(2);
    is $err, undef, "spawn_callback works in child process";
    $mgr->stop;
});
$h->start;
$mgr->run;

done_testing;
