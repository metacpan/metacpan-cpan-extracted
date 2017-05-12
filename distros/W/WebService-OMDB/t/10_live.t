#!perl

use strict;
use warnings;

use Test::More;

# skip tests if we are not online
use HTTP::Online ':skip_all';
plan tests => 5;

use WebService::OMDB;

use constant TITLE  => 'The Green Mile';
use constant IMDBID => 'tt0120689';

my $search_results = WebService::OMDB::search(TITLE);
ok( @{$search_results} >= 4, 'at least 4 results' );

my $id_result = WebService::OMDB::id(IMDBID);
ok($id_result);
is( $id_result->{Title}, TITLE );

my $title_result = WebService::OMDB::title(TITLE);
ok($title_result);
is( $id_result->{imdbID}, IMDBID );
