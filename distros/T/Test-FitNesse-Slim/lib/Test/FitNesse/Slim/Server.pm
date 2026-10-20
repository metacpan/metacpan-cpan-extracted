package Test::FitNesse::Slim::Server;

use strict;
use warnings;

use Encode qw/ encode /;
use File::Temp qw/ tempfile /;
use IO::Select;
use IO::Socket::INET;
use POSIX qw/ WNOHANG /;
use Socket qw/ AF_INET inet_pton /;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;

sub new {
  my($class,%options) = @_;

  my $self = bless {} => $class;
  my $max_frame = defined $options{max_frame_bytes}
    ? $options{max_frame_bytes}
    : defined $ENV{TEST_SLIM_MAX_FRAME_BYTES}
      ? $ENV{TEST_SLIM_MAX_FRAME_BYTES} : 67_108_864;
  die "invalid TEST_SLIM_MAX_FRAME_BYTES"
    unless defined($max_frame) && $max_frame =~ /\A[1-9][0-9]*\z/
      && (length($max_frame) < 10
        || length($max_frame) == 10 && $max_frame le '1073741824');
  $self->{MAX_FRAME_BYTES} = 0 + $max_frame;
  $self->{verbose} = $options{verbose} ? 1 : 0;
  $self->{statement_timeout} = $options{statement_timeout};
  $self->{bind_address} = exists($options{bind_address})
    ? $options{bind_address} : '127.0.0.1';
  $self->{bind_address_explicit} = exists($options{bind_address}) ? 1 : 0;
  die 'invalid IPv4 bind address: ' . (defined($self->{bind_address}) ? $self->{bind_address} : '<undefined>')
    unless defined($self->{bind_address}) && !ref($self->{bind_address})
      && defined inet_pton(AF_INET, $self->{bind_address});
  $self->{EXEC} = $self->_new_executor;

  $self;
}

sub _read_exact {
  my($self,$fh,$length,$where,$clean_eof) = @_;

  my $result = "";
  my $wanted = $length;
  while ($length > 0) {
    my $status = sysread $fh, my($buf), $length;

    if (defined $status) {
      if ($status == 0) {
        return if $clean_eof && $result eq "";
        die "truncated $where ($wanted bytes expected, " . length($result) . " received)";
      }
      $result .= $buf;
      $length -= $status;
    }
    else {
      next if $!{EINTR};
      die "sysread: $!";
    }
  }

  $result;
}

sub _write {
  my($self,$fh,$buf) = @_;

  return unless defined $buf;
  my $length = length $buf;
  while ($length > 0) {
    my $status = syswrite $fh, $buf;

    if (defined $status) {
      die "syswrite returned zero" if $status == 0;
      $length -= $status;
      substr($buf, 0, $status) = "";
    }
    else {
      next if $!{EINTR};
      die "syswrite failed: $!";
    }
  }
}

sub _read_message {
  my($self,$fh) = @_;

  my $digits = "";
  while (1) {
    my $char = $self->_read_exact($fh,1,"message length",$digits eq "");
    return unless defined $char;
    last if $char eq ":";

    die "invalid message length prefix"
      unless $char =~ /\A[0-9]\z/ && length($digits) < 32;
    $digits .= $char;
  }

  die "invalid message length prefix"
    unless $digits =~ /\A[0-9]{6,}\z/;
  (my $significant = $digits) =~ s/^0+//;
  $significant = '0' unless length $significant;
  my $maximum = "$self->{MAX_FRAME_BYTES}";
  die "resource limit: message frame exceeds configured maximum"
    if length($significant) > length($maximum)
      || length($significant) == length($maximum) && $significant gt $maximum;

  return $self->_read_exact($fh,0 + $significant,"message payload",0);
}

sub process {
  my($self,$fh) = @_;

  $self->_process_session($fh,$fh,'V0.5',1);
}

sub process_pipe {
  my($self,$input,$output,$diagnostic_output) = @_;

  local $SIG{PIPE} = 'IGNORE';
  $self->_process_session($input,$output,'V0.5',0,$diagnostic_output);
}

sub _process_session {
  my($self,$input,$output,$version,$close_input,$diagnostic_output) = @_;

  my $ok;
  my $error;
  {
    local $self->{EXEC} = $self->_new_executor;
    $ok = eval { $self->_process($input,$output,$version,$diagnostic_output); 1 };
    $error = $@;
  }

  close $input if $close_input && defined fileno($input);
  die $error unless $ok;
  return;
}

