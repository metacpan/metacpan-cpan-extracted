#!/usr/bin/perl
use v5.14;
use warnings;

use List::Util qw/first/;
use WWW::Search::Test;

use Test::RequiresInternet qw/www.coveralia.com 80/;
use Test::More tests => 9;

tm_new_engine('Coveralia::Artists');
tm_run_test_no_approx(normal => $WWW::Search::Test::bogus_query, 0, 0);
tm_run_test_no_approx(normal => 'Metallica', 1, 10);
my $result = first { $_->title eq 'Metallica' } $WWW::Search::Test::oSearch->results;
my @albums = $result->albums;

$result = first { $_->title eq 'And Justice For All' } @albums;
is $result->year, 1988, 'And Justice For All was released in 1988';
my %acovers = $result->covers;
ok $acovers{frontal}, 'And Justice For All has a front cover';
