use 5.012;
use warnings;

use lib 't/lib';
use IPCToken;
use UniEvent::HTTP::Manager;
use Test::More;

my $t = IPCToken->new(1);
my $l = UE::Loop->default;

my $root = $$;
my $mgr = UniEvent::HTTP::Manager->new({
    worker_model => UniEvent::HTTP::Manager::WORKER_PREFORK,
    bind_model   => UniEvent::HTTP::Manager::BIND_DUPLICATE,
    min_servers  => 1,
    max_servers  => 1,
    server       => { locations => [{host => '127.0.0.1', port => 0}], },
}, $l);

$mgr->request_callback(sub {
    my $req = shift;
    $req->respond({
        code => 200,
        body => "ok",
    });
});

$mgr->spawn_callback(sub {
    my $server = shift;
    note "spawn_callback, $$";
    $server->run_callback(sub {
        my $port = $server->listeners->[0]->sockaddr->port;
        note "run_callback, $$, port = $port";

        my $h = UE::Timer->new($server->loop);
        $h->callback(sub {
            my $ua = UniEvent::HTTP::UserAgent->new({}, $server->loop);
            my $uri = "http://127.0.0.1:$port/";
            note "requesting $uri, $$";
            my $req = UniEvent::HTTP::Request->new({ uri  => $uri });
            $req->response_event->add(sub {
                my (undef, $res, $err) = @_;
                note "response_event, $$, code = ", $res->code;
                $t->dec if $res->code == 200;
                POSIX::_exit(0);
                undef $h;
            });
            $ua->request($req);
        });
        $h->once(0.02);
    });
});


my $tm = UE::Timer->new($mgr->loop);
$tm->callback(sub {
    note "timer_callback, $$";
    return unless $$ eq $root;
    my $err = $t->await(2);
    is $err, undef, "spawn_callback works in child process";
    $mgr->stop;
});
$tm->once(0.01);
$mgr->run;

done_testing;
