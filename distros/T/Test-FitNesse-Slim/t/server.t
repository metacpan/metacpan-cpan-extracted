#! perl

use strict;
use utf8;
use warnings;

use IO::Handle;
use Socket;
use lib "t/lib";

use Test::More tests => 10;

BEGIN {
  use_ok "Test::FitNesse::Slim::Server"
    or BAIL_OUT "cannot use Test::FitNesse::Slim::Server";
}

my($slim,$fitnesse);
my $server;
sub test (&) {
  my($block) = @_;

  socketpair $slim, $fitnesse, AF_UNIX, SOCK_STREAM, PF_UNSPEC
    or BAIL_OUT "socketpair failed: $!";

  $_->autoflush(1) for $slim, $fitnesse;

  $server = Test::FitNesse::Slim::Server->new
    or BAIL_OUT "failed to instantiate server";

  $block->();

  for ($slim, $fitnesse) {
    close $_;
    undef $_;
  }
}

test {
  print $fitnesse "000003:bye";
  $fitnesse->flush;

  $server->process($slim);

  my $reply = <$fitnesse>;
  is $reply, "Slim -- V0.5\n", "proper Slim greeting";
};

test {
  my $import = "000074:[000001:000057:[000003:000010:import_0_0:000006:import:000008:MyModule:]:]";

  print $fitnesse $import . "000003:bye";
  $fitnesse->flush;

  $server->process($slim);

  my @replies = <$fitnesse>;

  my $ok = Test::FitNesse::Slim::List->new([qw/ import_0_0 OK /])->serialize;
  my @expected = (
    "Slim -- V0.5\n",
    "000054:[000001:000037:[000002:000010:import_0_0:000002:OK:]:]",
    #sprintf("%06d:%s", length $ok, $ok),
  );
  is_deeply \@replies, \@expected, "process import command";
};

test {
  my $tablename = "scriptTable_1_0";
  my $badmake = "000102:[000001:000085:[000004:000015:$tablename:000004:make:000016:scriptTableActor:000009:MyFixture:]:]";

  print $fitnesse $badmake . "000003:bye";
  $fitnesse->flush;

  $server->process($slim);

  my @replies = <$fitnesse>;

  is $replies[0], "Slim -- V0.5\n", "server greeting";

  my @exception = Test::FitNesse::Slim::List->new(substr $replies[1], 7)->list;
  is $exception[0][0], $tablename, "table name echoed";
  is $exception[0][1], '__EXCEPTION__:message:<<NO_CLASS MyFixture>>', $exception[0][1];

  is scalar    @exception,      1, "length of exception list";
  is scalar @{ $exception[0] }, 2, "length of exception sublist";
};

test {
  my $instructions = [
    [ "i1", "import", "fitnesse.slim.test" ],
    [ "m1", "make", "actor", "TestSlim" ],
    [ "c1", "call", "actor", "echo_string", "" ],
  ];
  my $command = Test::FitNesse::Slim::List->new($instructions)->serialize;
  print $fitnesse sprintf("%06d:%s", length($command), $command)
    . "000003:bye";
  $fitnesse->flush;

  my $processed = eval { $server->process($slim); 1 };
  ok $processed, "valid nested command with empty argument does not kill server";

  SKIP: {
    skip "server rejected command before returning a frame", 1 unless $processed;
    my @replies = <$fitnesse>;
    my @results = Test::FitNesse::Slim::List->new(substr $replies[1], 7)->list;
    is_deeply \@results, [ [ "i1", "OK" ], [ "m1", "OK" ], [ "c1", "" ] ],
      "empty argument round-trips through the SLiM server";
  }
};