sub _new_executor {
  my($self) = @_;
  Test::FitNesse::Slim::ListExecutor->new(
    statement_timeout => $self->{statement_timeout},
  );
}

sub _process {
  my($self,$input,$output,$version,$diagnostic_output) = @_;

  $self->_write($output, "Slim -- $version\n");

  while (1) {
    my $command = $self->_read_message($input);
    return unless defined $command;

    if (lc($command) eq "bye") {
      return;
    }
    else {
      warn "command=[" . length($command) . " bytes]\n" unless $diagnostic_output;
      my @instructions = Test::FitNesse::Slim::List->new(
        $command, limits => { frame_bytes => $self->{MAX_FRAME_BYTES} }
      )->list;
      if ($self->{verbose}) {
        my $request = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
        warn "$0: SLiM request: $request\n";
      }
      my @results = defined($diagnostic_output)
        ? $self->_execute_with_tunneling($diagnostic_output, @instructions)
        : $self->execute(@instructions);

      my $response = Test::FitNesse::Slim::List->new(\@results)->serialize;
      warn "$0: SLiM response: $response\n" if $self->{verbose};
      my $octets = encode "UTF-8", $response;
      die "resource limit: response frame exceeds configured maximum"
        if length($octets) > $self->{MAX_FRAME_BYTES};
      warn "response=[" . length($octets) . " bytes]\n" unless $diagnostic_output;
      $self->_write($output, sprintf "%06d:%s", length($octets), $octets);
    }
  }
}

sub _execute_with_tunneling {
  my($self,$diagnostic_output,@instructions) = @_;
  my($stdout_capture,$stdout_path) = tempfile(UNLINK => 1);
  my($stderr_capture,$stderr_path) = tempfile(UNLINK => 1);
  binmode $stdout_capture or die "binary stdout capture failed: $!";
  binmode $stderr_capture or die "binary stderr capture failed: $!";
  open my $stdout_reader, '<:raw', $stdout_path
    or die "open stdout capture reader failed: $!";
  open my $stderr_reader, '<:raw', $stderr_path
    or die "open stderr capture reader failed: $!";

  open my $saved_stdout, '>&', \*STDOUT
    or die "duplicate fixture stdout failed: $!";
  open my $saved_stderr, '>&', \*STDERR
    or die "duplicate fixture stderr failed: $!";
  binmode $saved_stdout or die "binary saved stdout failed: $!";
  binmode $saved_stderr or die "binary saved stderr failed: $!";

  my $selected = select;
  select STDOUT;
  my $stdout_autoflush = $|;
  select STDERR;
  my $stderr_autoflush = $|;

  my(@results,$execution_error,@tunnel_errors);
  my $executed = eval {
    open STDOUT, '>&', $stdout_capture or die "redirect fixture stdout failed: $!";
    open STDERR, '>&', $stderr_capture or die "redirect fixture stderr failed: $!";
    binmode STDOUT or die "binary fixture stdout failed: $!";
    binmode STDERR or die "binary fixture stderr failed: $!";
    select STDOUT; $| = 1;
    select STDERR; $| = 1;
    select $selected;
    @results = $self->{EXEC}->execute_with(sub {
      for my $capture ([$stdout_capture,$stdout_reader,'SOUT'],
                       [$stderr_capture,$stderr_reader,'SERR']) {
        my($writer,$reader,$channel) = @$capture;
        my $ok = eval { $self->_tunnel_capture($diagnostic_output,$writer,$reader,$channel); 1 };
        push @tunnel_errors, "$channel: $@" unless $ok;
      }
    }, @instructions);
    1;
  };
  $execution_error = $@ unless $executed;

  my $restored = eval {
    open STDOUT, '>&', $saved_stdout or die "restore fixture stdout failed: $!";
    open STDERR, '>&', $saved_stderr or die "restore fixture stderr failed: $!";
    select STDOUT; $| = $stdout_autoflush;
    select STDERR; $| = $stderr_autoflush;
    select $selected;
    1;
  };
  my $restore_error = $@ unless $restored;
  die $restore_error if defined $restore_error;

  for my $capture ([$stdout_capture,$stdout_reader,'SOUT'],
                   [$stderr_capture,$stderr_reader,'SERR']) {
    my($writer,$reader,$channel) = @$capture;
    my $ok = eval { $self->_tunnel_capture($diagnostic_output,$writer,$reader,$channel); 1 };
    push @tunnel_errors, "$channel: $@" unless $ok;
  }
  warn "$0: could not forward tunneled output ($_\n" for @tunnel_errors;
  close $stdout_reader or die "close stdout capture reader failed: $!";
  close $stderr_reader or die "close stderr capture reader failed: $!";
  close $stdout_capture or die "close stdout capture failed: $!";
  close $stderr_capture or die "close stderr capture failed: $!";
  die $execution_error if defined $execution_error;
  return @results;
}

