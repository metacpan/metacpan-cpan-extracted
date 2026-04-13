#!/usr/bin/env perl
# SUMMARY: Extract real fixture data from bugs.freebsd.org for test fixtures.
#          Read-only — does not create or modify any data.
#
# USAGE:
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/extract-fixtures.pl

use v5.24;
use strict;
use warnings;

use JSON::PP;
use Scalar::Util qw(blessed);
use overload;
my $JSON = JSON::PP->new->allow_blessed->pretty;
sub enc { $JSON->encode(shift) }

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $bz = get_client(default_url => 'https://bugs.freebsd.org');

sub _obj_to_hash {
    my ($ref) = @_;
    return undef unless defined $ref;
    if (blessed($ref) && overload::Method($ref, '%{}')) {
        return { %$ref };
    }
    if (ref($ref) eq 'HASH') {
        my %copy = %$ref;
        delete $copy{client};
        for my $v (values %copy) {
            $v = _obj_to_hash($v);
        }
        return \%copy;
    }
    if (ref($ref) eq 'ARRAY') {
        return [ map { _obj_to_hash($_) } @$ref ];
    }
    return $ref;
}

sub emit {
    my ($label, $data) = @_;
    print "=== $label ===\n";
    print enc(_obj_to_hash($data)), "\n\n";
}

print "=== Searching for example bugs ===\n";
my $bugs = $bz->bug->search(quicksearch => 'FreeBSD status:open', limit => 3);
die "No bugs found" unless @$bugs;
my $example_bug = $bugs->[0];
print "Using bug #", $example_bug->id, " — ", $example_bug->summary, "\n\n";

emit('Bug full',            $bz->bug->get($example_bug->id));
emit('Bug history',         $bz->bug->history($example_bug->id));
emit('Bug duplicates',      $bz->bug->possible_duplicates($example_bug->id));
emit('Bug search (2)',       $bz->bug->search(limit => 2));

my $comments = $bz->comment->get($example_bug->id);
if (@$comments) {
    emit('Comments',         $comments);
    my $first = $comments->[0];
    emit('Comment by ID',    $bz->comment->get_by_id($first->id));
    emit('Comment reactions', $bz->comment->get_reactions($first->id));
    emit('Comment tags search', $bz->comment->search_tags('dev'));
    emit('Comment render',    $bz->comment->render(markdown => 'Hello **world**'));
} else {
    print "=== Comments ===\n(no comments)\n\n";
}

my $attachments = $bz->attachment->search(bug_id => $example_bug->id);
if (@$attachments) {
    emit('Attachments',          $attachments);
    emit('Attachment by ID',     $bz->attachment->get($attachments->[0]{id}));
} else {
    print "=== Attachments ===\n(no attachments)\n\n";
}

emit('Component by name',    $bz->component->get_by_name($example_bug->product, $example_bug->component));
emit('Component search',     $bz->component->search('kern'));
emit('Field priority',       $bz->field->get('priority'));
emit('Field lexamplesal values',  $bz->field->legal_values('priority'));
emit('Fields (first 2)',     [$bz->field->get_all->@*[0..1]]);

my $flags = $bz->flag_activity->get_by_bug($example_bug->id);
emit('Flag activity',        $flags);

emit('User whoami',          $bz->user->whoami);
emit('Valid login',          $bz->user->valid_login);
emit('User login',           $bz->user->login_name(login => 'bugs@FreeBSD.org'));
emit('Products (3)',         $bz->product->search(limit => 3));
emit('Groups',               $bz->group->search);

my $classifications = $bz->classification->search;
if (@$classifications) {
    emit('Classification',      $bz->classification->get($classifications->[0]{id}));
} else {
    print "=== Classification ===\n(no classifications)\n\n";
}

emit('Reminders',            $bz->reminder->search(limit => 3));

emit('BugUserLastVisit get',  $bz->bug_user_last_visit->get(limit => 5));

print "\n=== ALL FIXTURES EXTRACTED ===\n";
print "Run the tests to confirm everything still works.\n";
