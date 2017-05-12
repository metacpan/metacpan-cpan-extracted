#!perl

use 5.006;
use strict; use warnings;
use WWW::MovieReviews::NYT;
use Test::More tests => 13;

my ($movie, $api_key);

$api_key = 'Dummy_API_Key';
$movie   = WWW::MovieReviews::NYT->new($api_key);

eval { $movie->by_keyword(); };
like($@, qr/ERROR: Missing input parameters./);

eval { $movie->by_keyword('query' => 'wild+west'); };
like($@, qr/ERROR: Input param has to be a ref to HASH./);

eval { $movie->by_keyword({'queyr' => 'wild+west'}); };
like($@, qr/ERROR: Missing key query./);

eval { $movie->by_keyword({'query' => 'wild+west', 'reviewer' => 12345}); };
like($@, qr/ERROR: Invalid value for key reviewer \[12345\]./);

eval { $movie->by_keyword({'query'        => 'wild+west',
                           'reviewer'     => 'a.e.scott',
                           'critics-pick' => 1}); };
like($@, qr/ERROR: Invalid value for key critics\-pick \[1\]./);

eval { $movie->by_keyword({'query'         => 'wild+west',
                           'reviewer'      => 'a.e.scott',
                           'thausand-best' => 1}); };
like($@, qr/ERROR: Invalid value for key thausand\-best \[1\]./);

eval { $movie->by_keyword({'query'    => 'wild+west',
                           'reviewer' => 'a.e.scott',
                           'dvd'      => 1}); };
like($@, qr/ERROR: Invalid value for key dvd \[1\]./);

eval { $movie->by_keyword({'query' => 'wild+west', 'publication-date' => '12-12-2011'}); };
like($@, qr/ERROR: Invalid value for key publication\-date \[12\-12\-2011\]./);

eval { $movie->by_keyword({'query' => 'wild+west', 'publication-date' => '2011-02-12;12-12-2011'}); };
like($@, qr/ERROR: Invalid value for key publication\-date \[2011\-02\-12;12\-12\-2011\]./);

eval { $movie->by_keyword({'query' => 'wild+west', 'opening-date' => '12-12-2011'}); };
like($@, qr/ERROR: Invalid value for key opening\-date \[12\-12\-2011\]./);

eval { $movie->by_keyword({'query' => 'wild+west', 'opening-date' => '2011-02-12;12-12-2011'}); };
like($@, qr/ERROR: Invalid value for key opening\-date \[2011\-02\-12;12\-12\-2011\]./);

eval { $movie->by_keyword({'query' => 'wild+west', 'offset' => 15}); };
like($@, qr/ERROR: Invalid value for key offset \[15\]./);

eval { $movie->by_keyword({'query' => 'wild+west', 'order' => 'by-name'}); };
like($@, qr/ERROR: Invalid value for key order \[by\-name\]./);
