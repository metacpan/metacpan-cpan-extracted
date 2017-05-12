#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use FileHandle;
use UI::Dialog::GNOME;

my $d = new UI::Dialog::GNOME ( title => "UI::Dialog::GNOME Demo",
								debug => 0, height => 20, width => 65 );


$d->msgbox( text => "This message box is provided by one of the following: zenity, Xdialog or gdialog." );
