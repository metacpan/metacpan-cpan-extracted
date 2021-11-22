#!/usr/bin/env perl
use 5.020;
use warnings;
use UniEvent::HTTP;
use XLog;
use Socket;

XLog::set_logger(sub { say $_[0] });
XLog::set_level(XLog::VERBOSE_DEBUG());

#my $t = UE::Tcp->new;
#$t->open($sock);
#$t->listen(128);
#
#$t->connection_callback(sub {
#    my (undef, $cli, $err) = @_;
#    die $err if $err;
#    $cli->read_callback(sub {
#        my (undef, $data, $err) = @_;
#        say "READ: $data";
#        $cli;
#    });
#});
#
#UE::Loop->default_loop->run;
#
#exit();

my $server = UniEvent::HTTP::Server->new({
    locations => [{path => "tmpsock"}],
});

$server->request_callback(sub {
    my $req = shift;
    say "REQUEST. URI = ".$req->uri;
    $req->respond({code => 200, body => "fuck you"});
});

$server->run;

UE::Loop->default_loop->run;
