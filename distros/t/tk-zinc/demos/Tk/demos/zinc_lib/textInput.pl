#!/usr/bin/perl -w
# $Id: textInput.pl,v 1.4 2003/09/24 15:08:37 mertz Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

package textInput; # for avoiding symbol re-use between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);


use Tk;
use Tk::Zinc;
use strict;

use Tk::Zinc::Text;  # the module for facilitating text input with zinc

my $mw = MainWindow->new();

###########################################
# Text zone
###########################################

my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2, -height => 4);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
'This toy-appli demonstrates the use of the
Tk::Zinc::Text module. This module is designed for
facilitating text input "a la emacs" on text items or on
fields of items such as tracks, waypoints or tabulars.');


###########################################
# Zinc
##########################################
my $zinc = $mw->Zinc(-width => 500, -height => 300,
		     -font => "10x20",
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

Tk::Zinc::Text->new ($zinc);  # for mapping text input bindings on item with a 'text' tag.


### creating a tabular with 3 fields, 2 of them being editable
my $labelformat1 = "130x100 x130x20+0+0 x130x20+0+20 x130x20+0+40";

my $x=120;
my $y=6;
my $track = $zinc->add('track',1, 3,
		       -position => [$x,$y],
		       -speedvector => [40, 10],
		       -labeldistance => 30,
		       -labelformat => $labelformat1,
		       -tags => 'text',
		       );
# moving the track, to display past positions
foreach my $i (0..5) {  $zinc->coords("$track",[$x+$i*10,$y+$i*2]); }

$zinc->itemconfigure($track, 0,
		     -border => "contour",
		     -text => "not editable",
		     -sensitive => 0,
		     );
$zinc->itemconfigure($track, 1,
		     -border => "contour",
		     -text => "editable",
		     -sensitive => 1,
		     );
$zinc->itemconfigure($track, 2,
		     -border => "contour",
		     -text => "editable too",
		     -alignment => "center",
		     -sensitive => 1,
		     );

# creating a text item, tagged with 'text', but not editable because
# it is not sensitive
$zinc->add('text', 1,
	   -position => [220,160],
	   -text => "this text is not
editable because it is
not sensitive",
	   -sensitive => 0,
	   -tags => ['text'],
	   );

# creating an editable text item
$zinc->add('text', 1,
	   -position => [50,230],
	   -text => "this text IS
editable",
	   -sensitive => 1,
	   -tags => ['text'],
	   );



Tk::MainLoop;
