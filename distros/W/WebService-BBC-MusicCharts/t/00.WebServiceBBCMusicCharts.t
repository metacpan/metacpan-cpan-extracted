#!perl -w
use strict;
use Test::More tests => 2;

BEGIN {
  use_ok('WebService::BBC::MusicCharts');
}

my $charts = WebService::BBC::MusicCharts->new( chart => 'singles' );
is(ref $charts, 'WebService::BBC::MusicCharts', "Check object type" );
