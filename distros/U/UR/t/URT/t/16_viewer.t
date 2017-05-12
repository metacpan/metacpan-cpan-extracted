#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More;

eval { App::UI->user_interface("gtk2") };
if ($@) {
    plan skip_all => "skipping because gtk will not initialize",
}
else {
    plan tests => 7;
    #Gtk->timeout_add(
if(0) {
    Glib::Timeout->add(
        1000, # = 1 second ...slow me down for debugging
        sub {
            my @w = App::UI::Gtk2->windows();
            for my $window (@w) {
                my $viewer_widget = $window->child();
                $window->remove($viewer_widget);
                $window->destroy;
                App::UI::Gtk2->remove_window($window);
            }
            return 1;
        }
    );
}
}

App->init; 

my $v = URT::RAMThingy->create_viewer(
    toolkit => "gtk2", 
    aspects => [
        'clone_name',
        'chromosome',
    ],
); 
ok($v, "created a viewer");
$v->show_modal; 

my @a = map { $_->aspect_name } sort { $a->position <=> $b->position } $v->get_aspects();
is_deeply(\@a, [qw/clone_name chromosome/], "aspects are correct");

my $s = URT::RAMThingy->create(clone_name => "MY_CC-loneA01", map_order => 123, chromosome => "y"); 
ok($s, "created a subject");

$v->set_subject($s); 
is($v->get_subject,$s, "set the subject for the viewer");
$v->show_modal;

ok($v->add_aspect("map_order"), "added a new aspect");
@a = map { $_->aspect_name } sort { $a->position <=> $b->position } $v->get_aspects();
is_deeply(\@a, [qw/clone_name chromosome map_order/], "returned aspects reflect the new addition");
$v->show_modal; 

$v->remove_aspect("chromosome");
@a = map { $_->aspect_name } sort { $a->position <=> $b->position } $v->get_aspects();
is_deeply(\@a, [qw/clone_name map_order/], "returned aspects reflect the removal");
$v->show_modal; 

1;
