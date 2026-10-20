#! perl

use strict;
use warnings;

use IO::Socket::INET;
use lib "lib";
use Test::More;
use Test::FitNesse::Slim::List;

plan skip_all => "set RUN_PAGE_DRIVER_INTEGRATION=1 with FitNesse and the Perl SLiM server running"
  unless $ENV{RUN_PAGE_DRIVER_INTEGRATION};

sub read_exact {
  my($socket,$length) = @_;
  my $value = "";
  while (length($value) < $length) {
    my $count = sysread $socket, my($buffer), $length - length($value);
    return unless defined($count) && $count > 0;
    $value .= $buffer;
  }
  return $value;
}

sub read_line {
  my($socket) = @_;
  my $line = "";
  while (length $line < 100) {
    my $char = read_exact($socket, 1) // return;
    $line .= $char;
    return $line if $char eq "\n";
  }
  return;
}

sub exchange {
  my($socket,$statements) = @_;
  my $wire = Test::FitNesse::Slim::List->new($statements)->serialize;
  print {$socket} sprintf("%06d:%s", length($wire), $wire) or die "write SLiM request: $!";
  my $header = read_exact($socket, 7) or die "read SLiM response length";
  $header =~ /^([0-9]{6}):$/ or die "invalid SLiM response header: $header";
  my $response = read_exact($socket, $1) or die "read SLiM response";
  return [ Test::FitNesse::Slim::List->new($response)->list ];
}

my $host = $ENV{TEST_SLIM_HOST} || "127.0.0.1";
my $port = $ENV{TEST_SLIM_PORT} || 8099;
my $socket = IO::Socket::INET->new(
  PeerAddr => $host, PeerPort => $port, Proto => "tcp", Timeout => 5,
);
ok($socket, "outer SLiM connection opens") or BAIL_OUT("start the external Perl SLiM server first");
$socket->autoflush(1);
is(read_line($socket), "Slim -- V0.5\n", "outer SLiM session receives its greeting");

my $page = "TestSlimPageDriverNested$$";
my $content = join "\n",
  "!define TEST_SYSTEM {slim}",
  "|import|",
  "|fitnesse.fixtures|",
  "|fitnesse.slim.test|",
  "|script|echo fixture|",
  "|check|echo|nested page ok|nested page ok|";
my $results = exchange($socket, [
  ["i1", "import", "fitnesse.fixtures"],
  ["i2", "import", "fitnesse.slim.test"],
  ["m1", "make", "library1", "PageDriver"],
  ["m2", "make", "actor", "TestSlim"],
  ["c1", "call", "library1", "createPageWithContent", $page, $content],
  ["c2", "call", "library1", "makeATestPage", $page],
  ["c3", "call", "library1", "requestPage", "$page?test"],
  ["c4", "call", "library1", "contentContains", 'class="pass"'],
  ["c5", "call", "library1", "contentContains", "nested page ok"],
  ["c6", "call", "actor", "echoString", "outer connection is usable"],
]);
is_deeply($results, [
  ["i1", "OK"], ["i2", "OK"], ["m1", "OK"], ["m2", "OK"],
  ["c1", "null"], ["c2", "null"], ["c3", 200],
  ["c4", "true"], ["c5", "true"], ["c6", "outer connection is usable"],
], "nested FitNesse execution completes and the original SLiM session remains usable");

my $bye = "bye";
print {$socket} sprintf("%06d:%s", length($bye), $bye);
close $socket;
done_testing();
