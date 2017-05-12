#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use UI::Dialog::KDE;

my $d = new UI::Dialog::KDE ( title => "UI::Dialog::KDE Demo",
							  debug => 0, height => 20, width => 65 );

$d->msgbox( text => "This message box is provided by one of the following: kdialog or Xdialog." );
