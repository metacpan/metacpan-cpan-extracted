#!/usr/bin/env perl
# SUMMARY: List products available in a Bugzilla instance.
#
# USAGE:
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/04-list-products.pl
#
# EXAMPLES:
#   curl -s -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/product"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $bz = get_client(default_url => 'https://bugs.freebsd.org');

say "=== Available Products ===";
my $products = $bz->product->search;

for my $p (sort { $a->name cmp $b->name } @$products) {
    say sprintf "  %-6s  %s", $p->id, $p->name;
}

say "";
say "Done.";
