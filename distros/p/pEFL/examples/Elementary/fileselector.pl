use strict;
use warnings;

use pEFL::Elm;
use pEFL::Evas;

my $size;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

#my $box = pEFL::Elm::Box->add($win);
#$box->horizontal_set(1);
#$box->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
#$win->resize_object_add($box);
#$box->show();

my $vbox = pEFL::Elm::Box->add($win);
$vbox->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$vbox->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
$vbox->show();
$win->resize_object_add($vbox);
#$box->pack_end($vbox);

my $fs = pEFL::Elm::Fileselector->add($win);
$fs->is_save_set(1);
$fs->expandable_set(0);
$fs->path_set("/tmp");

$fs->multi_select_set(1);

$fs->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$fs->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
$fs->show();
$vbox->pack_end($fs);


$fs->smart_callback_add("done", \&_fs_done, $fs);
$fs->smart_callback_add("activated", \&_fs_done, $fs);$fs->smart_callback_add("selected", \&_fs_selected, $fs);
$fs->smart_callback_add("directory,open", \&_fs_selected, $fs);

# win 400x400
$win->resize(800,600);
$win->show();


pEFL::Elm::run();

pEFL::Elm::shutdown();

sub _fs_done {

my ($data, $obj, $ev_info) = @_;
my $selected = pEFL::ev_info2s($ev_info);
print "We are done!! Selected file is $selected\n";
pEFL::Elm::exit();

}

sub _fs_selected {
    my ($data, $obj, $ev_info) = @_;
my $selected = pEFL::ev_info2s($ev_info);
print "There is been a selection. Selected file is $selected\n";
}
