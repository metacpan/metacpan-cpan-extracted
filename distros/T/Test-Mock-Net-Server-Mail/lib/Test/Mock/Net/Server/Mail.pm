package Test::Mock::Net::Server::Mail;

use Moose;

# ABSTRACT: mock SMTP server for use in tests
our $VERSION = '1.01'; # VERSION


use Net::Server::Mail::ESMTP;
use IO::Socket::INET;
use IO::File;
use Test::More;
use Test::Exception;
use JSON;
use File::Temp;


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

has 'mock_verbs' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [ qw(
    EHLO
    HELO
    MAIL
    RCPT
    DATA
    QUIT
  ) ] },
);

has 'logging' => (
  is => 'ro',
  isa => 'Bool',
  default => 1,
);

sub BUILD {
  my $self = shift;
  if( $self->logging ) {
    $self->_init_log;
  }
  return;
}

has '_log_fh' => (
  is => 'rw',
  isa => 'IO::Handle',
);

sub _init_log {
  my $self = shift;
  $self->_log_fh(File::Temp->new);
  return;
}

sub _reopen_log {
  my $self = shift;
  my $fh = IO::File->new($self->_log_fh->filename, O_WRONLY|O_APPEND)
    or die('cannot reopen temporary logfile: '.$!);
  $self->_log_fh($fh);
  return;
}

sub _write_log {
  my $self = shift;
  $self->_log_fh->print(join('',@_));
  $self->_log_fh->flush;
  return;
}


sub next_log {
  my $self = shift;
  my $line = $self->_log_fh->getline;
  if($line) {
    chomp $line;
    return decode_json $line;
  }
  return;
}


sub next_log_ok {
  my ($self, $verb, $params, $text) = @_;
  my $log = $self->next_log;
  if(!defined $log) {
    fail($text);
    diag('no more logs to read!');
    return;
  }

  if($log->{'verb'} ne $verb) {
    fail($text);
    diag('expected verb '.$verb.' but got '.$log->{'verb'});
    return;
  }

  if(defined $params) {
    if(ref($params) eq 'Regexp') {
      like($log->{'params'}, $params, $text);
      return;
    }
    cmp_ok($log->{'params'}, 'eq', $params, $text);
    return;
  }

  pass($text);
  return;
}

sub _process_callback {
  my ($self, $verb, $session, $params) = @_;

  if($self->logging) {
    $self->_log_callback($verb, $params);
  }

  my $method = "process_".lc($verb);
  if($self->can($method)) {
    return $self->$method($session, $params);
  }
  return;
}

sub _log_callback {
  my ($self, $verb, $params) = @_;
  my $params_out;
  if(ref($params) eq '') {
    $params_out = $params;
  } elsif(ref($params) eq 'SCALAR') {
    $params_out = $$params;
  } else {
    $params_out = $verb.' passed unprintable '.ref($params);
  }
  $self->_write_log(
    encode_json( {
      verb => $verb,
      defined $params_out ? (params => $params_out) : (),
    } )."\n"
  );
  return;
}

sub _process_connection {
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

  foreach my $verb (@{$self->mock_verbs}) {
    $smtp->set_callback($verb => sub {
        my ( $session, $params ) = @_;
        return $self->_process_callback( $verb, $session, $params );
    } );
  }

  $self->before_process( $smtp );
  $smtp->process();
  $conn->close();
    
  return;
};



sub before_process {
  my ( $self, $smtp ) = @_;
  return;
}


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


sub main_loop {
  my $self = shift;

  $self->_reopen_log;

  while( my $conn = $self->socket->accept ) {
    $self->_process_connection( $conn );
  }

  exit 1;
  return;
}


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


sub start_ok {
  my ( $self, $text ) = @_;
  lives_ok {
    $self->start;
  } defined $text ? $text : 'start smtp mock server';
  return;
}


sub stop {
  my $self = shift;
  my $pid = $self->pid;
  if( defined $pid ) {
    kill( 'QUIT', $pid );
    waitpid( $pid, 0 );
  }

  return;
}

sub DESTROY {
  my $self = shift;
  # try to stop server when going out of scope
  $self->stop;
  return;
}


sub stop_ok {
  my ( $self, $text ) = @_;
  lives_ok {
    $self->stop;
  } defined $text ? $text : 'stop smtp mock server';
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mock::Net::Server::Mail - mock SMTP server for use in tests

=head1 VERSION

version 1.01

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

=head1 DESCRIPTION

Test::Mock::Net::Server::Mail is a mock SMTP server based on Net::Server::Mail.
If could be used in unit tests to check SMTP clients.

It will accept all MAIL FROM and RCPT TO commands except they start
with 'bad' in the user or domain part.
And it will accept all mail except mail containing the string 'bad mail content'.

If a different behaviour is need a subclass could be used to overwrite process_<verb> methods.

=head1 LOGGING

If the logging option is enabled (by default) the mock server will log
received commands in a temporary log file. The content of this log file
can be inspected with the methods next_log() or tested with next_log_ok().

  # setup server($s) and client($c)...

  $c->ehlo('localhost');
  $s->next_log;
  # {"verb" => "EHLO","params" => "localhost"}
  
  $c->mail_from('user@domain.tld');
  $s->next_log_ok('MAIL', 'user@domain.tld, 'server received MAIL cmd');
  
  $c->rcpt_to('targetuser@targetdomain.tld');
  $s->next_log_ok('RCPT', qr/target/, 'server received RCPT cmd');

  # shutdown...

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

=head2 logging (default: 1)

Log commands received by the server.

=head2 mock_verbs (ArrayRef)

Which verbs the server should add mockup to.

By default:

  qw(
    EHLO
    HELO
    MAIL
    RCPT
    DATA
    QUIT
  )

=head1 METHODS

=head2 port

Retrieve the port of the running mock server.

=head2 pid

Retrieve the process id of the running mock server.

=head2 next_log

Reads one log from the servers log and returns a hashref.

Example:

  {"verb"=>"EHLO","params"=>"localhost"}

=head2 next_log_ok($verb, $expect, $text)

Will read a log using next_log() and test it.

The logs 'verb' must exactly match $verb.

The logs 'params' are checked against $expected. It must be a
string,regexp or undef.

Examples:

  $s->next_log_ok('EHLO', 'localhost', 'server received EHLO command');
  $s->next_log_ok('MAIL', 'gooduser@gooddomain', 'server received MAIL command');
  $s->next_log_ok('RCPT', 'gooduser@gooddomain', 'server received RCPT command');
  $s->next_log_ok('DATA', qr/bad mail content/, 'server received DATA command');
  $s->next_log_ok('QUIT', undef, 'server received QUIT command');

=head2 before_process( $smtp )

Overwrite this method in a subclass if you need to register additional
command callbacks via Net::Server::Mail.

Net::Server::Mail object is passed via $smtp.

=head2 process_ehlo( $session, $name )

Will refuse EHLO names containing the string 'bad'
otherwise will accept any EHLO.

=head2 process_mail( $session, $addr )

Will accept all senders except senders where
user or domain starts with 'bad'.

=head2 process_rcpt( $session, $addr )

Will accept all reciepients except recipients where
user or domain starts with 'bad'.

=head2 process_data( $session, \$data )

Overwrite on of this methods in a subclass if you need to
implement your own handler.

=head2 main_loop

Start main loop.

Will accept connections forever and will never return.

=head2 start

Start mock server in background (fork).

After the server is started $obj->port and $obj->pid will be set.

=head2 start_ok( $msg )

Start the mock server and return a test result.

=head2 stop

Stop mock smtp server.

=head2 stop_ok( $msg )

Stop the mock server and return a test result.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
