#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use Test::More tests => 4;
#use Test::More 'no_plan';
use WWW::PGXN;
use File::Spec::Functions qw(catfile);

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'file:t/mirror' ];

##############################################################################
# Try to get a nonexistent stats.
ok !$pgxn->get_stats('nonexistent'),
    'Should get nothing when searching for a nonexistent stats';

# Fetch stats data.
ok my $stats = $pgxn->get_stats('user'), 'Get user stats';
is_deeply $stats, {
   count => 3,
   prolific => [
      {nickname => 'theory', name => '', dists => 2, releases => 6},
      {nickname => 'strongrrl', name => '', dists => 1, releases => 1}
   ]
}, 'Should have stats structure';
