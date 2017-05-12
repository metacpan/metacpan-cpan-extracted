package UR::Service::WebServer;

use strict;
use warnings;

use UR;
use UR::Service::WebServer::Server;
use IO::File;
use IO::Socket::INET;
use Sys::Hostname;

class UR::Service::WebServer {
    has => [
        host => { is => 'String',
                    default_value => 'localhost',
                    doc => 'IP address to listen on' },
        port => { is => 'Integer',
                    default_value => undef,
                    doc => 'TCP port to listen on' },
    ],
    has_optional => [
        server  => { is => 'HTTP::Server::PSGI', calculate_from => ['__host','__port'], is_constant => 1,
                    calculate => q(
                        return UR::Service::WebServer::Server->new(
                            host => $__host,
                            port => $__port,
                            timeout => $self->timeout,
                            server_ready => sub { $self->announce() },
                        );
                    ), },
        timeout => { is => 'Integer',
                        default_value => undef,
                        doc => 'Timeout for read and write events' },
        idle_timeout => { is => 'Integer', default_value => undef,
                        doc => 'Exit the event loop after being idle for this many seconds' },
        cb => { is => 'CODE', doc => 'callback for handling requests' },
    ],
};

# Override port and host so they can auto-fill when needed
sub _port_host_override {
    my $self = shift;
    my $methodname = shift;
    my $method = '__'.$methodname;
    my $socket_method = 'sock'.$methodname;
    if (@_) {
        if ($self->{server}) {
            die "Cannot change $methodname after it has created the listen socket";
        }
        $self->$method(@_);

    } else {
      #  if (!defined($self->$method) && !defined($self->{server})) {
        unless (defined $self->$method) {
            unless (defined $self->{server}) {
                # not connected yet - start the server's listen socket and get its port
                $self->server->setup_listener();
            }
            $self->$method( $self->server->listen_sock->$socket_method() );
        }
    }
    return $self->$method;
}

sub port {
    my $self = shift;
    $self->_port_host_override('port', @_);
}

sub host {
    my $self = shift;
    $self->_port_host_override('host', @_);
}


sub announce {
    my $self = shift;

    my $sock = $self->server->listen_sock;
    my $host = ($sock->sockhost eq '0.0.0.0') ? Sys::Hostname::hostname() : gethostbyaddr($sock->sockaddr, AF_INET);
    $self->status_message(sprintf('Listening on http://%s:%d/', $host, $sock->sockport));
    return 1;
}

sub run {
    my $self = shift;

    my $cb = shift || $self->cb;

    unless ($cb) {
        $self->warning_message("No callback for run()... returning");
        return;
    }

    my $timeout = $self->idle_timeout || 0;
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    eval {
        alarm($timeout);
        $self->server->run($cb);
    };
    alarm(0);
    die $@ unless $@ eq "alarm\n";
}

my %mime_types = (
    'js'    => 'application/javascript',
    'html'  => 'text/html',
    'css'   => 'text/css',
    '*'     => 'text/plain',
);
sub _mime_type_for_filename {
    my($self, $pathname) = @_;
    my($ext) = ($pathname =~ m/\.(\w+)$/);
    $ext ||= '*';
    return $mime_types{$ext} || $mime_types{'*'};
}
sub _file_opener_for_directory {
    my($self, $dir) = @_;
    return sub {
        (my $pathname = shift) =~ s#/?\.\.##g;  # Remove .. - don't want them escaping the given directory tree
        return IO::File->new( join('/', $dir, $pathname), 'r');
    };
    
}
sub file_handler_for_directory {
    my($self, $dir) = @_;

    my $opener = $self->_file_opener_for_directory($dir);

    return sub {
        my($env, $pathname) = @_;

        my $fh = $opener->($pathname);
        unless($fh) {
            return [ 404, [ 'Content-Type' => 'text/plain'], ['Not Found']];
        }
        my $type = $self->_mime_type_for_filename($pathname);
        if ($env->{'psgi.streaming'}) {
            return [ 200, ['Content-Type' => $type], $fh];
        } else {
            local $/;
            my $buffer = <$fh>;
            return [ 200, ['Content-Type' => $type], [$buffer]];
        }
    };
}

sub delete {
    my $self = shift;
    $self->server->listen_sock->close();
    $self->{server} = undef;
    $self->SUPER::delete(@_);
}

1;

=pod

=head1 NAME

UR::Service::WebServer - A PSGI-based web server

=head1 SYNOPSIS

  my $s = UR::Service::WebServer(port => 4321);
  $s->run( \&handle_request );

=head1 DESCRIPTION

Implements a simple, standalone web server based on HTTP::Server::PSGI.  The
event loop is entered by calling the run() method.

=head2 Properties

=over 4

=item host

The IP address to listen on for connections.  The default value is
'localhost'.  host can be changed any time before the server is created,
usually the first time run() is called.

=item port

The TCP port to listen on for connections.   The detault value is undef,
meaning that the system will pick an unused port.  port can be changed any
time before the server is created, usually the first time run() is called.

=item server

Holds a reference to an object that isa HTTP::Server::PSGI.  This will be
automatically created the first time run() is called.

=item cb

Holds a CODE reference used as the default request handler within run().

=back

=head2 Methods

=over 4

=item $self->announce()

This method is called when the PSGI server is ready to accept requests.
The base-class behavior is to print the listening URL on STDOUT.  Subclasses
can override it to implement their own behavior.

=item my $code = $self->file_handler_for_directory($path)

A helper method used for implementing server for files located in the
directory $path.  It returns a CODE ref that takes 2 arguments, $env (the
standard PSGI env hashref) and $pathname (a path relative to $path).  It
returns the standard tuple a PSGI server expects.

$pathname is pre-processed by removing all occurrences of ".." to keep requests
within the provided $path.  If the requested file is not found, then it
returns a 404.

=item $self->run(<$cb>)

Enter the request loop.  If a callback is not provided to run(), then the
object's cb property is used instead.  If neither have a value, then run()
returns immediately.

For each request $cb is called with one argument, the standard PSGI env
hashref.

=back

=head1 SEE ALSO

L<UR::Service::UrlRouter>

=cut
