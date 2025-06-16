#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;
use pEFL::Evas;

my $count = 0;
my @dict;
my $curr = "";

# Open file
open my $fh, "<:encoding(utf-8)", "./dict.txt";
while (my $line=<$fh>) {
	chomp $line;
	push @dict, $line;
}
close $fh;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

my $vbox = pEFL::Elm::Box->add($win);
$vbox->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$win->resize_object_add($vbox);
$vbox->show();

my $list = pEFL::Elm::List->add($win);
$list->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$list->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
$list->show();
$vbox->pack_end($list);

my $id = pEFL::Elm::Index->add($win);
$id->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$win->resize_object_add($id);
$id->show();

foreach my $word (@dict) {
	my $lit = $list->item_append($word,undef,undef,undef,undef);

	my $first_letter = substr($word,0,1);
	
	if ($curr ne $first_letter) {
		$curr = $first_letter;
		
		my $index_it = $id->item_append($curr, undef, $lit);
		
		# TODO: elm_index_item_find#
		
		#$index_it->del_cb_set(\&_index_item_del);
	}
}

$id->smart_callback_add("delay,changed", \&_index_changed, undef);
$id->smart_callback_add("delay,changed", \&_index_selected, undef);

$id->level_go(0);

# Attribute setting knobs
my $sep = pEFL::Elm::Separator->add($win);
$sep->horizontal_set(1);
$vbox->pack_end($sep);
$sep->show();

my $hbox = pEFL::Elm::Box->add($win);
$hbox->horizontal_set(1);
$hbox->size_hint_weight_set(EVAS_HINT_EXPAND,0);
$hbox->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
$vbox->pack_end($hbox);
$hbox->show();

my $bt = pEFL::Elm::Button->add($win);
$bt->text_set("bring in index");
$bt->smart_callback_add("clicked", \&_active_set, $id);
$hbox->pack_end($bt);
$bt->show();

my $bt2 = pEFL::Elm::Button->add($win);
$bt2->text_set("delete last selected item");
$bt2->smart_callback_add("clicked", \&_item_del, $id);
$hbox->pack_end($bt2);
$bt2->show();

my $bt3 = pEFL::Elm::Button->add($win);
$bt3->text_set("delete all items");
$bt3->smart_callback_add("clicked", \&_item_del_all, $id);
$hbox->pack_end($bt3);
$bt3->show();

$win->resize(320,600);
$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub _index_item_del {
	my ($data, $obj, $evinfo) = @_;
	my $item = pEFL::ev_info2obj($evinfo, "pEFL::Elm::IndexItem");
	my $letter = $item->letter_get();
	# Workaround because elm_object_item_data_get is not implemented :-S
	$data = $pEFL::PLSide::Genitems{refaddr($item)}->{data};
	
	print "Deleting index node $letter. Comparing index tem data reported via callback "
		. "with the one returned by index's API on items: $data";
}

sub _item_del {
	my ($id, $obj, $evinfo) = @_;
	
	my $it = $id->selected_item_get(0) || undef;
	
	return unless (defined($it));
	
	my $letter = $it->letter_get();
	# Workaround because elm_object_item_data_get is not implemented :-S
	my $data = $pEFL::PLSide::Genitems{refaddr($it)}->{data};
	
	print "Deleting last selected index item, which had letter $letter (pointing to $data)\n";
	
	$it->del();
	$id->level_go(0);
}

sub _item_del_all {
	my ($id, $obj, $ev) = @_;
	$id->item_clear();
	$id->level_go(0);
}

sub _active_set {
	my ($id) = @_;
	
	my $disabled = $id->autohide_disabled_get();
	$disabled = $disabled ? 0 : 1;
	$id->autohide_disabled_set($disabled);
	
	print "Toggling index programmatically\n";
}

sub _index_changed {
	my ($data, $obj, $evinfo) = @_;
	my $item = pEFL::ev_info2obj($evinfo, "pEFL::Elm::IndexItem");
	# Workaround because elm_object_item_data_get is not implemented :-S
	$data = $pEFL::PLSide::Genitems{refaddr($item)}->{data};
	
	$data->item_bring_in();
}

sub _index_selected {
	my ($data, $obj, $evinfo) = @_;
	my $item = pEFL::ev_info2obj($evinfo, "pEFL::Elm::IndexItem");
	print "New index item selected\n";
}