sub _tunnel_capture {
  my($self,$output,$writer,$capture,$channel) = @_;
  my $first_line = 1;
  my $line_started = 0;

  my $offset = tell $capture;
  my @stat = stat $writer;
  die "stat fixture output capture failed: $!" unless @stat;
  my $available = $stat[7] - $offset;
  return if $available <= 0;
  if ($available == 1) {
    my $byte = '';
    my $read = sysread $capture, $byte, 1;
    die "read fixture output capture failed: $!" unless defined($read) && $read == 1;
    return if $byte eq "\n";
    $self->_write($output, "$channel.:");
    $self->_write($output, $byte);
    $self->_write($output, "\n");
    return;
  }

  while (1) {
    my $read = sysread $capture, my($bytes), 8192;
    die "read fixture output capture failed: $!" unless defined $read;
    last if $read == 0;

    while (length $bytes) {
      unless ($line_started) {
        $self->_write($output, $channel . ($first_line ? '.:' : ' :'));
        $line_started = 1;
      }
      my $newline = index($bytes, "\n");
      if ($newline < 0) {
        $self->_write($output, $bytes);
        $bytes = '';
      }
      else {
        my $line = substr($bytes, 0, $newline + 1, '');
        $self->_write($output, $line);
        $line_started = 0;
        $first_line = 0;
      }
    }
  }

  # Tunnel partial output as a terminated record so FitNesse can reconstruct it.
  $self->_write($output, "\n") if $line_started;
  return;
}

sub execute {
  my($self,@instructions) = @_;
  $self->{EXEC}->execute(@instructions);
}

sub run {
  my($self,$port) = @_;

  if (defined($port) && $port eq '1') {
    die 'bind_address cannot be used with pipe mode'
      if $self->{bind_address_explicit};
    return $self->run_pipe;
  }

  my $lsn = $self->_listen_socket($port);

  local $SIG{CHLD} = sub {
    1 while waitpid(-1, WNOHANG) > 0;
  };

  my $sel = IO::Select->new($lsn);
  while (1) {
    my @ready = $sel->can_read;
    next unless @ready;
    foreach my $fh (@ready) {
      if ($fh == $lsn) {
        my $new = $lsn->accept;
        unless ($new) {
          next if $!{EINTR};
          warn "$0: accept failed: $!\n";
          next;
        }

        my $pid = fork();
        unless (defined $pid) {
          warn "$0: fork failed: $!\n";
          close $new;
          next;
        }

        if ($pid == 0) {
          close $lsn;
          $SIG{CHLD} = "DEFAULT";
          my $ok = eval { $self->process($new); 1 };
          unless ($ok) {
            my $error = $@;
            warn "$0: SLiM client failed: $error\n";
            close $new if defined fileno($new);
          }
          exit($ok ? 0 : 1);
        }

        close $new;
      }
      else {
        warn "$0: unexpected input from fd " . fileno($fh) . "\n";
      }
    }
  }
}

sub _listen_socket {
  my($self,$port) = @_;
  my $address = $self->{bind_address};
  my $packed = inet_pton(AF_INET, $address);
  my @octets = unpack 'C4', $packed;
  warn "$0: warning: TCP SLiM on $address is unauthenticated; use only on a trusted network\n"
    if $self->{bind_address_explicit} && $octets[0] != 127;

  my $listener = IO::Socket::INET->new(
    # Winsock permits an SO_REUSEADDR socket to bind an occupied endpoint.
    # Keep the existing Unix restart behavior without enabling that on Windows.
    ReuseAddr => $^O eq 'MSWin32' ? 0 : 1,
    Listen    => 16,
    LocalAddr => $address,
    LocalPort => $port,
    Proto     => 'tcp',
  );
  die "$0: create listen socket on $address:$port failed: $!\n"
    unless $listener;
  return $listener;
}

