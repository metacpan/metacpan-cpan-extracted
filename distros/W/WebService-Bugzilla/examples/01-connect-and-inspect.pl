#!/usr/bin/env perl
# SUMMARY: Connect to a Bugzilla instance and inspect the API.
#          Demonstrates: client setup, quicksearch, component search, and get-by-id.
#
# USAGE:
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/01-connect-and-inspect.pl
#
#   perl examples/01-connect-and-inspect.pl --api-key=xxx --url=https://bugs.freebsd.org
#
# EXAMPLES:
#   # Search for open 'panic' bugs
#   curl -s -H "X-BUGZILLA-API-KEY: \$API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug?quicksearch=panic+status%3Aopen&limit=5"
#
#   # Get a specific bug
#   curl -s -H "X-BUGZILLA-API-KEY: \$API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug/279763"

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

sub str {
    my ($val) = @_;
    return ref($val) ? '(object)' : (defined($val) && $val ne '' ? $val : '(none)');
}

say "Connected to bugs.freebsd.org";
say "Base URL: ", $bz->base_url;
say "";

say "=== Open 'panic' bugs (quicksearch, limit 5) ===";
my $panic = $bz->bug->search(
    quicksearch => 'panic status:open',
    limit       => 5,
);
for my $bug (@$panic) {
    say sprintf "  [%s] #%d  %s", $bug->status, $bug->id, $bug->summary;
}

say "";

say "=== Open bugs in 'kern' component (limit 5) ===";
my $kern = $bz->bug->search(
    quicksearch => 'component:kern status:open',
    limit       => 5,
);
for my $bug (@$kern) {
    say sprintf "  [%s] #%d  %s", $bug->status, $bug->id, $bug->summary;
}

say "";

say "=== Bug #279763 ===";
my $one = $bz->bug->get(279763) or die "Bug #279763 not found\n";
say "  Summary:    ", $one->summary;
say "  Status:     ", bug_status($one);
say "  Product:    ", $one->product;
say "  Component:  ", $one->component;
say "  Version:    ", $one->version;
say "  Platform:   ", $one->platform;
say "  Severity:   ", str($one->severity);
say "  Priority:   ", str($one->priority);
say "  Assigned:   ", str($one->assigned_to);
say "  Reporter:   ", str($one->reporter);
say "  Created:    ", $one->creation_time;
say "  Changed:    ", $one->last_change_time;
say "  Is Open:   ", ($one->is_open ? 'yes' : 'no');
my @kw = @{$one->keywords // []};
say "  Keywords:  ", @kw ? join(', ', @kw) : '(none)';

say "";
say "Done.";
