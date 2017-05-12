package Vayne::Socks;

use Carp;

use Coro;
use Coro::Socket;

use Log::Log4perl qw(:easy);
use List::Util qw(first shuffle);

use Data::Dumper;
use Data::Printer;

use Vayne;
use constant CONF=>'socks';

my %ERROR =
(
    0 => "request granted",
    1 => "general failure",
    2 => "connection not allowed by ruleset",
    3 => "network unreachable",
    4 => "host unreachable",
    5 => "connection refused by destination host",
    6 => "TTL expired",
    7 => "command not supported / protocol error",
    8 => "address type not supported",
);

sub connect
{
    my ($socket, $err) = eval{ _connect(@_) };
    if($@)
    {
        $@ =~ s/ ?at .*//g;
        $err = $@;
    }elsif($!){
        $err = $!;
    }
    return $socket, $err;
}
my %SOCKS; 

sub load
{
    TRACE "load socks file"; 
    my $sock = Vayne->conf( CONF ) or WARN "socks conf not found";
    %SOCKS = %$sock if $sock && ref $sock eq 'HASH';
    TRACE Dumper \%SOCKS;
}

load();

#reload interval
async { while(1){ load(); Coro::AnyEvent::sleep 10}};

sub _connect
{
    my($host, $port, $timeout, $reg, $ser) = splice @_, 0, 3;
    TRACE "connect $host $port";
    TRACE Dumper \%SOCKS;

    my $find  = first { $host =~ /$_/ } keys %SOCKS;
    TRACE "find socks: $find $SOCKS{$find}";
    my ($phost, $pport) =  $SOCKS{$find} =~ /^(.+):(\d+)$/;
    TRACE "$phost, $pport";

    if(
        %SOCKS
        and $reg = first { $host =~ /$_/ } keys %SOCKS
        and $ser = ref $SOCKS{$reg} ? shuffle @{ $SOCKS{$reg} } : $SOCKS{$reg}
        and my ($phost, $pport) =  $ser =~ /^(.+):(\d+)$/
    )
    {
        DEBUG "proxy: $phost, port: $pport";


        my($socket, $buf) = new Coro::Socket( PeerHost => $phost, PeerPort => $pport, Timeout => $timeout );
        croak "connect socks server($phost\:$pport) failed: $!" if $!;

        $socket->syswrite( pack("CCC", 5, 1, 0) );

        $socket->sysread($buf, 2);

        my($ver, $method, $cmd) = unpack "CC", $buf;
        DEBUG "ver:$ver, method:$method";

        croak "negotiate socks server($phost\:$pport) failed" and return unless $ver == 5 && $method == 0;

        $cmd .= pack("CCCC", 5, 1, 0, 3);
        $cmd .= pack("C", length $host);
        $cmd .= $host;
        $cmd .= pack("n", $port);

        DEBUG "$host|$port";
        $socket->syswrite($cmd);
        DEBUG "readable:", $socket->readable;
        $socket->sysread($buf, 10);

        my($version, $reply, $rsv, $atyp, $ip, $port) = unpack "CCCCa4n", $buf;
        DEBUG "ver: $version, reply: $reply, atyp: $atyp, ip: $ip, port: $port";

        croak "socks proxy error($ERROR{$reply})" unless $ver == 5 && $reply == 0 && $atyp == 1;

        $socket;

    }else
    {
        new Coro::Socket( PeerHost => $host, PeerPort => $port, Timeout => $timeout );
    }
}


1;
__END__
