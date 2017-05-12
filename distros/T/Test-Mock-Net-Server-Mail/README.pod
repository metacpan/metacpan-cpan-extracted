package Test::Mock::Net::Server::Mail;

use Moose;

# ABSTRACT: mock SMTP server for use in tests
# VERSION

use Net::Server::Mail::ESMTP;
use IO::Socket::INET;
use Test::Exception;

=head1 DESCRIPTION

Test::Mock::Net::Server::Mail is a mock SMTP server based on Net::Server::Mail.
If could be used in unit tests to check SMTP clients.

It will accept all MAIL FROM and RCPT TO commands except they start
with 'bad' in the user or domain part.
And it will accept all mail except mail containing the string 'bad mail content'.

If a different behaviour is need a subclass could be used to overwrite process_<cmd> methods.

=head1 SYNOPSIS

In a test:

  use Test::More;
  use Test::Mock::Net::Server::Mail;

  use_ok(Net::YourClient);

  my $s = Test::Mock::Net::Server::Mail->new;
  $s->start_ok;

  my $c = Net::YourClient->new(
    host => $s->bind_address,
    port => $s->port,
  );
  # check...

  $s->stop_ok;

=head1 ATTRIBUTES

=head2 bind_address (default: "127.0.0.1")

The address to bind to.

=head2 start_port (default: random port > 50000)

First port number to try when searching for a free port.

=head2 support_8bitmime (default: 1)

Load 8BITMIME extension?

=head2 support_pipelining (default: 1)

Load PIPELINING extension?

=head2 support_starttls (default: 1)

Load STARTTLS extension?

=cut

has 'bind_address' => ( is => 'ro', isa => 'Str', default => '127.0.0.1' );
has 'port' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'pid' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'start_port' => ( is => 'rw', isa => 'Int', lazy => 1,
  default => sub {
    return 50000 + int(rand(10000));
  },
);

has 'socket' => ( is => 'ro', isa => 'IO::Socket::INET', lazy => 1,
  default => sub {
    my $self = shift;
    my $cur_port = $self->start_port;
    my $socket;
    for( my $i = 0 ; $i < 100 ; $i++ ) {
      $socket = IO::Socket::INET->new(
        Listen => 1,
        LocalPort => $cur_port,
        LocalAddr => $self->bind_address,
      );
      if( defined $socket ) {
        last;
      }
      $cur_port += 10;
    }
    if( ! defined $socket ) {
      die("giving up to find free port to bind: $@");
    }
    $self->port( $cur_port );
    return $socket;
  },
);

has 'support_8bitmime' => ( is => 'ro', isa => 'Bool', default => 1 );
has 'support_pipelining' => ( is => 'ro', isa => 'Bool', default => 1 );
has 'support_starttls' => ( is => 'ro', isa => 'Bool', default => 1 );

sub process_connection {
  my ( $self, $conn ) = @_;
  my $smtp = Net::Server::Mail::ESMTP->new(
    socket => $conn,
  );

  $self->support_8bitmime
    && $smtp->register('Net::Server::Mail::ESMTP::8BITMIME');
  $self->support_pipelining
    && $smtp->register('Net::Server::Mail::ESMTP::PIPELINING');
  $self->support_starttls
    && $smtp->register('Net::Server::Mail::ESMTP::STARTTLS');

  $smtp->set_callback(EHLO => sub {
      my ( $session, $name ) = @_;
      return $self->process_ehlo( $session, $name );
  } );
  $smtp->set_callback(HELO => sub {
      my ( $session, $name ) = @_;
      return $self->process_ehlo( $session, $name );
  } );
  $smtp->set_callback(MAIL => sub {
      my ( $session, $addr ) = @_;
      return $self->process_mail( $session, $addr );
  } );
  $smtp->set_callback(RCPT => sub {
      my ( $session, $addr ) = @_;
      return $self->process_rcpt( $session, $addr );
  } );
  $smtp->set_callback(DATA => sub {
      my ( $session, $data ) = @_;
      return $self->process_data( $session, $data );
  } );

  $self->before_process( $smtp );
  $smtp->process();
  $conn->close();
    
  return;
};

=head1 METHODS

=head2 port

Retrieve the port of the running mock server.

=head2 pid

Retrieve the process id of the running mock server.

=head2 before_process( $smtp )

Overwrite this method in a subclass if you need to register additional
command callbacks via Net::Server::Mail.

Net::Server::Mail object is passed via $smtp.

=cut

sub before_process {
  my ( $self, $smtp ) = @_;
  return;
}

=head2 process_ehlo( $session, $name )

=head2 process_mail( $session, $addr )

=head2 process_rcpt( $session, $addr )

=head2 process_data( $session, \$data )

Overwrite on of this methods in a subclass if you need to
implement your own handler.

=cut

sub process_ehlo {
  my ( $self, $session, $name ) = @_;
  if( $name =~ /^bad/) {
    return(1, 501, "$name is a bad helo name");
  }
  return 1;
}

sub process_mail_rcpt {
  my ( $self, $session, $rcpt ) = @_;
  my ( $user, $domain ) = split('@', $rcpt, 2);
  if( ! defined $user ) {
    return(0, 513, 'Syntax error.');
  }
  if( $user =~ /^bad/ ) {
    return(0, 552, "$rcpt Recipient address rejected: bad user");
  }
  if( defined $domain && $domain =~ /^bad/ ) {
    return(0, 552, "$rcpt Recipient address rejected: bad domain");
  }
  return(1);
}
*process_mail = \&process_mail_rcpt;
*process_rcpt = \&process_mail_rcpt;

sub process_data {
  my ( $self, $session, $data ) = @_;
  if( $$data =~ /bad mail content/msi ) {
    return(0, 554, 'Message rejected: bad mail content');
  }
  return 1;
}

=head2 main_loop

Start main loop.

Will accept connections forever and will never return.

=cut

sub main_loop {
  my $self = shift;

  while( my $conn = $self->socket->accept ) {
    $self->process_connection( $conn );
  }

  return;
}

=head2 start

Start mock server in background (fork).

After the server is started $obj->port and $obj->pid will be set.

=cut

sub start {
  my $self = shift;
  if( defined $self->pid ) {
    die('already running with pid '.$self->pid);
  }

  # make sure socket is initialized
  # we need to know the port number in parent
  $self->socket;

  my $pid = fork;
  if( $pid == 0 ) {
    $self->main_loop;
  } else {
    $self->pid( $pid );
  }

  return;
}

=head2 start_ok( $msg )

Start the mock server and return a test result.

=cut

sub start_ok {
  my ( $self, $text ) = @_;
  lives_ok {
    $self->start;
  } defined $text ? $text : 'start smtp mock server';
  return;
}

=head2 stop

Stop mock smtp server.

=cut

sub stop {
  my $self = shift;
  my $pid = $self->pid;
  if( defined $pid ) {
    kill( 'QUIT', $pid );
    waitpid( $pid, 0 );
  }

  return;
}

=head2 stop_ok( $msg )

Stop the mock server and return a test result.

=cut

sub stop_ok {
  my ( $self, $text ) = @_;
  lives_ok {
    $self->stop;
  } defined $text ? $text : 'stop smtp mock server';
  return;
}

1;

