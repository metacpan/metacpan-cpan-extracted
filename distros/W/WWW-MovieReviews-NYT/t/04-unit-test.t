#!perl

use 5.006;
use strict; use warnings;
use WWW::MovieReviews::NYT;
use Test::More tests => 2;

my ($movie, $api_key);

$api_key = 'Dummy_API_Key';
$movie   = WWW::MovieReviews::NYT->new($api_key);

eval { print $movie->get_reviewer_details(); };
like($@, qr/ERROR: Missing key resource\-type./);

eval { print $movie->get_reviewer_details(12345); };
like($@, qr/ERROR: Invalid value for key resource\-type \[12345\]./);
