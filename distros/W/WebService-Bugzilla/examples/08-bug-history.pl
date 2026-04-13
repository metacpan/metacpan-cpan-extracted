#!/usr/bin/env perl
# SUMMARY: Print the full change history of a bug.
#
# USAGE:
#   perl examples/08-bug-history.pl [bug_id]
#   Defaults to bug 279763.
#
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/08-bug-history.pl [bug_id]
#
# EXAMPLES:
#   curl -s -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug/279763/history"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $BUG_ID = $ARGV[0] // 279763;
my $bz     = get_client(default_url => 'https://bugs.freebsd.org');

my $bug = $bz->bug->get($BUG_ID)
    or die "Bug #$BUG_ID not found\n";

say "=== Bug #$BUG_ID History: $bug->summary ===";
say "";

my $history = $bz->bug->history($BUG_ID);
if (@$history == 0) {
    say "(no history)";
} else {
    say "Total changes: ", scalar @$history;
    say "";

    my %by_date;
    for my $entry (@$history) {
        my $date = substr($entry->when, 0, 10);
        push @{$by_date{$date}}, $entry;
    }

    for my $date (sort { $b cmp $a } keys %by_date) {
        say "=== $date ===";
        for my $entry (@{$by_date{$date}}) {
            say "  $entry->{when}  $entry->who";
            for my $change (@{$entry->changes}) {
                my $from = $change->removed // '';
                my $to   = $change->added    // '';
                $from = "'$from'" if $from;
                $to   = "'$to'"   if $to;
                say sprintf "    %-20s: %s -> %s",
                    $change->field_name, $from, $to;
            }
        }
        say "";
    }
}

say "Done.";
