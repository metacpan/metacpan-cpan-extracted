# Based on the Basic tutorial code Basic Button
# see https://www.enlightenment.org/develop/legacy/tutorial/form_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;
use pEFL::Evas;
use Scalar::Util qw(blessed refaddr);

my @contacts = (
	{name => "Alexander Holmes", mobile => "+1234567896", address => "", email => "alexander_holmes\@tizen.org", icon => "c1.svg"},
   	{name => "Lara Alvaréz", mobile => "+9876543216", address => "", email => "lara_alvares\@tizen.org", icon => "c2.svg"},
   	{name => "Aksel Møller", mobile => "+1679432846", address => "", email => "aksel_moller\@tizen.org",icon => "c3.svg"},
   	{name => "Anir Amghar", mobile => "+1679432846", address => "", email => "anir_amghar\@tizen.org",icon => "c4.svg"},
   	{name => "Noémie Cordier", mobile => "+1679432846", address => "", email => "noemie_cordier\@tizen.org",icon => "c5.svg"},
   	{name => "Henry Thompson", mobile => "+1679432846", address => "", email => "henry_thompson\@tizen.org",icon => "c6.svg"}
);

my $nav;

my @form_items = ("name :", "mobile :", "address :", "email :");

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

# win 400x400
$win->resize(400,400);

# Create the Naviframe
$nav = pEFL::Elm::Naviframe->add($win);
$nav->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$win->resize_object_add($nav);
$nav->show();

# Create the list of contacts
my $list = _create_contact_list($win);

# Push the list on top of the naviframe
$nav->item_push(undef,undef,undef,$list,undef);

$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub _create_contact_list {
	my ($parent) = @_;
	
	# Create a new genlist
	my $list = pEFL::Elm::Genlist->add($parent);
	$list->show();
	
	# Create a new item class for the genlist
	my $itc = pEFL::Elm::GenlistItemClass->new();
	my $addr = $$itc;
	$itc->item_style("default");
	# Set the callback which will be used when the genlist text will be created
	$itc->text_get(\&_genlist_text_get);
	# Set the callback wich will be used when the content of the item will be created
	$itc->content_get(\&_genlist_content_get);
	$itc->state_get(undef);
	$itc->del(undef);
	
	# Create a genlist item for each item in the contacts array
	foreach my $contact (@contacts) {
		# Append the item, add a callback when the item is selected, and use the
        # current contact item as data pointer for the callbacks.
        $list->item_append($itc,$contact,undef,ELM_GENLIST_ITEM_NONE,\&_contact_selected_cb,$contact);
	}
	
	return $list;
}

sub _genlist_content_get {
	my ($contact, $obj, $part) = @_;
	
	if ($part eq "elm.swallow.icon") {
		# Create new icon
		my $ic = pEFL::Elm::Icon->add($obj);
		# Set the filename of the file which is to be loaded
		$ic->file_set("./" . $contact->{icon}, undef );
		# Keep the ratio squared
		$ic->size_hint_aspect_set(EVAS_ASPECT_CONTROL_VERTICAL, 1, 1);
		
		return $ic;
	}
	
	return undef;
}

sub _genlist_text_get {
	my ($contact, $obj, $part) = @_;
	
	return $contact->{name};
}

sub _contact_selected_cb {
	my ($contact, $obj, $evinfo) = @_;
	
	# Create a new contact form
	my $form = _create_contact_form($nav, $contact);
	# Push the form on top of naviframe
	$nav->item_push(undef,undef,undef,$form,undef);
}

sub _create_contact_form {
	my ($parent, $contact) = @_;
	
	my $i;
	
	my $vbox = pEFL::Elm::Box->add($parent);
	$vbox->align_set(0,0);
	$vbox->show();
	
	# Add the icon to the vbox
	my $ic = pEFL::Elm::Icon->add($vbox);
	$ic->file_set("./" . $contact->{icon}, undef );
	$ic->size_hint_min_set(96,96);
	$ic->show();
	$vbox->pack_end($ic);
	
	# Create the entries for contact information
	foreach my $form_item (@form_items) {
		# hbox
		my $hbox = pEFL::Elm::Box->add($vbox);
		$hbox->horizontal_set(1);
		$hbox->padding_set(32,32);
		$hbox->size_hint_weight_set(EVAS_HINT_EXPAND,0);
		$hbox->size_hint_align_set(EVAS_HINT_FILL,0);
		$hbox->show();
		
		# label
		my $label = pEFL::Elm::Label->add($hbox);
		$label->text_set($form_item);
		$label->size_hint_weight_set(0,0);
		$label->size_hint_align_set(0,0);
		$label->show();
		
		# edit
		my $edit = pEFL::Elm::Entry->add($hbox);
		
		my $str = undef;
		$str = $contact->{name} if ($form_item eq "name :");
		$str = $contact->{mobile} if ($form_item eq "mobile :");
		$str = $contact->{address} if ($form_item eq "address :");
		$str = $contact->{email} if ($form_item eq "email :");
		
		$edit->text_set($str);
		$edit->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
		$edit->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
		$edit->show();
		
		$hbox->pack_end($label);
		$hbox->pack_end($edit);
		
		$vbox->pack_end($hbox);
	}
	
	return $vbox;
}