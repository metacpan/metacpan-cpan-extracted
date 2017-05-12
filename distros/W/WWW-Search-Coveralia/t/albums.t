#!/usr/bin/perl
use v5.14;
use warnings;

use List::Util qw/first/;
use WWW::Search::Test;

use Test::RequiresInternet qw/www.coveralia.com 80/;
use Test::More tests => 11;

tm_new_engine('Coveralia::Albums');
tm_run_test_no_approx(normal => $WWW::Search::Test::bogus_query, 0, 0);
tm_run_test_no_approx(normal => 'And Justice For All', 1, 10);
my $result = first { $_->artist eq 'Metallica' } $WWW::Search::Test::oSearch->results;
is $result->year, 1988, 'And Justice For All was released in 1988';

my @songs = $result->songs;
my %covers = $result->covers;
ok ((first { $_->{name} eq 'The Shortest Straw' } @songs), 'And Justice For All contains The Shortest Straw');
ok $covers{frontal}, 'And Justice For All has a front cover';
is $result->cover('frontal'), $covers{frontal}, '->cover works';
