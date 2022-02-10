#!/usr/local/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch', 't';
use Benchmark qw/timethis timethese/;
use Time::HiRes;
use UniEvent::WebSocket;

say "START $$";

my $loop = new UE::Loop;

my $cfg = {
    locations => [
        {host => '127.0.0.1', port => 4680},
        {host => '127.0.0.1', port => 4681, secure => 1},
    ],
};
my $server = UniEvent::WebSocket::Server->new($cfg);
#$server->configure($cfg);
$server->connection_event->add(sub {
    my ($serv, $conn) = @_;
    say "connection_event";


    $conn->accept_event->add(sub {
        my $conn = shift;
        say "accept_event";
        $conn->send_text('Hello');
        $conn->message_event->add(sub {
            my ($conn, $msg) = @_;
            say "on_message: ", $msg->payload_length, " : ", $msg->payload;
        });
    });

    #bless $conn, 'MyConnection';
    #say "connection cb";
});

$server->loop;

$server->run;

#my $t = new UE::Timer($f->loop);
#$t->callback(sub {
#    $f->stop;
#    $t->stop;
#});
##$t->start(2);

say "entering loop";
$server->loop->run;
say "loop finished";

1;
