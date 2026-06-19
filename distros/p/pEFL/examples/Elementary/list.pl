# Based on the Basic tutorial code Basic List
# see https://www.enlightenment.org/develop/legacy/tutorial/basic_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

my $counter = 0;

use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("Main", "Hello, World");
$win->autodel_set(1);
$win->resize(400,400);

my $list = pEFL::Elm::List->add($win);

# $list->horizontal_set(1); //uncoment to get horizontal
# size giving scrollbar
$list->resize(320,300);
$list->mode_set(ELM_LIST_LIMIT);

# first item: text
$list->item_append("Text item",undef, undef,\&select_cb,undef);

# second item: icon
my $icon = pEFL::Elm::Icon->add($list);
$icon->standard_set("chat");
$list->item_append("Icon item", $icon, undef,\&select_cb,undef);

# third item: button
my $button = pEFL::Elm::Button->add($list);
$button->text_set("Button");
my $itembutton = $list->item_append("Button item", undef, $button, \&select_cb,undef);

$list->go();
$list->show();

$list->smart_callback_add("selected", \&_prepend_itembutton_cb, $itembutton);

$win->show();

pEFL::Elm::run();

pEFL::Elm::shutdown();

sub select_cb {
	my ($data, $obj, $evinfo) = @_;
	
	my $selected = pEFL::ev_info2obj($evinfo, "pEFL::Elm::ListItem");
	print "The text of selected item " . $selected->text_get() . "\n";
}

sub _prepend_itembutton_cb {
    my ($data, $obj, $event_info) = @_;
    my $li = $obj;

    my $selected = $li->selected_item_get();
    my $next = $selected->next;
    
	if ($next) {
		my $text = $next->text_get();
		print "Text of next item: $text\n";
		$li->item_prepend("Item $counter", undef, undef, \&select_cb, undef);
		$counter++;
		$li->go();
    }
    
}
