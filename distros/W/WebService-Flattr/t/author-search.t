#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

# +1 for Test::NoWarnings
use Test::More tests => 5 + 1;
use Test::NoWarnings;

use_ok 'WebService::Flattr';
my $flattr = WebService::Flattr->new();
my $resp = $flattr->search_things({
    count => 4,
    sort => 'flattrs',
    tags => 'perl',
});

my $req_uri = $resp->http_response->request->uri;
like $req_uri, qr/tags=perl/, 'Request: expected search tags';
like $req_uri, qr/sort=flattrs/, 'Request: Expected sort order';
like $req_uri, qr/count=4/, 'Request: Expected count';

my $data = $resp->data;
is @{ $data->{things} }, 4, 'Response: Expected count';
