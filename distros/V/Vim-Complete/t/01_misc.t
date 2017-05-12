#!/usr/bin/env perl
use warnings;
use strict;
use Vim::Complete;
use Test::More tests => 1;
use Test::Differences;
use FindBin '$Bin';
my $completer = Vim::Complete->new(
    dirs       => "$Bin/../lib",
    verbose    => 0,
    min_length => 3,
)->parse;
my $report = $completer->report;
my $expect = [
    qw(
      VERSION
      Vim::Complete
      document
      filename
      gather
      min_length
      parse
      report
      report_to_file
      result
      seen
      self
      verbose
      )
];
eq_or_diff($report, $expect, 'report from Vim::Complete');
