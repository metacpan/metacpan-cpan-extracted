#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use FileHandle;
use UI::Dialog::Console;

my $d = new UI::Dialog::Console ( title => "UI::Dialog::Console Demo",
								  debug => 0, height => 20, width => 65 );


$d->msgbox( text => "This message box is provided by one of the following: dialog, whiptail, or simple ASCII." );