sub run_pipe {
  my($self) = @_;

  open my $protocol_output, '>&', \*STDOUT
    or die "$0: duplicate SLiM stdout failed: $!\n";
  open my $diagnostic_output, '>&', \*STDERR
    or die "$0: duplicate diagnostic stderr failed: $!\n";
  binmode $protocol_output or die "$0: binary SLiM stdout failed: $!\n";
  binmode $diagnostic_output or die "$0: binary diagnostic stderr failed: $!\n";
  binmode STDIN or die "$0: binary SLiM stdin failed: $!\n";

  # Keep fd 1 away from SLiM framing even when a fixture, child process, or
  # native routine writes directly to stdout. The saved handle remains the
  # only protocol-output path. FitNesse collects this diagnostic stream.
  open STDOUT, '>&', STDERR
    or die "$0: redirect fixture stdout failed: $!\n";
  binmode STDOUT or die "$0: binary fixture stdout redirection failed: $!\n";
  my $selected = select STDOUT;
  $| = 1;
  select $selected;

  $self->process_pipe(\*STDIN,$protocol_output,$diagnostic_output);
  close $protocol_output or die "$0: close SLiM stdout failed: $!\n";
  close $diagnostic_output or die "$0: close diagnostic stderr failed: $!\n";
  return;
}

1;

=head1 NAME

Test::FitNesse::Slim::Server - Serve FitNesse SLiM sessions over TCP or pipes

=head1 DESCRIPTION

The server owns transport framing and the per-session
L<Test::FitNesse::Slim::ListExecutor>. TCP connections and the port-1 stdin/stdout
transport share the same frame reader, SLiM deserializer, executor, and
response serializer. Each accepted connection receives isolated fixture,
library, and symbol state.

Pipe protocol bytes are written through a dedicated stdout handle. Fixture
stdout and stderr are captured separately and emitted as FitNesse v0.5
diagnostic records on stderr. TCP diagnostics use the normal process
diagnostic stream. Transport and resource errors close the affected session
and are reported on stderr; they do not manufacture a response for an
incomplete message.

=head1 METHODS

=head2 new

    my $server = Test::FitNesse::Slim::Server->new(%options);

Create a server. C<verbose> enables request/response diagnostics,
C<statement_timeout> sets an optional per-invocation limit,
C<max_frame_bytes> overrides the outer frame limit, and C<bind_address>
selects the TCP listener's numeric IPv4 address. The bind address defaults
to C<127.0.0.1>; explicitly configured non-loopback addresses produce an
unauthenticated-listener warning when the TCP listener starts. Binding
configuration cannot be used with pipe mode. The frame limit may also be
configured with C<TEST_SLIM_MAX_FRAME_BYTES> and defaults to 64 MiB. Invalid
limits and bind addresses throw an error during construction.

=head2 run

    $server->run($port);

    my $remote = Test::FitNesse::Slim::Server->new(bind_address => '0.0.0.0');
    $remote->run(8099);

Run the selected transport. Port C<1> serves a single v0.5 pipe session
over inherited standard input/output. Other valid ports create an IPv4 TCP
listener at C<bind_address> (loopback by default) and serve clients. The
method runs until the pipe session ends or the TCP listener is stopped.

=head2 process

Process one connected TCP session on a bidirectional filehandle. This
method is primarily used by the listener and transport tests.

=head2 process_pipe

Process one pipe session using distinct input and protocol-output
filehandles. An optional diagnostic-output handle receives v0.5 tunneling
records.

=head2 execute

Execute decoded instruction array references in the current session. This
is a small integration-test hook; transport sessions normally use the
internal list executor directly.

=head2 run_pipe

Prepare the standard handles for a FitNesse-managed child and run one pipe
session. Protocol bytes go to the preserved stdout descriptor; ordinary
stdout is redirected away from it.

=head1 PROTOCOL

The outer frame prefix counts UTF-8 payload bytes. Inner SLiM string
lengths count UTF-16 code units. The server advertises
C<Slim -- V0.5\n>. A framed C<bye> ends a session. See
C<docs/slim-protocol-malformed-input.md> and
C<docs/slim-pipe-transport.md> for framing limits and transport policy.

=cut
