#!/usr/bin/env perl
# SUMMARY: Search for bugs with various filter combinations.
#
# USAGE:
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/02-search-bugs.pl
#
# EXAMPLES:
#   curl -s -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug?quicksearch=iSCSI+status%3Aopen&limit=5"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $bz = get_client(default_url => 'https://bugs.freebsd.org');

sub bug_status {
    my ($bug) = @_;
    my $res = $bug->resolution // '';
    return $res ? "${\$bug->status} ($res)" : $bug->status;
}

my $LIMIT = 5;

sub print_bugs {
    my ($label, $bugs) = @_;
    say "=== $label ===";
    if (@$bugs == 0) {
        say "  (no results)";
    } else {
        for my $bug (@$bugs) {
            say sprintf "  #%-6d [%s] %s",
                $bug->id, bug_status($bug), $bug->summary;
        }
    }
    say "";
}

print_bugs "Quicksearch: 'iSCSI status:open'",
    $bz->bug->search(quicksearch => 'iSCSI status:open', limit => $LIMIT);

print_bugs "Component='usb', open bugs",
    $bz->bug->search(quicksearch => 'component:usb status:open', limit => $LIMIT);

print_bugs "Product='Ports Framework', open bugs",
    $bz->bug->search(quicksearch => 'product:"Ports Framework" status:open', limit => $LIMIT);

print_bugs "Version='14.0-RELEASE', open bugs",
    $bz->bug->search(quicksearch => 'version:14.0-RELEASE status:open', limit => $LIMIT);

print_bugs "Severity='Affects Many People', open bugs",
    $bz->bug->search(
        quicksearch => 'severity:"Affects Many People" status:open',
        limit       => $LIMIT,
    );

print_bugs "Whiteboard contains 'mwait'",
    $bz->bug->search(quicksearch => 'whiteboard:mwait', limit => $LIMIT);

say "Done.";
