#!perl

use 5.006;
use strict;
use warnings;

use IO::Handle;
use POSIX;
use Socket;
use Test::More;
use Test::Exception;

if ('MSWin32' eq $^O) { # man perlport
    plan skip_all => qq(Test is not usable on $^O);
}
elsif ($] < 5.014) {
    plan skip_all => qq(Test doesn't work with perl version prior 5.14);
}

use WebService::IdoitAPI;

$SIG{CHLD} = 'IGNORE';

my $port = 54321;
my $addr = "localhost";

if ( my $pid = fork ) {
    sleep 2;
    do_tests();
    kill SIGKILL, $pid;
}
else {
    echo_server();
}

sub do_tests {
    my $api = WebService::IdoitAPI->new({
            apikey => 'abc',
            url => "https://$addr:$port/api",
        });
    my $request = {
        method => 'idoit.version',
        params => {},
    };
    throws_ok { $api->request($request) } 
        qr/^Connection problem: /,
        "expected to die with connection problem";
    done_testing();
} # do_tests()

sub echo_server {
    socket (SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
    setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
    my $sockaddr = sockaddr_in($port, inet_aton($addr));
    bind(SERVER, $sockaddr)
      or die "can't bind to port $port: $!";
    listen(SERVER, SOMAXCONN)
      or die "cant't listen on port $port: $!";;
    while (accept(CLIENT, SERVER)) {
        CLIENT->autoflush(1);
        print CLIENT "This is only an echo server\n";
        while (my $line = <CLIENT>) {
            print CLIENT $line;
        }
    }
} # echo_server()
