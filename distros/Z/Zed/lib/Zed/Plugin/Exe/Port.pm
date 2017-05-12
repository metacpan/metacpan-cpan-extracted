package Zed::Plugin::Exe::Port;

use Zed::Plugin;
use Zed::Output;
use Zed::Config::Env;
use Zed::Config::Space;

use AnyEvent;
use AnyEvent::Socket;

use strict;
use warnings;

use constant MAX_CONN => 20;
use constant TIMEOUT  => 5;

=head1 SYNOPSIS

    port PORT 
    ex:
        port 22

=cut

invoke "port" => sub {
    my ( $port, $cv, @host) = shift;
    debug("port: $port");
    return unless @host = targets();

    $cv = AE::cv;

    my($all, @suc, @fail, $sub, $count) = scalar @host;

    $sub = sub
    {
        return unless my $host = shift @host;
        $cv->begin;
        tcp_connect $host, $port, sub {
            $count += 1;
            if( shift )
            {
               push @suc,  $host;
               result("$count/$all", 1, "$host port $port open..");
            }else{
               push @fail, $host;
               result("$count/$all", 0, "$host port $port close..");
            }
            $cv->end;
            $sub->();
        },sub{ TIMEOUT };
    };

    $sub->() for 1..MAX_CONN;
    $cv->recv;

    (\@suc, \@fail);
};

1;
