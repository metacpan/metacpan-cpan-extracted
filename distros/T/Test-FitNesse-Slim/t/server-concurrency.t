#! perl

use strict;
use utf8;
use warnings;

use IO::Select;
use IO::Socket::INET;
use POSIX qw(WNOHANG);
use Socket qw(SOCK_STREAM);
use lib "lib", "t/lib";

use Test::More;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::Server;

sub free_port {
  my $socket = IO::Socket::INET->new(
    LocalAddr => "127.0.0.1",
    LocalPort => 0,
    Listen    => 1,
    Proto     => "tcp",
  ) or die "cannot reserve local port: $!";
  my $port = $socket->sockport;
  close $socket;
  $port;
}

sub connect_to_server {
  my($port) = @_;
  for (1 .. 40) {
    my $socket = IO::Socket::INET->new(
      PeerAddr => "127.0.0.1",
      PeerPort => $port,
      Proto    => "tcp",
      Timeout  => 0.2,
    );
    if ($socket) {
      $socket->autoflush(1);
      return $socket;
    }
    select undef, undef, undef, 0.05;
  }
  return;
}

sub read_exact {
  my($socket,$length,$timeout) = @_;
  my $select = IO::Select->new($socket);
  my $value = "";
  while (length($value) < $length) {
    return unless $select->can_read($timeout);
    my $count = sysread $socket, my($buffer), $length - length($value);
    return unless defined($count) && $count > 0;
    $value .= $buffer;
  }
  return $value;
}

sub read_line {
  my($socket,$timeout) = @_;
  my $line = "";
  while (length($line) < 100) {
    my $char = read_exact($socket, 1, $timeout);
    return unless defined $char;
    $line .= $char;
    return $line if $char eq "\n";
  }
  return;
}

sub read_frame {
  my($socket,$timeout) = @_;
  my $header = read_exact($socket, 7, $timeout) or return;
  return unless $header =~ /\A([0-9]{6}):\z/;
  read_exact($socket, $1, $timeout);
}

sub send_statements {
  my($socket,$statements) = @_;
  my $wire = Test::FitNesse::Slim::List->new($statements)->serialize;
  print {$socket} sprintf("%06d:%s", length($wire), $wire);
  my $response = read_frame($socket, 2);
  return unless defined $response;
  return [ Test::FitNesse::Slim::List->new($response)->list ];
}

sub assert_results {
  my($actual,$expected,$label) = @_;
  is_deeply($actual, $expected, $label);
}

my $port = free_port();
my $server_pid = fork();
die "fork server: $!" unless defined $server_pid;
if (!$server_pid) {
  open STDOUT, ">", "/dev/null" or die "redirect stdout: $!";
  open STDERR, ">", "/dev/null" or die "redirect stderr: $!";
  Test::FitNesse::Slim::Server->new->run($port);
  exit 0;
}

my @sockets;
my $a = connect_to_server($port);
push @sockets, $a if $a;
ok($a, "connection A reaches the listener");
is(read_line($a, 2), "Slim -- V0.5\n", "connection A receives the SLiM greeting") if $a;

my $b;
my $can_run_b = 0;
if ($a) {
  my $a_results = send_statements($a, [
    ["i1", "import", "fitnesse.slim.test"],
    ["i2", "import", "fitnesse.fixtures"],
    ["m1", "make", "actor", "TestSlim"],
    ["c1", "call", "actor", "setString", "state-from-A"],
    ["s1", "callAndAssign", "shared", "actor", "echoString", "value-from-A"],
    ["m2", "make", "library1", "EchoFixture"],
  ]);
  assert_results($a_results, [
    ["i1", "OK"], ["i2", "OK"], ["m1", "OK"], ["c1", "state-from-A"],
    ["s1", "value-from-A"], ["m2", "OK"],
  ], "connection A initializes its actor, symbol, and library while staying open");

  $b = connect_to_server($port);
  push @sockets, $b if $b;
  $can_run_b = $b && (read_line($b, 2) // "") eq "Slim -- V0.5\n";
}
ok($can_run_b, "connection B receives a greeting while connection A remains open");

SKIP: {
  skip "the listener did not accept a second active connection", 2 unless $can_run_b;

  my $b_results = send_statements($b, [
    ["m0", "make", "unimported", "TestSlim"],
    ["i1", "import", "fitnesse.slim.test"],
    ["i2", "import", "fitnesse.fixtures"],
    ["m1", "make", "actor", "TestSlim"],
    ["c1", "call", "actor", "getStringArg"],
    ["c0", "call", "actor", "echo", "before-library"],
    ["s1", "callAndAssign", "shared", "actor", "echoString", "value-from-B"],
    ["c2", "call", "null", "cloneSymbol", '$shared'],
    ["m2", "make", "library1", "EchoFixture"],
    ["c3", "call", "actor", "echo", "B"],
  ]);
  assert_results($b_results, [
    ["m0", "__EXCEPTION__:message:<<NO_CLASS TestSlim>>"],
    ["i1", "OK"], ["i2", "OK"], ["m1", "OK"], ["c1", "null"],
    ["c0", "__EXCEPTION__:message:<<NO_METHOD_IN_CLASS echo[1] Fitnesse::Slim::Test::TestSlim>>"],
    ["s1", "value-from-B"], ["c2", "value-from-B"], ["m2", "OK"], ["c3", "B"],
  ], "connection B starts with independent actor, symbol, and library state");

  my $a_results = send_statements($a, [
    ["c1", "call", "actor", "getStringArg"],
    ["c2", "call", "null", "cloneSymbol", '$shared'],
    ["c3", "call", "actor", "echo", "A"],
  ]);
  assert_results($a_results, [
    ["c1", "state-from-A"], ["c2", "value-from-A"], ["c3", "A"],
  ], "connection A retains its actor, symbol, and library state");

  close $b;
  undef $b;
}

my $malformed = connect_to_server($port);
push @sockets, $malformed if $malformed;
ok($malformed, "listener accepts another client while A remains active") if $can_run_b;
if ($malformed) {
is(read_line($malformed, 2), "Slim -- V0.5\n", "malformed-input client receives its greeting") if $can_run_b;
  print {$malformed} "000007:invalid";
  my $malformed_closed = !defined read_line($malformed, 2);
  ok($malformed_closed, "malformed frame closes only its client session") if $can_run_b;
  close $malformed;
  undef $malformed;
}

if ($a && $can_run_b) {
  my $a_results = send_statements($a, [["c4", "call", "actor", "getStringArg"]]);
  assert_results($a_results, [["c4", "state-from-A"]], "malformed and disconnected clients leave A active");
}

if ($a) {
  close $a;
  undef $a;
}

my $survivor = connect_to_server($port);
push @sockets, $survivor if $survivor;
ok($survivor, "listener accepts a new client after disconnect and malformed input") if $can_run_b;
if ($survivor) {
is(read_line($survivor, 2), "Slim -- V0.5\n", "new session receives a greeting after prior sessions close") if $can_run_b;
  my $results = send_statements($survivor, [["i1", "import", "fitnesse.slim.test"]]);
  assert_results($results, [["i1", "OK"]], "listener processes valid statements after malformed input") if $can_run_b;
  print {$survivor} "000003:bye";
  close $survivor;
  undef $survivor;
}

close $_ for grep { $_ } @sockets;
select undef, undef, undef, 0.1;
kill "TERM", $server_pid;
waitpid($server_pid, 0);

done_testing();
