#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use lib grep { -d $_ } qw(./lib ../lib);
use Test::Easy;

# test set/rollback of hashrefs for run_where
{
  my %hash = (1..10);
  is_deeply( \%hash, {1..10}, 'sanity' );

  run_where(
    [\%hash => {'a'..'f'}],
    sub {
      is_deeply( \%hash, {'a'..'f'}, 'local' );
    }
   );
  is_deeply( \%hash, {1..10}, 'restore' );
}

# checking short-circuit logic in keys check in DeepEqual::_same_hashrefs
{
  my %got = (1..10);
  my %exp = (3..12);

  my $wt = Test::Easy::wiretap 'Test::Easy::DeepEqual::deep_equal';
  Test::Easy::DeepEqual::deep_equal( \%got, \%exp );
  each_ok { 0 == grep { ! defined } @$_ } @{$wt->args};
}
