package Test::HTTP::MockServer;
use strict;
use warnings;
use HTTP::Parser;
use HTTP::Response;
use IO::Handle;
use Socket;

our $VERSION = '0.0.1';

sub new {
    my ($class) = @_;
    $class = ref $class || $class;
    return bless {}, $class;
}

sub bind_mock_server {
    my $self = shift;
    if (!$self->{socket}) {
        my $proto = getprotobyname("tcp")
          or die $!;
        socket my $s, PF_INET, SOCK_STREAM, $proto
          or die $!;
        my $host_s = '127.0.0.1';
        my $host = inet_aton($host_s);
        my $port;
        while (1) {
            $port = int(rand(5000))+10000;
            my $addr = sockaddr_in($port, $host);
            bind($s,$addr)
              or next;
            listen($s, 10)
              or die $!;
            last;
        }
        $self->{host} = $host_s;
        $self->{port} = $port;
        $self->{socket} = $s;
    }
    return 1;
}

sub host {
    my $self = shift;
    $self->bind_mock_server;
    return $self->{host};
}

sub port {
    my $self = shift;
    $self->bind_mock_server;
    return $self->{port};
}

sub url_base {
    my $self = shift;
    my $host = $self->host;
    my $port = $self->port;
    return "http://$host:$port";
}

my $request_handle = sub {
    my $self = shift;
    my $rp = shift;
    my $request = shift;
    my $response;
    eval {
        $response = HTTP::Response->new(200, 'OK');
        $response->header('Content-type' => 'text/plain');
        $rp->($request, $response);
    };
    if ($@) {
        my $err = $@;
        return HTTP::Response->new(
            500, 'Internal Server Error',
            HTTP::Headers->new("Content-type" => "text/plain"),
            $err
        );
    } else {
        return $response;
    }
};

my $client_handle = sub {
    my $self = shift;
    my $rp = shift;
    my $client = shift;
    my $parser = HTTP::Parser->new(request => 1);

    while (1) {
        my $buf;
        # read a byte at a time so we can do a blocking read instead of
        # having to manage a non-blocking read loop.
        my $r = read $client, $buf, 1;
        my $request;
        my $closed;
        if (defined $r) {
            my $p = $parser->add($buf);
            if ($p == 0) {
                $request = $parser->object;
            }
            $closed = 0;
        } else {
            $request = $parser->object;
            $closed = 1;
        }
        if ($request) {
            my $copy = $request;
            $request = undef;
            my $response = $request_handle->($self, $rp, $copy);
            $response->header('Content-length' => length($response->content));
            my $strout = "HTTP/1.1 ".($response->as_string("\015\012"));
            $client->print($strout);
            # we don't support keep-alive
            $closed = 1;
        }
        last if $closed;
    }
};

my $server_loop = sub {
    my $self = shift;
    my $rp = shift;
    while (1) {
        accept my $client, $self->{socket}
          or die "Failed to accept new connections: $!";
        eval {
            $client_handle->($self, $rp, $client);
        };
        close $client;
    }
};

sub start_mock_server {
    my $self = shift;
    my $rp = shift or die "No request processor";

    die "There is already a mock server running"
      if $self->{mock_server_pid};

    $self->{mock_server_pid} = fork;
    if ($self->{mock_server_pid}) {
        return;
    } else {
        $DB::signal = 1;
        $SIG{INT} = sub { exit 1; };
        $SIG{TERM} = sub { exit 1; };
        $server_loop->($self,$rp);
        exit 0;
    }
}

sub stop_mock_server {
    my $self = shift;
    die "Mock server not started"
      unless $self->{mock_server_pid};
    kill 2, $self->{mock_server_pid};
    waitpid $self->{mock_server_pid}, 0;
    delete $self->{mock_server_pid};
}

sub DESTROY {
    my $self = shift;
    eval {
        $self->stop_mock_server
          if $self->{mock_server_pid};
    };
}

1;

__END__

=head1 NAME

Test::HTTP::MockServer - Implement a mock HTTP server for use in tests

=head1 SYNOPSIS

  use Test::HTTP::MockServer;
  
  my $server = Test::HTTP::MockServer->new();
  my $url = $server->url_base();
  # inject $url as the config for the remote http service.
  
  my $handle_request_phase1 = sub {
      my ($request, $response) = @_;
      ...
  };
  $server->start_mock_server($handle_request_phase1);
  # run your tests against $handle_request_phase1
  $server->stop_mock_server();
  
  my $handle_request_phase2 = sub {
      my ($request, $response) = @_;
      ...
  };
  $server->start_mock_server($handle_request_phase2);
  # run your tests against $handle_request_phase2
  $server->stop_mock_server();

=head1 DESCRIPTION

Sometimes, when writing a test, you don't have to oportunity to do
dependency injection of the type of transport used in a specific
API. Sometimes that code willl unequivocally always use actual HTTP
and the only control you have is over the host and port to which it
will connect.

This class offer a simple way to mock the service being called. It
does that by binding to a random port on localhost and allowing you to
inspect which port that was. Using a random port means that this can
be used by tests running in parallel on the same host.

The socket will be bound and listened on the main test process, such
that the lifetime of the connection is defined by the lifetime of the
test itself.

Since the socket will be already bound and listened to, the two
conntrol methods (start_mock_server and stop_mock_server) fork only
for the accept call, which means that it is safe to call start and
stop several times during the test in order to change the expectations
of the mocked code.

That allows you to easily configure the expectations of the mock
server across each step of your test case. On the other hand, it also
means that no state is shared between the code running in the mock
server and the test code.

=head1 METHOS

=over

=item new()

Creates a new MockServer object.

=item bind_mock_server()

Finds a random available port, bind and listen to it. This allows to
inspect what the mock url of the portal will be before the server
forks to start. If the random port is already in use, it will keep
trying until it finds one that works.

=item host()

Returns the host which the mock server is binding to. It will call
bind_mock_server if that was not yet initialized. The current version
always bind to 127.0.0.1.

=item port()

Returns the port which the mock server is bound and is listening
to. It will call bind_mock_server if that was not yet initialized.

=item base_url()

Returns the url to be used as the base url for requests into the mock
server. It will bind_mock_server if that was not yet initialized.

=item start_mock_server($request_processor)

This will bind_mock_server if that was not yet initialized, then fork
to accept connections.

In order to make it easier to have state propagate across different
requests in the mock implementation, there will only be one connection
at a time, and every request in that connection will be handled
serially.

=item stop_mock_server()

This will kill the server running on the background, but it won't
unbind the socket, which means that you can just call
start_mock_server again with a different request_processor and the
same url will be preserved.

=back

=head1 THE REQUEST PROCESSOR

The request processor is the code reference sent as an argument to the
start_mock_server call which will receive all the requests received
via the socket.

Whenever a request is received, the code reference will be called with
two arguments:

=over

=item $request

An HTTP::Request object with the request as it was received.

=item $response

An HTTP::Response object that will be sent back. It is initialized
with "200 OK" and no content

=back

If your code dies while processing a request, a "500 Internal Server
Error" response will be generated.

=head1 COPYRIGHT

Copyright 2016 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


