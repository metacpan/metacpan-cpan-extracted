package Test::HTTP::MockServer::Once;
use strict;
use warnings;
use HTTP::Parser;
use HTTP::Response;
use IO::Handle;
use Socket;
use Storable qw(freeze);

our $VERSION = '0.0.2';

sub new {
	my ($class, %params) = @_;
    $class = ref $class || $class;
    return bless {
		port => $params{port} || undef
	}, $class;
}

sub bind_mock_server {
    my $self = shift;
    if (!$self->{socket}) {
        my $proto = getprotobyname("tcp")
          or die $!;
        socket my $s, PF_INET, SOCK_STREAM, $proto
          or die $!;
        setsockopt($s,SOL_SOCKET,SO_REUSEADDR,1) or die "setsockopt: $!"; 
        my $host_s = '127.0.0.1';
        my $host = inet_aton($host_s);
        if(defined($self->{port}))
        {
			my $addr = sockaddr_in($self->{port}, $host);
			bind($s,$addr) or die $!;
			listen($s, 10)
			  or die $!;
		}
		else
		{
	        my $random_port;
			while (1) {
				$random_port = int(rand(5000))+10000;
				my $addr = sockaddr_in($random_port, $host);
				bind($s,$addr)
				  or next;
				listen($s, 10)
				  or die $!;
				last;
			}
			$self->{port} = $random_port;
		}
        $self->{host} = $host_s;
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

sub base_url {
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

	my $ret;
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
            $ret->{request} = $request;
            $request = undef;
            my $response = $request_handle->($self, $rp, $copy);
            $response->header('Content-length' => length($response->content));
            $ret->{response} = $response;
            my $strout = "HTTP/1.1 ".($response->as_string("\015\012"));
            $client->print($strout);
            # we don't support keep-alive
            $closed = 1;
        }
        last if $closed;
    }
    return $ret; 
};

sub start_mock_server {
    my $self = shift;
    my $rp = shift or die "No request processor";

	$self->bind_mock_server();

	$DB::signal = 1;
	$SIG{INT} = sub { exit 1; };
	$SIG{TERM} = sub { exit 1; };
	accept my $client, $self->{socket}
	  or die "Failed to accept new connections: $!";
	my $interaction;
	eval {
		$interaction = $client_handle->($self, $rp, $client);
	};
	close $client;
	close $self->{socket};
	return freeze $interaction;
}

1;

__END__

=head1 NAME

Test::HTTP::MockServer::Once - Implement a one shot mock HTTP server for use in tests

=head1 SYNOPSIS

  use Test::HTTP::MockServer::Once;
  use Test::More;
  use Storable qw(thaw);
  
  my $server = Test::HTTP::MockServer::Once->new();
  my $server = Test::HTTP::MockServer::Once->new(port => 3000);
  my $url = $server->base_url();
  # this is the listen URL
  
  my $handle_request = sub {
      my ($request, $response) = @_;
      ...
  };
  # This will block until one request is received, and then exit
  # Fine if you are expecting a call from outside
  my $interaction = thaw $server->start_mock_server($handle_request);
  # response contains request and response objects and is a frozen Storable
  note("URI called: ".$interaction->{request}->uri->as_string);
  
  # If you want to include a timeout rather than wait for ever, use Async  
  use Async;
  use Test::HTTP::MockServer::Once;
  use Test::More;
  use Storable qw(thaw);
  
  my $proc = AsyncTimeout->new(sub { $server->start_mock_server($handle_request) }, 30, "TIMEOUT");
  # wait until the request comes in or it times out
  my $result = $proc->result('force completion');						
  BAIL_OUT "No request received" if($proc->result eq "TIMEOUT");
  my $interaction = thaw $result;
  note("URI called: ".$interaction->{request}->uri->as_string);

  # Or don't wait for the request if you want to mock that yourself
  use Async;
  use Test::HTTP::MockServer::Once;
  use Test::More;
  use LWP::UserAgent;
  use Storable qw(thaw);
  
  my $proc = Async->new(sub { $server->start_mock_server($handle_request) });
  $ua->get($url);
  my $interaction = thaw $proc->result;
  note("URI called: ".$interaction->{request}->uri->as_string);
  

=head1 DESCRIPTION

Based on L<Test::HTTP::MockServer> but runs once and exits rather than 
continuing to run.

Sometimes, when writing a test, you don't have to opportunity to do
dependency injection of the type of transport used in a specific
API. Sometimes that code will unequivocally always use actual HTTP
and the only control you have is over the host and port to which it
will connect.

This class offers a simple way to mock the service being called. It
does that by binding to a random port or specified port on localhost.
Using a random port means that this can be used by tests running in 
parallel on the same host. Using a specified port means you can have a
predictable URL to give as a callback URL when testing OAuth2 and the 
like.

The socket will be bound and listened on the main test process, then 
closed after one request has been received. You will need to restart the 
server for each test call it should receive.

If you want a server to carry on running for multiple tests, see 
L<Test::HTTP::MockServer>.

=head1 METHODS

=over

=item new()

Creates a new MockServer object. By default a random local available 
port will be chosen. To choose a specific port:

  Test::HTTP::MockServer::Once->new(port => 3000);

=item bind_mock_server()

Finds a random available port, bind and listen to it, or binds to the 
specified port if provided. This allows you to inspect what the mock url 
of the portal will be before the server starts. If the random port is 
already in use, it will keep trying until it finds one that works.

=item host()

Returns the host which the mock server is binding to. It will call
bind_mock_server if that was not yet initialized. The current version
always bind to 127.0.0.1.

=item port()

Returns the port which the mock server is bound and is listening
to. It will call bind_mock_server if that was not yet initialized.

=item base_url()

Returns the url to be used as the base url for requests into the mock
server. It will call bind_mock_server if that was not yet initialized.

=item start_mock_server($request_processor)

This will call bind_mock_server if that was not yet initialized. It will 
not return until exactly one request has been processed. Use with Async 
as shown in the L<SYNOPSIS> if you want your test to carry on.

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

Copyright 2016 Bloomberg Finance L.P., 2021 on Ian Gibbs

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


