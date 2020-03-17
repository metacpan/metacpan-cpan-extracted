use strict;
use lib 't';
package SingleClientServer;

use Socket qw/INADDR_ANY SOMAXCONN PF_INET PF_UNIX SOCK_STREAM IPPROTO_TCP sockaddr_in
	     sockaddr_un/;
use Binder;

sub run {
    close STDOUT;

    my ($server, $sub) = @_;

    accept(my $client, $server);
    close $server;

    $sub->($client);

    close $client;
}

sub run_local {
    my ($sub, $path) = @_;
    socket(my $server, PF_UNIX, SOCK_STREAM, 0) || die "socket: $!";
    # print STDERR "$path\n";
    # print STDERR `ls t`;
    my $uaddr = sockaddr_un($path);
    die "sockaddr_un: $!" unless $uaddr;
    bind($server, $uaddr) || die "bind: $!";
    listen($server, SOMAXCONN) || die "listen: $!";
    return run($server, $sub)
}

sub run_remote {
    my $sub = $_[0];
    socket(my $server, PF_INET, SOCK_STREAM, IPPROTO_TCP) || die "socket: $!";
    my $port = Binder::bind2free(Binder::make_perl_bound_socket(
	$server, sub { die $! unless listen $_[0], 1 }
       ));
    syswrite STDOUT, $port;
    return run($server, $sub);
}

1;
