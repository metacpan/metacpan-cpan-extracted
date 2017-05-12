use strict;

{
  package TPSTParseWords;

  use base qw(POE::Filter);
  use Text::ParseWords;

  my $VERSION = '1.02';

  sub new {
    my $class = shift;
    my %opts = @_;
    $opts{lc $_} = delete $opts{$_} for keys %opts;
    $opts{keep} = 0 unless $opts{keep};
    $opts{delim} = '\s+' unless $opts{delim};
    $opts{BUFFER} = [];
    bless \%opts, $class;
  }

  sub get {
    my ($self, $raw) = @_;
    my $events = [];
    push @$events, [ parse_line( $self->{delim}, $self->{keep}, $_ ) ] for @$raw;
    return $events;
  }

  sub get_one_start {
    my ($self, $raw) = @_;
    push @{ $self->{BUFFER} }, $_ for @$raw;
  }

  sub get_one {
    my $self = shift;
    my $events = [];
    my $event = shift @{ $self->{BUFFER} };
    push @$events, [ parse_line( $self->{delim}, $self->{keep}, $event ) ] if defined $event;
    return $events;
  }

  sub put {
    warn "PUT is unimplemented\n";
    return;
  }

  sub clone {
    my $self = shift;
    my $nself = { };
    $nself->{$_} = $self->{$_} for keys %{ $self };
    $nself->{BUFFER} = [ ];
    return bless $nself, ref $self;
  }

}

use Socket;
use Test::More;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use Test::POE::Server::TCP;

plan tests => 11;

my %data = (
	tests => [ 
		[ 'Howdy!' => '"This is just a test" "line" "so there"' ], 
		[ 'bleh' => 'quit' ],
	],
);

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_sock_up
			_sock_fail
			_sock_in
			_sock_err
			testd_registered
			testd_connected
			testd_disconnected
			testd_client_input
	)],
  ],
  heap => \%data,
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
	address => '127.0.0.1',
	port => 0,
	options => { trace => 0 },
	inputfilter => TPSTParseWords->new(),
	outputfilter => POE::Filter::Line->new(),
  );
  isa_ok( $_[HEAP]->{testd}, 'Test::POE::Server::TCP' );
  return;
}

sub testd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  isa_ok( $object, 'Test::POE::Server::TCP' );
  $heap->{port} = $object->port();
  $heap->{factory} = POE::Wheel::SocketFactory->new(
	RemoteAddress  => '127.0.0.1',
	RemotePort     => $heap->{port},
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_fail',
  );
  return;
}

sub _sock_up {
  my ($heap,$socket) = @_[HEAP,ARG0];
  delete $heap->{factory};
  $heap->{socket} = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	InputEvent => '_sock_in',
	ErrorEvent => '_sock_err',
  );
  return;
}

sub _sock_fail {
  my $heap = $_[HEAP];
  delete $heap->{factory};
  $heap->{testd}->shutdown();
  return;
}

sub _sock_in {
  my ($heap,$input) = @_[HEAP,ARG0];
  my @parms = split /\s+/, $input;
  my $test = shift @{ $heap->{tests} };
  if ( $test and $test->[0] eq $parms[0] ) {
	pass($input);
	$heap->{socket}->put( $test->[1] );
	return;
  }
  pass($input);
  return;
}

sub _sock_err {
  delete $_[HEAP]->{socket};
  pass("Disconnected");
  $_[HEAP]->{testd}->shutdown();
  return;
}

sub testd_connected {
  my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
  $heap->{testd}->send_to_client( $id, 'Howdy!' );
  pass($state);
  return;
}

sub testd_disconnected {
  pass($_[STATE]);
  return;
}

sub testd_client_input {
  my ($sender,$id,$input) = @_[SENDER,ARG0,ARG1];
  my $testd = $_[SENDER]->get_heap();
  pass($_[STATE]);
  if ( $input->[0] eq 'quit' ) {
    $testd->disconnect( $id );
    $testd->send_to_client( $id, 'Buh Bye!' );
    return;
  }
  ok( ( $input->[0] eq 'This is just a test' and $input->[1] eq 'line' and $input->[2] eq 'so there' ) , 'Test Get' );
  $testd->send_to_client( $id, 'bleh' );
  return;
}
