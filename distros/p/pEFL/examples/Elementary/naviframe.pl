# Based on the Naviframe Tutorial
# see https://www.enlightenment.org/develop/legacy/tutorial/naviframe_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;
use pEFL::Evas;

$pEFL::Debug = 0;

# NOTE: A zipper is a datastructure for an ordered set of elements and a
# cursor in this set, meaning there are elements before the cursor (which are
# stored inside the naviframe) and after (which are stored in the "popped"
# list.
my @naviframe_zipper;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("Naviframe", "Naviframe Tutorial");
$win->autodel_set(1);

# win 400x400
$win->resize(400,400);

my $box = pEFL::Elm::Box->add($win);
$box->horizontal_set(0);
$box->homogeneous_set(1);
$box->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$box->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
$box->show();
$win->resize_object_add($box);

my $z = _naviframe_populate_gen($win, "Before", \&_populate_cb__push_then_insert_before);
push @naviframe_zipper, $z;
$box->pack_end($z->{naviframe});

my $z1 = _naviframe_populate_gen($win, "After", \&_populate_cb__push_then_insert_after);
push @naviframe_zipper, $z1;
$box->pack_end($z1->{naviframe});

my $z2 = _naviframe_populate_gen($win, "Push", \&_populate_cb__push);
push @naviframe_zipper, $z2;
$box->pack_end($z2->{naviframe});

$win->smart_callback_add("delete_request", \&_delete_cb, \@naviframe_zipper);

# win 400x400px
$win->resize(400,400);
$win->show();

pEFL::Elm::run();

pEFL::Elm::shutdown();

sub _naviframe_add {
	my ($parent) = @_;
	
	my $z = {};
	$z->{naviframe} = pEFL::Elm::Naviframe->add($parent);
	my $type = $z->{naviframe}->widget_type_get();
	
	$z->{popped} = [];
	
	$z->{naviframe}->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
	$z->{naviframe}->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
	$z->{naviframe}->show();
	
	# By default, objects are destroyed when they are popped from the naviframe
    # To save and re-use them, enable "preserve_on_pop"
    $z->{naviframe}->content_preserve_on_pop_set(1);
    
    return $z;
}

# Save the element that is popped from the naviframe
# callback of the prev button
sub _naviframe_prev {
	my ($data, $o, $event_info) = @_;
	
	my $z = $data;
	my @popped = @{$z->{popped}};
	# if more than one item push in naviframe
	if ( ${$z->{naviframe}->bottom_item_get()} != ${$z->{naviframe}->top_item_get()} ) {
		# NOTE: $nav->item_pop_pv is a perl specific version of $nav->item_pop() that tries
		# to bless the returned EvasObject to the appropriate perl class
		# If you use the pEFL-Elm standard version you must bless the returned widget manually
		# as following:
		# my $content = $z->{naviframe}->item_pop();
		# bless($content, "ElmLabelPtr"); # or bless($content, "pEFL::Elm::Label");
		# unshift @popped, $content;
		unshift @popped, $z->{naviframe}->item_pop_pv();
		$z->{popped} = \@popped
	}
}

# Set the first element after the current one available and push it to the
# naviframe
# callback of the next button
sub _naviframe_next {
	my ($data, $o, $event_info) = @_;
	
	my $z = $data;
	my @popped = @{ $z->{popped} };
	
	my $label = shift(@popped);
	$z->{popped} = \@popped;
	
	if ($label) {
		# The widget is saved inside the naviframe but nothing more; we need
		# to create new buttons and set the title text again (copy the one
		# from the label that is saved).
		my $text = $label->text_get();
		
		# The _button function creates a button which is either "Previous" (-1) or
        # "Next" (1)
        my $prev = _button($z, -1);
        my $next = _button($z, 1);
        
        my $it = $z->{naviframe}->item_push($text,$prev,$next,$label,undef);
	}
}

# Build either a "Previous" or a "Next" button
sub _button {
	my ($z, $direction) = @_;
	
	my ($text, $callback);
	if ($direction < 0) {
		$text = "Previous";
		$callback = \&_naviframe_prev;
	}
	else {
		$text = "Next";
		$callback = \&_naviframe_next;
	}
	
	my $button = pEFL::Elm::Button->add($z->{naviframe});
	$button->text_set($text);
	$button->smart_callback_add("clicked", $callback, $z);
	return $button;
}

# Generic naviframe-populate function:
# Its third (and last) parameter is a callback for customization, i.e. pushes
# the new items to a specific position; it returns a "context" value that is
# used between its calls and enables behaviors such as "push after the
# previously-pushed item"
sub _naviframe_populate_gen {
	my ($parent, $id, $populate_cb) = @_;
	
	my $context = 0;
	my $z = _naviframe_add($parent);
	
	my $i;
	for ($i = 0; $i < 20; $i++) {
		my $label = pEFL::Elm::Label->add($z->{naviframe});
		my $label2 = pEFL::Elm::Label->add($z->{naviframe});
		
		$label->text_set("$id [$i]");
		$label->show();
		$label->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
		$label->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);
		
		# The _button function creates a button which is either "Previous" (-1) or
        # "Next" (1)
        my $prev = _button($z, -1);
        my $next = _button($z, 1);
        
        # Use the populate_cb callback to provide the customization of the way the
        # elements are added inside the naviframe
        $context = $populate_cb->($z->{naviframe}, "$id [$i]", $prev, $next, $label, $context);
	}
	
	return $z;
}

# Push items one after the other
sub _populate_cb__push {
	my ($nav, $title, $prev, $next, $label, $context) = @_;
	
	return $nav->item_push($title, $prev, $next, $label, undef);
	
}

# Push items one after the other but use insert_after for it
sub _populate_cb__push_then_insert_after {
	my ($nav, $title, $prev, $next, $label, $context) = @_;
	
	if ($context != 0) {
		return $nav->item_insert_after($context, $title, $prev, $next, $label, undef);
	}
	else {
		return $nav->item_push($title, $prev, $next, $label, undef);
	}
}

# Push one item and repeatedly insert new items before the last inserted
# item
sub _populate_cb__push_then_insert_before {
	my ($nav, $title, $prev, $next, $label, $context) = @_;
	
	if ($context) {
		return $nav->item_insert_before($context, $title, $prev, $next, $label, undef);
	}
	else {
		return $nav->item_push($title, $prev, $next, $label, undef);
	}
}

sub _delete_cb {
	my ($win, $zipper) = @_;
	$win->del();
}
