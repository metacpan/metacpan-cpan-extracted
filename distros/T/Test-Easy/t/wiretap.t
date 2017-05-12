#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";

use Test::Easy qw(wiretap);

{
  package target;

  sub kanga { 'roo' }
}

# wiretaps reset when they go out of scope
{
  is( target->kanga, 'roo', 'sanity test' );

  my $hits;
  {
    my $wt = wiretap 'target::kanga', sub { $hits++ };
    is( target->kanga, 'roo', 'wiretap in effect' );
    is( $hits, 1, 'hit the wiretap once' );
  }

  # here's the real test
  is( target->kanga, 'roo', 'outside wiretap scope' );
  is( $hits, 1, "wiretap got torn down when it exited scope" );
}

1;
