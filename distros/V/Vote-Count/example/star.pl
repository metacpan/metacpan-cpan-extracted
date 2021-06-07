#!/usr/bin/env perl

use 5.024;

use feature qw /postderef signatures/;
use Path::Tiny;

use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Vote::Count::Method::STAR;

my $tennessee =
  Vote::Count::Method::STAR->new(
  LogTo => '/tmp/demo/tennessee_star',
  BallotSet => read_range_ballots('tennessee.range.json'), );

$tennessee->STAR();
say '='x60 ;
say "Running STAR for Tennessee";
say $tennessee->logv();

$tennessee->WriteLog();
