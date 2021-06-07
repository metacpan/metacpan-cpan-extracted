use 5.012;
use warnings;

use lib 't/lib';
use IPCToken;
use UniEvent::HTTP::Manager;
use Test::More;

my $t = IPCToken->new(2);
my $l = UE::Loop->default;

my $root = $$;
note "root = $root";

my $pid = fork;
if ($pid) {
    sleep 1;
    note "going to kill $pid";
    kill 9, $pid;
    is waitpid($pid, 0), $pid;
    my $err = $t->await(2);
    is $err, undef, "spawn_callback works in child process";
}
else {
    my $mgr = UniEvent::HTTP::Manager->new({
        worker_model => UniEvent::HTTP::Manager::WORKER_PREFORK,
        min_servers  => 1,
        max_servers  => 1,
        server       => { locations => [{host => '127.0.0.1', port => 0}], },
    }, $l);
    $mgr->start_callback(sub {
        note "start_callback, $$";
        $t->dec;
    });
    $mgr->spawn_callback(sub {
        note "spawn_callback, $$";
        my $server = shift;
        $server->stop_callback(sub {
            note "stop_callback, $$";
            $t->dec
        });
    });
    $mgr->run;
}

done_testing;
