#!perl

use strict;
use warnings;

use Test::More;

# skip tests if we are not online
use HTTP::Online ':skip_all';

plan tests => 7;

use WebService::IMDBAPI;

my $title   = 'The Notebook';
my $imdb_id = 'tt0332280';
my $imdbapi;
my $results;
my $result;

$imdbapi = WebService::IMDBAPI->new();

$results = $imdbapi->search_by_title( $title, { limit => 1 } );
is( @{$results}, 1 );
$result = $results->[0];
is( $result->title,   $title );
is( $result->imdb_id, $imdb_id );

$result = $imdbapi->search_by_id($imdb_id);
is( $result->title,   $title );
is( $result->imdb_id, $imdb_id );

# title not found
$title = "300muxed";
$results = $imdbapi->search_by_title( $title, { limit => 1 } );
ok( !@{$results} );

# id not found
$imdb_id = 'abcdef';
$result  = $imdbapi->search_by_id($imdb_id);
ok( !$result );
