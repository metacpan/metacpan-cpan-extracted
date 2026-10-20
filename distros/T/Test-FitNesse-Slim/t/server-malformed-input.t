#! perl

use strict;
use utf8;
use warnings;
use Encode qw(encode);
use Errno qw(ECONNRESET EPIPE ENOTCONN);
use IO::Select;
use IO::Socket::INET;
use Socket qw(SHUT_WR);
use lib 'lib', 't/lib';
use Test::More;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::Server;

sub free_port {
  my $socket = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
    Listen => 1, Proto => 'tcp') or die "reserve port: $!";
  my $port = $socket->sockport;
  close $socket;
  return $port;
}

sub connect_client {
  my($port) = @_;
  for (1 .. 50) {
    my $socket = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
      Proto => 'tcp', Timeout => 0.2);
    if ($socket) {
      $socket->autoflush(1);
      my $greeting = read_line($socket,2);
      return $socket if defined($greeting) && $greeting eq "Slim -- V0.5\n";
      close $socket;
    }
    select undef,undef,undef,0.05;
  }
  return;
}

sub read_exact {
  my($socket,$length,$timeout) = @_;
  my $ready = IO::Select->new($socket);
  my $value = '';
  while (length($value) < $length) {
    return unless $ready->can_read($timeout);
    my $got = sysread($socket,my $chunk,$length-length($value));
    return unless defined($got) && $got > 0;
    $value .= $chunk;
  }
  return $value;
}

sub read_line {
  my($socket,$timeout) = @_;
  my $line = '';
  while (length($line) < 64) {
    my $char = read_exact($socket,1,$timeout);
    return unless defined $char;
    $line .= $char;
    return $line if $char eq "\n";
  }
  return;
}

sub read_frame {
  my($socket,$timeout) = @_;
  my $header = '';
  while (length($header) < 34) {
    my $char = read_exact($socket,1,$timeout);
    return unless defined $char;
    $header .= $char;
    last if $char eq ':';
  }
  return unless $header =~ /\A([0-9]{6,}):\z/;
  return read_exact($socket,0+$1,$timeout);
}

sub wait_closed {
  my($socket,$timeout) = @_;
  my $ready = IO::Select->new($socket);
  return 0 unless $ready->can_read($timeout);
  my $count = sysread($socket,my $byte,1);
  return 1 if !defined($count) && ($!{ECONNRESET} || $!{EPIPE} || $!{ENOTCONN});
  return defined($count) && $count == 0;
}

sub send_bytes {
  my($socket,$bytes,$fragmented) = @_;
  my $offset = 0;
  my $step = $fragmented ? 1 : length($bytes);
  while ($offset < length($bytes)) {
    my $chunk = substr($bytes,$offset,$step);
    my $written = syswrite($socket,$chunk);
    return unless defined($written) && $written > 0;
    $offset += $written;
    select undef,undef,undef,0.002 if $fragmented;
  }
  return 1;
}

sub frame {
  my($payload,$expanded) = @_;
  my $size = length($payload);
  my $prefix = $expanded ? sprintf('%08d:',$size) : sprintf('%06d:',$size);
  return $prefix . $payload;
}

sub request {
  my($socket,$instructions,$fragmented) = @_;
  my $text = Test::FitNesse::Slim::List->new($instructions)->serialize;
  my $bytes = encode('UTF-8',$text);
  return unless send_bytes($socket,frame($bytes,$fragmented),$fragmented);
  my $reply = read_frame($socket,3);
  return unless defined $reply;
  return [ Test::FitNesse::Slim::List->new($reply)->list ];
}

sub probe_listener {
  my($port) = @_;
  my $socket = connect_client($port) or return;
  my $result = request($socket,[[probe => import => 'fitnesse.slim.test']]);
  send_bytes($socket,'000003:bye');
  close $socket;
  return $result;
}

my $marker_path = "/tmp/test-slim-marker-$$";
unlink $marker_path;
my $owner_pid = $$;
my $port = free_port();
my $pid = fork();
die "fork: $!" unless defined $pid;
if (!$pid) {
  $ENV{TEST_SLIM_MAX_FRAME_BYTES} = 2048;
  open STDOUT,'>','/dev/null' or die "redirect stdout: $!";
  open STDERR,'>','/dev/null' or die "redirect stderr: $!";
  Test::FitNesse::Slim::Server->new->run($port);
  exit 0;
}

