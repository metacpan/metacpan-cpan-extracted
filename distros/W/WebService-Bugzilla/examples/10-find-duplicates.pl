#!/usr/bin/env perl
# SUMMARY: Find bugs marked as duplicates of a given bug.
#
# NOTE: /duplicates returns bugs that are duplicates OF the given bug
#       (the given bug is the master). Check $bug->dupe_of to see if
#       this bug itself is a duplicate.
#
# USAGE:
#   perl examples/10-find-duplicates.pl [bug_id]
#   Defaults to bug 279763.
#
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/10-find-duplicates.pl [bug_id]
#
# EXAMPLES:
#   curl -s -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug/279763/duplicates"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $BUG_ID = $ARGV[0] // 279763;
my $bz     = get_client(default_url => 'https://bugs.freebsd.org');

my $bug = $bz->bug->get($BUG_ID)
    or die "Bug #$BUG_ID not found\n";

say "=== Duplicates of Bug #$BUG_ID ===";
say "Summary: $bug->summary";
say "Status:  $bug->status";
my $dupe_of = $bug->{dupe_of};
if (defined $dupe_of && $dupe_of ne '') {
    say "NOTE: This bug IS a duplicate of #$dupe_of";
}
say "";

my $dupes = $bz->bug->possible_duplicates($BUG_ID);
if (@$dupes == 0) {
    say "(no duplicates found)";
} else {
    say "Bugs marked as duplicates of #$BUG_ID:";
    for my $d (@$dupes) {
        say sprintf "  #%-6d  [%s]  %s",
            $d->id, $d->status, $d->summary;
    }
}

say "";
say "Done.";
