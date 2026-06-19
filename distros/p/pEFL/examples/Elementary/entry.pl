#! /usr/bin/perl
use strict;
use warnings;


use pEFL::Evas;
use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

my $rehighlight = 1;

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

my $box = pEFL::Elm::Box->add($win);
$box->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
$win->resize_object_add($box);
$box->show();

my $en = pEFL::Elm::Entry->add($win);
$en->autosave_set(0);
# Important: The file must exist. Otherwise saving doesn't work!!
$en->file_set("./test.txt",1);
my ($file, $text_format) = $en->file_get();
print "Saving to $file in Format $text_format (0=uft8, 1=Markup)\n";
$en->entry_set("This text is outside <a href=anc-01>but this one is an anchor</a>");
$en->file_set("./da_test.txt", ELM_TEXT_FORMAT_MARKUP_UTF8);
$en->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$en->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
$en->line_wrap_set(ELM_WRAP_WORD);
$en->markup_filter_append(\&filter_user, undef);
$en->markup_filter_prepend("limit_size", {max_char_count => 50, max_byte_count => 0});
$en->markup_filter_append("accept_set", {accepted=> "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",rejected => "0123456789"});
$en->smart_callback_add("anchor,clicked" => \&anchor_clicked, undef);
$box->pack_end($en);
$en->show();

$win->resize(300,780);


$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub filter_user {
    my ($data, $entry, $text) = @_;
    print "TEXT $text\n";
    return $text;
}

sub anchor_clicked {
    my ($data,$entry,$ev) = @_;
    
    my $pobj = pEFL::ev_info2obj( $ev, "pEFL::Elm::EntryAnchorInfo");
    my $name = $pobj->name(); 
    my $button = $pobj->button();
    my $x = $pobj->x; my $y = $pobj->y; my $w = $pobj->w; my $h = $pobj->h;
    print "NAME $name \n BUTTON $button\n X: $x, Y: $y, W: $w, H: $h\n";
    $entry->file_save();
}


