#! /bin/perl

use Tk;
use Tk::JComboBox;

###############################################################
## This example demonstrates the -popupcreate option in action.
## I put this together to help with fixing a problem with the
## option on 19 Sep 06. type in a list of words, letters, numbers 
## separated by spaces into the Entry, and then press the JComboBox.
## It should dynamically insert these items into the JComboBox.
## Note that this is just one way this could have been accomplished.
## There are plenty of others.
################################################################

my $mw = MainWindow->new;
my $entry = $mw->Entry->pack;

my $jcb = $mw->JComboBox(
   -choices => [qw/one two three four/],
   -entrywidth => '16',
   -highlightthickness => 0,
   -listwidth => '16',
   -mode => 'readonly',
   -popupcreate => \&addItems,
)->pack;

MainLoop;

sub addItems {
   my @items = split(/ /, $entry->get());
   $jcb->removeAllItems;
   $jcb->configure(-choices => \@items) if @items;
 }

