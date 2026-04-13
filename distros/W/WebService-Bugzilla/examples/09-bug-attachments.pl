#!/usr/bin/env perl
# SUMMARY: List attachments on a bug.
#
# USAGE:
#   perl examples/09-bug-attachments.pl [bug_id]
#   Defaults to bug 279763.
#
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/09-bug-attachments.pl [bug_id]
#
# EXAMPLES:
#   curl -s -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug/279763/attachment"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $BUG_ID = $ARGV[0] // 279763;
my $bz     = get_client(default_url => 'https://bugs.freebsd.org');

my $bug = $bz->bug->get($BUG_ID)
    or die "Bug #$BUG_ID not found\n";

say "=== Attachments for Bug #$BUG_ID ===";
say "Summary: $bug->summary";
say "";

my $attachments = $bz->attachment->search(bug_id => $BUG_ID);
if (@$attachments == 0) {
    say "(no attachments)";
} else {
    for my $a (@$attachments) {
        say sprintf "  #%-6d  %-10s  %s",
            $a->id, $a->content_type, $a->filename;
        say "    Description:  ", $a->description // "(none)";
        say "    Creator:     ", $a->creator     // "(unknown)";
        say "    Date:        ", $a->creation_time // "(unknown)";
        say "";
    }
}

say "Done.";
