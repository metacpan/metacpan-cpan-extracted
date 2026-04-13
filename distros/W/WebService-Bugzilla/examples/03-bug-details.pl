#!/usr/bin/env perl
# SUMMARY: Fetch a specific bug and print full details, comments, and history.
#
# USAGE:
#   perl examples/03-bug-details.pl [bug_id]
#   Defaults to bug 279763 if no argument given.
#
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/03-bug-details.pl [bug_id]
#
# EXAMPLES:
#   curl -s -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     "https://bugs.freebsd.org/bugzilla/rest/bug/279763"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $BUG_ID = $ARGV[0] // 279763;
my $bz     = get_client(default_url => 'https://bugs.freebsd.org');

sub str {
    my ($val) = @_;
    return ref($val) ? '(object)' : (defined($val) && $val ne '' ? $val : '(none)');
}

sub bug_status {
    my ($bug) = @_;
    my $res = $bug->resolution // '';
    return $res ? "${\$bug->status} ($res)" : $bug->status;
}

my $bug = $bz->bug->get($BUG_ID) or die "Bug #$BUG_ID not found\n";

say "=== Bug #$BUG_ID ===";
say "";
say "Summary:    ", $bug->summary;
say "Status:    ", bug_status($bug);
say "Product:   ", $bug->product;
say "Component: ", $bug->component;
say "Version:   ", $bug->version;
say "Platform:  ", $bug->platform;
say "OS:        ", $bug->op_sys;
say "Severity:  ", str($bug->severity);
say "Priority:  ", str($bug->priority);
say "Assigned:  ", str($bug->assigned_to);
say "Reporter:  ", str($bug->{creator} // $bug->reporter);
say "Created:   ", $bug->creation_time;
say "Changed:   ", $bug->last_change_time;
say "Is Open:  ", ($bug->is_open ? 'yes' : 'no');
my @kw = @{$bug->keywords // []};
say "Keywords: ", @kw ? join(', ', @kw) : '(none)';

say "";
say "=== Comments ===";
my $comments = $bz->comment->get($BUG_ID);
if (@$comments == 0) {
    say "  (no comments)";
} else {
    for my $c (@$comments) {
        my $private = $c->is_private ? " [PRIVATE]" : "";
        say sprintf "  #%-3d %s by %s%s",
            $c->count, $c->creation_time, $c->creator, $private;
        my $text = $c->text;
        $text =~ s/\n/ /g;
        $text = substr($text, 0, 120);
        say "    $text";
    }
}

say "";
say "=== Bug History (last 5 changes) ===";
my $history = $bz->bug->history($BUG_ID);
if (@$history == 0) {
    say "  (no history)";
} else {
    my @recent = reverse @$history;
    splice(@recent, 5);
    for my $entry (@recent) {
        say sprintf "  %s by %s", $entry->when, $entry->who;
        for my $change (@{$entry->changes}) {
            say sprintf "    %-20s: '%s' -> '%s'",
                $change->field_name,
                $change->removed // '',
                $change->added    // '';
        }
    }
}

say "";
say "=== Attachments ===";
my $attachments = $bz->attachment->search(bug_id => $BUG_ID);
if (@$attachments == 0) {
    say "  (no attachments)";
} else {
    for my $a (@$attachments) {
        say sprintf "  #%-6d  %-10s  %s",
            $a->id, $a->content_type, $a->filename;
        say "    ", str($a->description);
    }
}

say "";
say "Done.";
