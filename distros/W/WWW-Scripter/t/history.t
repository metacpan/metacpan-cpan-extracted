#!perl

use warnings;
use strict;
use Test::More tests => 28 ;
use URI;

BEGIN {
    use_ok( 'WWW::Scripter' );
}

sub data_url {
    my $u = new URI 'data:';
    $u->media_type('text/html');
    $u->data(shift);
    $u
}

my $mech = WWW::Scripter->new;

is $mech->history->length, 1,'history->length\'s initial retval';

$mech->get(data_url '<title>first page</title>');
$mech->get(data_url '<title>second page</title>');
$mech->get(data_url '<title>third page</title>');
is $mech->history->length, 3, 'history->length after fetching pages';
$mech->back;
is $mech->history->length, 3, 'history->length after going back';
is $mech->title, 'second page', 'back';
$mech->back;
is $mech->title, 'first page', 'back again';
$mech->forward;
is $mech->title, 'second page', 'forward';
$mech->forward;
is $mech->title, 'third page', 'forward again';
$mech->back;
is $mech->title, 'second page', 'back yet again';

$mech->get(data_url '<title>new page</title>');
is $mech->history->length, 3,
    'history->length after a page fetch erases fwd history';
$mech->forward;
is $mech->title, 'new page', '->request erases the forward stack';
$mech->back;
is $mech->title, 'second page',
    'Does ->forward at the end of history mess things up?';

$mech->clear_history;
$mech->back;
is $mech->history->length, 1,
    'make sure back messes nothing up when you can\'t go back';


# state info stuff

$mech->get(data_url '<title>third page</title>');

my @scratch;
sub record_state {
    my $h = $mech->history;
    # Yes, we are breaking encapuslation here.
    # Don’t do this in your own code.
    my $history_entry = $h->[$h->index];
    push @scratch, [
     $mech->title,
     exists $history_entry->[3] ? $history_entry->[3] : undef
    ];
}

my $h = $mech->history;
$h->pushState(37);      record_state;
$h->pushState(43);      record_state;
$mech->get(data_url '<title>fourth page</title>'); record_state;
$h->pushState(\'phoo'); record_state;
$mech->back,                     record_state  for 1..5;
$mech->forward,                  record_state  for 1..6;
$mech->get(data_url '<title>fifth page</title>');
$mech->history->go(-2);
$h->pushState(\'barr'); # make sure it erases state objects from fwd
                        # history (that belong to the current page)
$mech->forward;                  record_state;

is_deeply \@scratch, [
    ['third page',  37],
    ['third page',  43],
    ['fourth page', undef],
    ['fourth page', \'phoo'],
    ['fourth page', undef],
    ['third page',  43],
    ['third page',  37],
    ['third page',  undef],
    ['second page', undef],
    ['third page',  undef],
    ['third page',  37],
    ['third page',  43],
    ['fourth page', undef],
    ['fourth page', \'phoo'],
    ['fourth page', \'phoo'],  # can't go forward beyond the last state
    ['fifth page', undef],
], 'pushState';

$mech = new WWW::Scripter max_docs => 3, max_history => 27;
is $mech->max_docs, 3, 'max_docs constructor arg';
is $mech->max_history, 27, 'max_history constructor arg';
$mech->max_docs(4);
$mech->max_history(32);
is $mech->max_docs, 4, 'max_docs accessor';
is $mech->max_history, 32, 'max_history accessor';
$mech->stack_depth(53);
is $mech->max_docs, 54, 'max_history based on stack_depth';

$mech->max_docs(2);
$mech->max_history(4);
for("one","two","three",'four','five') {
 $mech->get(data_url "<title>$_</title>");
 $mech->document->title("$_ modified");
}
is $mech->history->length, 4, 'max_history in effect';
$mech->back;
is $mech->title, "four modified", 'max_docs does not erase too many docs';
$mech->back;
is $mech->title, "three", 'max_docs throws docs away when appropriate';
$mech->forward for 1..2;
is $mech->title,"five", 'max_docs throws away future docs when going back';
$mech->back for 1..4;
is $mech->title,'two',
 'max_history did actually throw away the first entry';


# In my first attempt at implementing  max_docs,  it would defenestrate
# enough docs at the beginning or end of the history to satisfy max_docs--
# at the beginning for forward navigation, and at the end for backward nav-
# igation.  This would cause the following problem  (it could get worse if
# max_docs  were fiddled in the middle of browsing,  in that the  current
# page’s corresponding  entry  in  the  history  object  would  lack  a
# response object):
#
# set max_docs to 2
# browse to four docs:
#   undef undef document document
#                           ^
# go(-3)
#   document undef document undef
#      ^
# forward
#   undef document document undef
#            ^
# back
#   document document undef undef
#      ^
# So going back to the page we’ve just been on reloads it since it was
# erased. That doesn’t make sense. So now we keep a separate list of doc-
# uments, in the order they were visited, and delete the oldest ones. That
# is what this test is for. (That’s a long test name!)

$mech->clear_history(1);
$mech->max_docs(2);
$mech->get(data_url "<title>$_</title>") for qw "one two three four";
$mech->history->go(-3);
$mech->document->title("modified");
$mech->forward;
$mech->back;
#use DDS; Dump $mech->history;
is $mech->title, "modified",
 "In my first attempt at.... (see the source for the full name)";

# Test go with other arguments.
$mech->history->go(2);
is $mech->title, 'three', 'go with a positive argument';
$mech->document->title('modified');
$mech->history->go(0);
is $mech->title, 'three', 'go(0) reloads';
$mech->document->title('modified');
$mech->history->go('00');
is $mech->title, 'three', 'go("00") (true zero) reloads';