my @clients;
END {
  if ($$ == $owner_pid) {
    my $test_status = $?;
    close $_ for grep { $_ } @clients;
    if ($pid) {
      kill 'TERM',$pid;
      waitpid($pid,0);
    }
    unlink $marker_path if $marker_path;
    $? = $test_status;
  }
}

my $client = connect_client($port);
push @clients,$client if $client;
ok($client,'raw TCP client receives the SLiM greeting');

SKIP: {
  skip 'listener failed to start', 15 unless $client;
  my $first = request($client,[[i => import => 'fitnesse.slim.test']],1);
  is_deeply($first,[['i','OK']],'fragmented valid frame is read exactly');
  my $unicode = request($client,[
    [m => make => actor => 'TestSlim'],
    [c => call => actor => 'echoString' => 'München / Tartu õun / Mae govannen, mellon nín / 😀 é'],
  ]);
  is_deeply($unicode,[['m','OK'],['c','München / Tartu õun / Mae govannen, mellon nín / 😀 é']],
    'German, Estonian, Sindarin, supplementary, and combining text round-trip over the socket');
  my $second = request($client,[[i2 => import => 'fitnesse.fixtures']],1);
  is_deeply($second,[['i2','OK']],'multiple requests remain valid on one connection');

  my $malformed = request($client,[['bad','unknownOperation']]);
  like($malformed->[0][1],qr/^__EXCEPTION__:message:<<MALFORMED_INSTRUCTION/,
    'well-formed serialization with malformed instruction returns standard exception');
  my $after_bad_instruction = request($client,[[i3 => import => 'fitnesse.slim.test']]);
  is_deeply($after_bad_instruction,[['i3','OK']],
    'valid instruction is handled after malformed instruction on the same connection');
  send_bytes($client,'000003:bye');
  close $client;
  undef $client;

  my $boundary_eof = connect_client($port);
  push @clients,$boundary_eof if $boundary_eof;
  ok($boundary_eof,'listener accepts a client that will close at a message boundary');
  close $boundary_eof if $boundary_eof;
  is_deeply(probe_listener($port),[['probe','OK']],
    'clean boundary EOF ends one session without affecting the listener');

  my @cases = (
    ['invalid frame prefix', 'not-a-frame' . frame(encode('UTF-8',Test::FitNesse::Slim::List->new([[i => import => 'fitnesse.slim.test']])->serialize))],
    ['declared length shorter than payload', sub {
      my $payload = encode('UTF-8',Test::FitNesse::Slim::List->new([[short => import => 'fitnesse.slim.test']])->serialize);
      return sprintf('%06d:',$payload ? length($payload)-1 : 0) . $payload;
    }->()],
    ['truncated payload', '000020:[000001:000001:x:', 1],
    ['oversized declaration', '0002049:'],
    ['invalid UTF-8 payload', "000001:\xff"],
  );
  for my $case (@cases) {
    my($name,$bytes,$half_close) = @$case;
    my $bad = connect_client($port);
    push @clients,$bad if $bad;
    ok($bad,"listener accepts a client before $name") or next;
    ok(send_bytes($bad,$bytes),"send $name");
    shutdown($bad,SHUT_WR) if $half_close;
    ok(wait_closed($bad,2),"$name closes only its connection without a response");
    close $bad;
    my $probe = probe_listener($port);
    is_deeply($probe,[['probe','OK']],"listener remains usable after $name");
  }

  my $bad_payload = '[000002:'
    . encoded_item(Test::FitNesse::Slim::List->new(
        ['atomic','make','marker','Fitnesse::Slim::Test::ProtocolMarker',$marker_path]
      )->serialize)
    . '000010:abc]';
  sub encoded_item {
    my($item) = @_;
    return sprintf('%06d:%s:',length($item),$item);
  }
  my $malformed_batch = connect_client($port);
  push @clients,$malformed_batch if $malformed_batch;
  ok($malformed_batch,'listener accepts a client for an atomicity check');
  if ($malformed_batch) {
    send_bytes($malformed_batch,frame(encode('UTF-8',$bad_payload)));
    ok(wait_closed($malformed_batch,2),'corrupt later element closes the batch connection');
    close $malformed_batch;
    ok(!-e $marker_path,
      'valid state-mutating first instruction is not executed before later corruption');
    is_deeply(probe_listener($port),[['probe','OK']],
      'listener remains usable after atomic batch rejection');
  }
}

done_testing;
