#!perl

use 5.006;
use strict; use warnings;
use WWW::MovieReviews::NYT;
use Test::More tests => 7;

my ($movie, $api_key);

$api_key = 'Dummy_API_Key';
$movie   = WWW::MovieReviews::NYT->new($api_key);

eval { print $movie->by_reviewer(); };
like($@, qr/ERROR: Missing input parameters./);

eval { print $movie->by_reviewer('reviewer-name' => 'a.b.scott'); };
like($@, qr/ERROR: Input param has to be a ref to HASH./);

eval { print $movie->by_reviewer({'reviewer-naem' => 'a.b.scott'}); };
like($@, qr/ERROR: Missing key reviewer\-name./);

eval { print $movie->by_reviewer({'reviewer-name' => 12345}); };
like($@, qr/ERROR: Invalid value for key reviewer\-name \[12345\]./);

eval { print $movie->by_reviewer({'reviewer-name' => 'a.b.scott', 'critics-pick' => 1}); };
like($@, qr/ERROR: Invalid value for key critics\-pick \[1\]./);

eval { print $movie->by_reviewer({'reviewer-name' => 'a.b.scott', 'offset' => 12}); };
like($@, qr/ERROR: Invalid value for key offset \[12\]./);

eval { print $movie->by_reviewer({'reviewer-name' => 'a.b.scott', 'order' => 'by-name'}); };
like($@, qr/ERROR: Invalid value for key order \[by\-name\]./);
