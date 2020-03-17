use strict;
use warnings;

package UniClient;
use Carp;

use Socket
  qw/
        IPPROTO_TCP PF_UNIX PF_INET SOCK_STREAM
        inet_aton pack_sockaddr_in unpack_sockaddr_in pack_sockaddr_un unpack_sockaddr_un/;

sub connect_generic {
    my ($sub, $sock, $paddr) = @_;
    connect($sock, $paddr) or confess "connect: $!";
    my $res = $sub->($sock);
    close($sock) or confess "close: $!";
    return $res;
}

sub connect_remote {
    my ($target, $sub) = @_;
    my $remote  = "localhost";
    confess "No port" unless $target;
    my $iaddr   = (inet_aton($remote) or confess "no host: $remote");
    my $paddr   = pack_sockaddr_in($target, $iaddr);
    socket(my $sock, PF_INET, SOCK_STREAM, IPPROTO_TCP) or confess "socket: $!";
    connect_generic($sub, $sock, $paddr);
}

sub connect_local {
    # my ($target, $source, $sub) = @_;
    # # print STDERR "$target\n";
    # my $paddr = (pack_sockaddr_un($target) or confess "Something wrong with path");
    # socket(my $sock, PF_UNIX, SOCK_STREAM, 0) or confess "socket (local): $!";
    # bind($sock, pack_sockaddr_un($source)) if $source;
    # connect_generic($sub, $sock, $paddr);
}

1;
