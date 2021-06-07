#!/usr/bin/env perl

use 5.024;

use Data::Printer;
use feature qw /postderef signatures/;

use Vote::Count::Start;
use Vote::Count::Method::CondorcetVsIRV;

my ( $filename, $outfolder ) = @ARGV;
$filename =~ m/\/(\w+)\./;
my $name = $1;

use Vote::Count::Start;

say "use ballotfile $filename";
say "log to $outfolder";

my $Election = StartElection(
    BallotFile => $filename,
    FloorRule  => 'Approval',
    FloorValue => 5,
    LogPath    => $outfolder,
    LogBaseName => $name . "_basic",
);

$Election->WriteLog();

say '='x60 ;
say "Running Basic RCV Methods for $filename";
say $Election->logt();

my $CIRV = Vote::Count::Method::CondorcetVsIRV->new(
    'BallotSet' => $Election->BallotSet(),
    LogTo    => "$outfolder/$name" ."_cirv" );
my $CIRV2 = Vote::Count::Method::CondorcetVsIRV->new(
    'BallotSet' => $Election->BallotSet(),
    LogTo    => "$outfolder/$name" ."_relaxed" );

say '='x60 ;
say "Running Strict CondorcetVsIRV for $filename";
$CIRV->CondorcetVsIRV();
$CIRV->WriteAllLogs();
say $CIRV->logt();

say '='x60 ;
say "Running Relaxed CondorcetVsIRV for $filename";

$CIRV2->CondorcetVsIRV( relaxed => 1 );
$CIRV2->WriteAllLogs();
say $CIRV2->logt();

