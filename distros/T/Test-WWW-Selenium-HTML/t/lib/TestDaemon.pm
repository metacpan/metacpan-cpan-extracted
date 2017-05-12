package TestDaemon;

use warnings;
use strict;

use HTTP::Daemon;
use HTTP::Status;
use IO::Socket::INET;

sub selenium_server_exists
{
    return IO::Socket::INET->new(PeerAddr => 'localhost',
                                 PeerPort => 4444,
                                 Proto    => 'tcp') ? 1 : 0;
}

sub get_port
{
    my $port = 1024 + $$;
    
    while (IO::Socket::INET->new(PeerAddr => 'localhost',
                                 PeerPort => $port,
                                 Proto    => 'tcp')) {
        $port++;
    }
    
    return $port;
}

sub start
{
    my ($port) = @_;        

    my $d = HTTP::Daemon->new(LocalPort => $port)
        or die "Unable to start HTTP::Daemon.";

    my @pids;
    while (my $c = $d->accept()) {
        if (my $pid = fork()) {
            push @pids, $pid;
        } 
        else {
            while (my $r = $c->get_request()) {
                my $path = $r->uri()->path();
                my $real_path = "./t/html$path";
                if ($path =~ /shutdown.html$/) {
                    $c->send_response(RC_OK);
                    last;
                }
                elsif ($path eq '/') {
                    $c->send_file_response('./t/html/simple.html');
                }
                elsif (not -e $real_path) {
                    $c->send_error(RC_NOT_FOUND);
                }
                else {
                    $c->send_file_response($real_path);
                }

                if ($r->header('Connection') =~ /close/) {
                    last;
                }
            }
            $c->close();
            undef $c;
            exit(0);
        }
    }

    return 1;
}

1;
