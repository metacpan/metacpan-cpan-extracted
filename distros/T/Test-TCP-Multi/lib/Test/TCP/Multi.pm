package Test::TCP::Multi;
use strict;
use base qw(Exporter);
use Config;
use IO::Handle;
use IO::Socket::INET;
use Test::SharedFork;
use Test::More ();
use POSIX ();
use Storable qw(nstore_fd fd_retrieve);
use Time::HiRes();

our $VERSION = '0.00004';
our @EXPORT = qw( empty_port test_multi_tcp wait_port kill_proc );

# process does not die when received SIGTERM, on win32.
my $TERMSIG = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

sub empty_port {
    my $port = shift || 10000;
    $port = 19000 unless $port =~ /^[0-9]+$/ && $port < 19000;

    while ( $port++ < 20000 ) {
        my $sock = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        );
        return $port if $sock;
    }
    die "empty port not found";
}

sub test_multi_tcp {
    my %args = @_;

    my (%ports, %pids, $prev);
    foreach my $server (grep { /^server/i } keys %args) {
        $prev = $ports{$server} = empty_port( defined $prev ? $prev + 1 : () );
    }

    my $reaper = sub {
        while ( scalar keys %pids > 0 && (my $kid = waitpid( -1, POSIX::WNOHANG() ) ) > 0 ) {
            delete $pids{ $kid };
            if ($^O ne 'MSWin32') { # i'm not in hell
                if (POSIX::WIFSIGNALED($?)) {
                    my $signame = (split(' ', $Config{sig_name}))[POSIX::WTERMSIG($?)];
                    if ($signame =~ /^(ABRT|PIPE)$/) {
                        Test::More::diag("your process received SIG$signame")
                    }
                }
            }
        }
    };

    local $SIG{CHLD} = $reaper;

    my %processes;
    my %sockets;
    foreach my $name ( grep { /^(?:server|client)/i } keys %args ) {
        my $code = $args{$name};
        my ($reader, $writer);
        socketpair($reader, $writer, AF_UNIX, SOCK_STREAM, PF_UNSPEC);

        if ( my $pid = Test::SharedFork->fork() ) {
            close($reader);
            $sockets{$name} = $writer;
            $processes{$name} = $pid;
            $pids{$pid}++;
        } elsif ($pid == 0) {
            # wait for the parent to signal us
            eval { 
                close($writer);
                my $data = fd_retrieve($reader);
                close($reader);

                if ($ports{ $name }) { # it's a server
                    $code->( $ports{ $name }, $data );
                } else {
                    $code->( $data );
                }
            };
            if ($@) { 
                my $message = "child $name ($$): $@";
                Test::More::diag($message);
                die $message;
            }
            exit;
        } else {
            die "fork failed: $!";
        }
    }

    # merge data
    my %data;
    while (my ($name, $port) = each %ports ) {
        $data{ $name } = { port => $port };
    }
    while (my ($name, $pid) = each %processes ) {
        $data{$name} ||= {};
        $data{$name}->{pid} = $pid;
    }

    foreach my $name ( grep { /^server/i } keys %args ) {
        # send each process information about other processes
        Storable::nstore_fd \%data, $sockets{$name};
        IO::Handle::flush($sockets{$name});
    }

    my ($sig, $loop);
    RUN: {
        $loop = 1;
        local $SIG{INT}  = sub { $sig = "INT"; $loop = 0 };
        local $SIG{PIPE} = sub { $sig = "PIPE"; $loop = 0 };

        while ( my($server, $port) = each %ports) {
            eval {
                wait_port($port);
            };
            if ($@) {
                Test::More::diag("Failed to spawn server $server: $@");
                while ( my ($name, $pid) = each %processes ) {
                    kill_proc( $pid );
                }
                last RUN;
            }
        }

        foreach my $name ( grep { /^client/i } keys %args ) {
            # send each process information about other processes
            Storable::nstore_fd \%data, $sockets{$name};
            IO::Handle::flush($sockets{$name});
        }

        while($loop && scalar keys %pids) {
            $reaper->();
        };

        if (scalar keys %pids) {
            while (my($name, $pid) = each %processes) {
                kill_proc( $pid );
            }
        }
                
    }

    if ($sig) {
        kill $sig, $$; # rethrow signal after cleanup
    }
}

sub kill_proc {
    foreach my $pid (@_) {
        next unless $pid;
        kill $TERMSIG => $pid;
    }
}

sub _check_port {
    my ($port) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

sub wait_port {
    my $port = shift;

    my $retry = 100;
    while ( $retry-- ) {
        return if _check_port($port);
        Time::HiRes::sleep(0.1);
    }
    die "Waited for port $port, but was not available";
}

1;

__END__

=head1 NAME

Test::TCP::Multi - Test Using Multiple Servers/Clients

=head1 SYNOPSIS

    use Test::MultiTCP;

    test_multi_tcp(
        server1 => sub {
            my ($port, $data_hash) = @_;
        },
        server2 => sub { ... },
        server3 => sub { ... },
        client1 => sub {
            my ($data_hash) = @_;
        },
        client2 => sub { ... },
        client3 => sub { ... }
    );

=head1 WARNING

This code is mostly a copy of Test::TCP, but the portions that I wrote are
eh... a HACK. Don't use unless you can debug things yourself!

=head1 DESCRIPTION

Test::TCP allows you to run client/server tests. With Test::TCP::Multi,
you can have multiple servers and clients.

=head1 SERVERS

Any key that starts with the string "server" (case-insensitive) is considered to be a server. Test::TCP::Multi will attempt to find an open port for any of these entries.

Server callbacks should expect two arguments, the port number you should use, and a hashref containing pids of each entry, and a port number (if the entry is a server)

B<UNLIKE Test::TCP>, YOU HAVE TO KILL THE SERVERS YOURSELF! This is because there's no way for Test::TCP::Multi to know if you're really done with the servers or not. Simply do something like

    kill_proc($data_hash->{ your_server_name }->{pid});

=head1 CLIENTS

Any key that starts with the string "client" (case-insensitive) is considered to be a client.

Server callbacks should expect two arguments, the port number you should use, and a hashref containing pids of each entry, and a port number (if the entry is a server)

=head1 AUTHOR

The important bits by Tokuhiro Matsuno (Test::TCP)

The hacked up stuff by Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut


