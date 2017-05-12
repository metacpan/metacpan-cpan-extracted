#!perl

use strict; use warnings;
use WWW::Google::URLShortener;
use Test::More tests => 7;

my ($google);

eval { $google = WWW::Google::URLShortener->new(); };
like($@, qr/Missing required arguments: api_key/);

$google = WWW::Google::URLShortener->new(api_key => 'You_API_Key');
eval { $google->shorten_url(); };
like($@, qr/ERROR: Received undefined mandatory param: longUrl/);

eval { $google->expand_url(); };
like($@, qr/ERROR: Received undefined mandatory param: shortUrl/);

eval { $google->get_analytics(); };
like($@, qr/ERROR: Received undefined mandatory param: shortUrl/);

eval { $google->shorten_url('http//www.google.com'); };
like($@, qr/ERROR: Invalid data type 'url'/);

eval { $google->expand_url('http//www.google.com'); };
like($@, qr/ERROR: Invalid data type 'url'/);

eval { $google->get_analytics('http//www.google.com'); };
like($@, qr/ERROR: Invalid data type 'url'/);
