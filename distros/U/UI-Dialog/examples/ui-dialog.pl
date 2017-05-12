#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use UI::Dialog;

my $d = new UI::Dialog ( title => "UI::Dialog Demo",
						 debug => 0, height => 20, width => 65 );


$d->msgbox( text => [ "This message box is provided by one of the following: zenity, Xdialog or gdialog. ",
					  "(Or if from a console: dialog, whiptail, ascii)" ] );

