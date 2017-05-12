package WWW::Webrobot::StupidHTTPD;
use strict;
use warnings;

use HTTP::Daemon;
use LWP::UserAgent;


=head1 NAME

WWW::Webrobot::StupidHTTPD - A simple HTTP daemon for tests

=head1 SYNOPSIS

 # create and start the daemon
 my $daemon = WWW::Webrobot::StupidHTTPD -> new();
 $daemon -> start($server_func, fork_daemon => 1);

 # do anything else, e.g. run a client that accesses the daemon
 $config .= "names=application=" . $daemon -> server_url() . "\n";
 my $webrobot = WWW::Webrobot -> new($config);
 my $exit = $webrobot -> run($test_plan);

 # stop the daemon
 $daemon -> stop();


=head1 DESCRIPTION

Start and stop a daemon. Can fork!

=head1 METHODS

=over

=item $wr = WWW::Webrobot -> new( %parameters );

 debug         switch to debug mode
 timout        timout (terminate) for the daemon in seconds

=cut

sub new {
    my $class = shift;
    my %parm = @_;
    my $self = bless({
        debug => $parm{debug},
        timeout => $parm{timout} || 10,
    }, ref($class) || $class);
    return $self;
}

=item $wr -> start($func, %parameters)

Start a daemon.
C<$func> is the servers job to do on any request,
see F<t/get.t> for the syntax.
Parameters:

 timeout       The timout for the server
 fork_daemon   Require the daemon to be forked:
               forked:     work as client (server is forked off)
               non-forked: work as server

Returns the C<pid> of the currently started server (only if server is forked off).

=cut

sub start {
    my ($self, $func, %parm) = @_;
    $func ||= sub {
        my ($connection, $request) = @_;
        $connection->send_error(404)
    };

    my $daemon = HTTP::Daemon -> new(Timeout => $parm{timeout});
    $self->server_url($daemon->url());

    if ($parm{fork_daemon}) { # fork if desired
        my $pid = fork();
        if ($pid) { # parent
            my $url = $daemon->url();
            $self->{_pids}->{$pid} = $url;
            print STDERR "Starting httpd: process=$pid url=$url\n" if $self->{debug};
            undef($daemon);
            return $pid;
        }
        else { # child
            close STDIN;
            close STDOUT;
            #close STDERR if ! $self->{debug};
        }
    }

    DAEMON:
    while (my $connection = $daemon->accept()) {
        while (my $request = $connection->get_request()) {
            last DAEMON if $request->uri =~ m(/shutdown/$);
            $func->($connection, $request);
            last if $parm{single_request}; # for multiple clients, less efficient
        }
        $connection->close();
        undef($connection);
    }
    print STDERR "TERMINATION $$\n" if $self->{debug};
    exit;
}

=item $wr -> server_url

The url where you can access the recently started daemon.

This method makes only sense iff you forked the server off.

=cut

sub server_url {
    my ($self, $server_url) = @_;
    ($self->{_server_url} = $server_url) =~ s{/$}{} if defined $server_url;
    return $self->{_server_url};
}

=item $wr -> stop( @stop_pids )

Stop the desired daemons or all if no list is given.
This is done by creating a user agent and requesting an url
containing C<shutdown>.

This method makes only sense iff you forked the server off.

=cut

sub stop {
    my ($self, @stop_pids) = @_;
    my $ua = LWP::UserAgent -> new();
    my @pids = scalar @stop_pids ? @stop_pids : keys %{$self->{_pids}};
    foreach (@pids) {
        print STDERR "Terminating httpd: process=$_ url=$self->{_pids}->{$_}\n" if $self->{debug};
        $ua -> get($self->{_pids}->{$_} . "shutdown/") if defined $self->{_pids}->{$_};
    }
}

=back

=cut

1;
