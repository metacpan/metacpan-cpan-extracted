#!/usr/bin/env perl
# SUMMARY: Update a bug's whiteboard or status (DRY RUN).
#
# NOTE: This script is a DRY RUN. It prints the update that would be
#       applied but does NOT call the API. Uncomment the update call
#       to actually modify a bug.
#
# USAGE:
#   perl examples/07-update-bug.pl [bug_id]
#   Defaults to bug 279763.
#
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/07-update-bug.pl [bug_id]
#
# EXAMPLES:
#   curl -X PUT -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     -H "Content-Type: application/json" \
#     -d '{"whiteboard":"[API-TEST] processed via WebService::Bugzilla"}' \
#     "https://bugs.freebsd.org/bugzilla/rest/bug/279763"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);
use JSON::MaybeXS qw(encode_json);

my $BUG_ID = $ARGV[0] // 279763;
my $bz     = get_client(default_url => 'https://bugs.freebsd.org');

my $bug = $bz->bug->get($BUG_ID)
    or die "Bug #$BUG_ID not found\n";

say "Bug #$BUG_ID: $bug->summary";
say "Status: $bug->status  resolution: ", $bug->resolution // "none";
say "";

my %updates = (
    whiteboard => '[API-TEST] processed via WebService::Bugzilla',
);

say "Would update bug #$BUG_ID with:";
for my $key (sort keys %updates) {
    say "  $key = $updates{$key}";
}

say "";
say "LIVE curl command:";
say "  curl -X PUT \\";
say "    -H 'X-BUGZILLA-API-KEY: \$BUGZILLA_API_KEY' \\";
say "    -H 'Content-Type: application/json' \\";
say "    -d '", encode_json(\%updates), "' \\";
say "    'https://bugs.freebsd.org/bugzilla/rest/bug/$BUG_ID'";
say "";

# Uncomment to actually update (instance form):
# my $updated = $bug->update(%updates);
# say "Updated. New whiteboard: ", $updated->whiteboard;

# Or service form:
# my $updated = $bz->bug->update($BUG_ID, %updates);
say "(dry run — no bug was modified)";
