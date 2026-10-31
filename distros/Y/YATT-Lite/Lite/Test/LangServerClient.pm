package YATT::Lite::Test::LangServerClient;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use IPC::Open2;
use IO::Select;
use IO::Handle;
use POSIX qw(WNOHANG);
use JSON::MaybeXS;
use Time::HiRes qw(time);

=head1 NAME

YATT::Lite::Test::LangServerClient - drive YATT::Lite::LanguageServer over pipes (for tests)

=head1 SYNOPSIS

  my $cl = YATT::Lite::Test::LangServerClient->new(
    server => "$FindBin::Bin/../Lite/LanguageServer.pm",
  );
  my $res = $cl->call(initialize => {rootUri => "file://$root", capabilities => {}});

  # Several frames in ONE write (what eglot does: didChange + definition):
  my $req = $cl->make_request('textDocument/definition', {...});
  $cl->send_messages($cl->make_notification('textDocument/didOpen', {...}), $req);
  my $def = $cl->wait_response($req->{id});

  my ($shutdown_res, $exit_code) = $cl->shutdown;

=head1 DESCRIPTION

Spawns C<LanguageServer.pm --quiet server> as a child process and speaks
JSON-RPC (Content-Length framing) with it. Every read is bounded by
C<timeout> seconds so a stalled server fails a test instead of hanging it.
Notifications from the server (publishDiagnostics...) are queued and can be
inspected with C<take_notifications>.

=cut

sub new {
  my ($class, %opts) = @_;
  my $self = bless {
    timeout => 20,
    args => [qw(--quiet server)],
    _buf => '',
    _next_id => 1,
    _notifications => [],
    _others => [],
    %opts,
  }, $class;
  defined $self->{server}
    or croak "server (path to LanguageServer.pm) is required";
  $self->spawn;
  $self;
}

sub spawn {
  my ($self) = @_;
  my @inc = map {"-I$_"} grep {defined and not ref} @INC;
  my ($out, $in);
  my $pid = open2($out, $in, $^X, @inc, $self->{server}, @{$self->{args}});
  binmode $_ for $in, $out;
  $in->autoflush(1);
  @{$self}{qw(pid in out sel)} = ($pid, $in, $out, IO::Select->new($out));
  $self;
}

sub pid { $_[0]{pid} }

#========================================
# Message construction
#========================================

sub frame {
  my ($self, $msg) = @_;
  my $body = ref $msg ? encode_json($msg) : $msg;
  "Content-Length: " . length($body) . "\r\n\r\n" . $body;
}

sub make_request {
  my ($self, $method, $params, $id) = @_;
  $id //= $self->{_next_id}++;
  +{jsonrpc => '2.0', id => $id, method => $method, params => $params};
}

sub make_notification {
  my ($self, $method, $params) = @_;
  +{jsonrpc => '2.0', method => $method, params => $params};
}

#========================================
# Sending
#========================================

# All messages are joined and written with ONE syswrite, so the server
# sees them in a single read (pipelined frames).
sub send_messages {
  my ($self, @msgs) = @_;
  $self->send_raw(join "", map {$self->frame($_)} @msgs);
}

sub send_raw {
  my ($self, $bytes) = @_;
  my $off = 0;
  while ($off < length $bytes) {
    my $cnt = syswrite($self->{in}, $bytes, length($bytes) - $off, $off);
    croak "write to language server failed: $!" unless defined $cnt;
    $off += $cnt;
  }
  $off;
}

sub request {
  my ($self, $method, $params) = @_;
  my $req = $self->make_request($method, $params);
  $self->send_messages($req);
  $req->{id};
}

sub notify {
  my ($self, $method, $params) = @_;
  $self->send_messages($self->make_notification($method, $params));
}

# request + wait_response
sub call {
  my ($self, $method, $params) = @_;
  my $id = $self->request($method, $params);
  $self->wait_response($id);
}

#========================================
# Receiving
#========================================

# Read one framed message before $deadline (absolute time).
# Returns undef on timeout or EOF.
sub read_message {
  my ($self, $deadline) = @_;
  $deadline //= time + $self->{timeout};
  while (1) {
    if ((my $sep = index($self->{_buf}, "\r\n\r\n")) >= 0) {
      my $header = substr($self->{_buf}, 0, $sep);
      my ($len) = $header =~ /Content-Length:\s*(\d+)/i
        or croak "bad header from language server: $header";
      if (length($self->{_buf}) >= $sep + 4 + $len) {
        substr($self->{_buf}, 0, $sep + 4, '');
        my $body = substr($self->{_buf}, 0, $len, '');
        return decode_json($body);
      }
    }
    my $left = $deadline - time;
    return undef if $left <= 0;
    $self->{sel}->can_read($left) or return undef;
    my $cnt = sysread($self->{out}, $self->{_buf}, 65536, length $self->{_buf});
    return undef unless $cnt;
  }
}

# Wait for the response to request $id. Other responses and all
# notifications are queued meanwhile. Returns undef on timeout/EOF.
sub wait_response {
  my ($self, $id, $timeout) = @_;
  for my $i (0 .. $#{$self->{_others}}) {
    my $m = $self->{_others}[$i];
    if (defined $m->{id} and $m->{id} eq $id) {
      splice @{$self->{_others}}, $i, 1;
      return $m;
    }
  }
  my $deadline = time + ($timeout // $self->{timeout});
  while (defined (my $m = $self->read_message($deadline))) {
    if (defined $m->{method}) {
      push @{$self->{_notifications}}, $m;
    } elsif (defined $m->{id}) {
      return $m if $m->{id} eq $id;
      push @{$self->{_others}}, $m;
    } else {
      # error response without id (e.g. ParseError). Keep for inspection.
      push @{$self->{_others}}, $m;
    }
  }
  return undef;
}

sub notifications { @{$_[0]{_notifications}} }

sub take_notifications {
  my ($self) = @_;
  my @n = @{$self->{_notifications}};
  @{$self->{_notifications}} = ();
  @n;
}

sub other_messages { @{$_[0]{_others}} }

#========================================
# Termination
#========================================

# Returns ($shutdown_response, $exit_code). $exit_code is undef when
# the server did not exit within timeout (it is then killed).
sub shutdown {
  my ($self) = @_;
  my $res = $self->call('shutdown', undef);
  $self->notify('exit', undef);
  my $code = $self->wait_exit;
  ($res, $code);
}

sub wait_exit {
  my ($self) = @_;
  my $pid = delete $self->{pid} or return undef;
  my $deadline = time + $self->{timeout};
  while (time < $deadline) {
    my $got = waitpid($pid, WNOHANG);
    return $? >> 8 if $got == $pid;
    return undef if $got < 0;
    select(undef, undef, undef, 0.05);
  }
  kill TERM => $pid;
  waitpid($pid, 0);
  return undef;
}

sub DESTROY {
  my ($self) = @_;
  if (my $pid = delete $self->{pid}) {
    kill TERM => $pid;
    waitpid($pid, 0);
  }
}

1;
