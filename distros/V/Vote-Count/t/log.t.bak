#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
use Test2::Tools::Exception qw/dies lives/;
use Data::Printer;

use Path::Tiny;
use File::Temp;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';

my $VC1 = Vote::Count->new( BallotSet => read_ballots('t/data/data1.txt'), );

for my $oldfile ( path('/tmp')->children(qr/votecount/) ) {
  unlink $oldfile;
}

is( $VC1->BallotSetType(), 'rcv', 'BallotSetType option is set to rcv' );

is( $VC1->VotesCast(), 10, 'Count the number of ballots in the set' );

$VC1->logt('A Terse Entry');
$VC1->logv('A Verbose Entry');
$VC1->logd('A Debug Entry');

ok( lives { $VC1->WriteLog() }, "did not die from writing a log" )
  or note($@);
ok( stat("/tmp/votecount.full"),
  'the default temp file for the full log exists' );

my $tmp = File::Temp::tempdir( 'XXXX', DIR => '/tmp/' );

my $VC2 = Vote::Count->new(
  BallotSet => read_ballots('t/data/data1.txt'),
  LogTo     => "$tmp/vc2"
);

$VC2->logt('A Terse Entry');
$VC2->logv('A Verbose Entry');
$VC2->logd('A Debug Entry');
$VC2->WriteLog();
ok( stat("$tmp/vc2\.brief"),
  "created brief log to specified path $tmp/vc2\.brief" );

my $tmp2 = "$tmp/subdir";
note $tmp2;
my $VC3 = Vote::Count->new(
  BallotSet   => read_ballots('t/data/data1.txt'),
  LogPath     => $tmp2,
  LogBaseName => 'logtest'
);

isa_ok( $VC3->PairMatrix(), ['Vote::Count::Matrix'], 'Confirm Matrix' );

my $now = gmtime();
$VC3->PairMatrix()->logt("Test log event for NOW $now");
$VC3->WriteLog();
$VC3->PairMatrix()->WriteLog();

my $debug3 = "$tmp2/logtest.debug";
ok( stat $debug3, "debug log written to $debug3" );
my $debug3mb = "$tmp2/logtest_matrix.brief";
like( path($debug3mb)->slurp(),
  qr/$now/, "String for Now $now logged to $debug3mb" );

note "Temporary Files are in $tmp and $tmp2";

done_testing();
