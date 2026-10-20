#! perl

use strict;
use warnings;

use IO::Select;
use IO::Socket::INET;
use IPC::Open3;
use POSIX qw(WNOHANG);
use Symbol qw(gensym);
use Time::HiRes qw(sleep time);
use Test::More;

my @children;
END {
  for my $child (@children) {
    kill 'TERM', $child;
    waitpid($child, 0);
  }
}

sub unused_port {
  my $socket = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0,
    Proto => 'tcp', Listen => 1, ReuseAddr => 1,
  ) or die "allocate test port: $!";
  my $port = $socket->sockport;
  close $socket;
  return $port;
}

my $error = gensym;
my $pid = open3(my $input,my $output,$error,
  $^X,'-Ilib','-It/lib','bin/perl-slim','-x','1');
close $input;
my $stdout = do { local $/; <$output> // '' };
my $stderr = do { local $/; <$error> // '' };
waitpid($pid,0);
ok(($? >> 8) != 0,'unknown runner flags are rejected');
like($stderr,qr/Usage: .*perl-slim/,'invalid invocation explains supported arguments');
is($stdout,'','invalid invocation writes no protocol bytes to stdout');

for my $arguments (
  ['-s','0','1'], ['-s','1'], ['-s','1','-s','2','1'],
  ['--bind-address'],
  ['--bind-address','127.0.0.1','--bind-address','0.0.0.0','8099'],
  ['--bind-address','999.1.1.1','8099'],
  ['--bind-address','localhost','8099'],
  ['--bind-address','127.0.0.1','1'],
) {
  $error = gensym;
  $pid = open3($input,$output,$error,
    $^X,'-Ilib','-It/lib','bin/perl-slim',@$arguments);
  close $input;
  my $invalid_error = do { local $/; <$error> // '' };
  waitpid($pid,0);
  isnt($? >> 8,0,'invalid -s argument is rejected');
  if ($arguments->[0] eq '--bind-address'
      && @$arguments == 3
      && $arguments->[1] ne '127.0.0.1') {
    like($invalid_error,qr/invalid IPv4 bind address/,
      'malformed bind address has a specific diagnostic');
  }
  else {
    like($invalid_error,qr/Usage: .*perl-slim/,'invalid CLI arguments report usage');
  }
}

my $port = unused_port();
$error = gensym;
$pid = open3($input,$output,$error,
  $^X,'-Ilib','-It/lib','bin/perl-slim','-v','-s','1',
  '--bind-address','127.0.0.1',"$port");
push @children, $pid;
binmode $_ for ($input,$output,$error);
my $socket;
my $deadline = time + 5;
while (time < $deadline) {
  $socket = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 0.2,
  );
  last if $socket;
  select undef,undef,undef,0.02;
}
ok($socket,'-v -s 1 with explicit loopback starts a TCP listener');
if ($socket) {
  local $/ = "\n";
  is(<$socket>,"Slim -- V0.5\n",'TCP listener sends the pinned FitNesse v0.5 greeting');
  syswrite($socket,'000003:bye');
  close $socket;
}
kill 'TERM',$pid;
waitpid($pid,0);
@children = grep { $_ != $pid } @children;
is($? & 127,15,'TCP CLI process is explicitly reaped after handshake verification');

my $wildcard_port = unused_port();
$error = gensym;
$pid = open3($input,$output,$error,
  $^X,'-Ilib','-It/lib','bin/perl-slim','--bind-address','0.0.0.0',"$wildcard_port");
push @children, $pid;
binmode $_ for ($input,$output,$error);
my $wildcard_socket;
$deadline = time + 5;
while (time < $deadline) {
  $wildcard_socket = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1', PeerPort => $wildcard_port,
    Proto => 'tcp', Timeout => 0.2,
  );
  last if $wildcard_socket;
  sleep 0.02;
}
ok($wildcard_socket,'CLI explicitly binds to all IPv4 interfaces and accepts loopback clients');
my $warning = '';
if ($wildcard_socket) {
  local $/ = "\n";
  is(<$wildcard_socket>,"Slim -- V0.5\n",'explicit wildcard listener retains the v0.5 greeting');
  my $select = IO::Select->new($error);
  $warning = <$error> if $select->can_read(2);
  like($warning,qr/0\.0\.0\.0.*unauthenticated.*trusted network/,
    'remote-binding warning is emitted to stderr');
  syswrite($wildcard_socket,'000003:bye');
  close $wildcard_socket;
}
else {
  fail('explicit wildcard listener retains the v0.5 greeting');
  fail('remote-binding warning is emitted to stderr');
}
kill 'TERM',$pid;
waitpid($pid,0);
@children = grep { $_ != $pid } @children;
is($? & 127,15,'explicit-bind TCP CLI process is terminated and reaped');

done_testing;
