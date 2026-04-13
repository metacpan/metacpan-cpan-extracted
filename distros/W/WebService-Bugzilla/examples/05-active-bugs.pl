#!/usr/bin/env perl
# SUMMARY: Find the most recently active open bugs.
#
# USAGE:
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/05-active-bugs.pl
#
# EXAMPLES:
#   curl -s -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug?quicksearch=status%3Aopen&order=changeddate&limit=10"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $bz = get_client(default_url => 'https://bugs.freebsd.org');

say "=== Most Recently Changed Open Bugs (limit 10) ===";
my $bugs = $bz->bug->search(
    quicksearch => 'status:open',
    order       => 'changeddate',
    limit       => 10,
);

for my $bug (@$bugs) {
    say sprintf "  %s  #%-6d  %s",
        $bug->last_change_time, $bug->id, $bug->summary;
}

say "";
say "Done.";
