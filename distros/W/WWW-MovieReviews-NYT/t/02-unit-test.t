#!perl

use 5.006;
use strict; use warnings;
use WWW::MovieReviews::NYT;
use Test::More tests => 6;

my ($movie, $api_key);

$api_key = 'Dummy_API_Key';
$movie   = WWW::MovieReviews::NYT->new($api_key);

eval { print $movie->by_reviews_critics(); };
like($@, qr/ERROR: Missing input parameters./);

eval { print $movie->by_reviews_critics('resource-type' => 'all'); };
like($@, qr/ERROR: Input param has to be a ref to HASH./);

eval { print $movie->by_reviews_critics({'resource-tpye' => 'all'}); };
like($@, qr/ERROR: Missing key resource\-type./);

eval { print $movie->by_reviews_critics({'resource-type' => 'alls'}); };
like($@, qr/ERROR: Invalid value for key resource\-type \[alls\]./);

eval { print $movie->by_reviews_critics({'resource-type' => 'all', 'offset' => 12}); };
like($@, qr/ERROR: Invalid value for key offset \[12\]./);

eval { print $movie->by_reviews_critics({'resource-type' => 'all', 'order' => 'by-name'}); };
like($@, qr/ERROR: Invalid value for key order \[by\-name\]./);
