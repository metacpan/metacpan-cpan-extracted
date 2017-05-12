#!/usr/bin/env perl
use strict;
use warnings;
use diagnostics;
use constant { TRUE => 1, FALSE => 0 };

use lib qw(./lib);
use UI::Dialog::Screen::Menu;

#
#: Demonstrate usage of UI::Dialog::Screen::Menu
#


our $counter = 0;

my $s = new UI::Dialog::Screen::Menu
 (
  title => "test title",
  text => "test text",
  order => [ 'dialog' ]
 );
$s->add_menu_item
 ( "An Action ".$counter,
   sub {
       my ($self,$dialog,$index) = @_;
       $counter++;
       $s->set_menu_item( $index, "An Action ".$counter, undef );
   }
 );

my $s2 = new UI::Dialog::Screen::Menu
 (
  title => "test 2 title",
  text => "test 2 text",
  order => [ 'dialog' ]
 );
$s2->add_menu_item
 ( "Another Option",
   sub {
       my ($self,$dialog,$index) = @_;
       $dialog->msgbox( text => "Hi" );
   }
 );
$s->add_menu_item
 ( "Next Screen",
   sub { $s2->loop(); }
 );

$s->loop();

exit 0;
