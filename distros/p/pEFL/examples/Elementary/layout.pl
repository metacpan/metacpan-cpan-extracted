#! /usr/bin/perl
#use strict;
use warnings;

use pEFL::Evas;
use pEFL::Elm;

my $btn_large = 0;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

my $layout = pEFL::Elm::Layout->add($win);
$layout->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$win->resize_object_add($layout);
$layout->file_set("./layout_example.edj", "example/mylayout3");
$layout->show();

$layout->signal_callback_add("size,changed","",\&_size_changed_cb2,$layout);
$layout->signal_callback_add("size,changed","",\&_size_changed_cb,$layout);
$layout->signal_callback_del("size,changed","",\&_size_changed_cb2);

my $btn = pEFL::Elm::Button->add($win);
$btn->text_set("Enlarge me");
$btn->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$btn->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
$layout->part_content_set("example/custom",$btn);
$btn->smart_callback_add("clicked", \&_swallow_btn_cb,$layout);
#$btn->signal_callback_add("size,changed","",\&_size_changed_cb2,$layout);

$win->resize(160,160);
$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub _swallow_btn_cb {
    my ($layout, $btn, $evInfo) = @_;
    
    unless ($btn_large) {
        $btn_large = 1;
        $layout->signal_emit("button,enlarge","");
        $btn->text_set("Reduce me!");
    }
    else {
        $btn_large = 0;
        $layout->signal_emit("button,reduce","");
        $btn->text_set("Enlarge me!");
        
    }
}

sub _size_changed_cb {
    my ($data, $layout, $emission, $source) = @_;
    $layout->sizing_eval();
}
sub _size_changed_cb2 {
    my ($data, $layout, $emission, $source) = @_;
    $layout->sizing_eval();
    print "This will not be displayed, as the callback was deleted\n";
}
