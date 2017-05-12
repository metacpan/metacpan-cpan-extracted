#!/usr/bin/perl
# $Id: translation.pl,v 1.3 2004/04/30 11:35:18 lecoanet Exp $
# This simple demo has been developped by C. Schlienger <celine@intuilab.com>

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


use Tk;
use Tk::Zinc;
use strict;


my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();

###########################################
# Text zone
###########################################

my $text = $mw->Scrolled(qw/Text -relief sunken -borderwidth 2 -setgrid true
	      -height 6 -scrollbars e/);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
	      'This toy-appli shows translations on waypoint items.
The following operations are possible:
   Click "Up" for up translation
   Click "Left" for left translation
   Click "Right" for right translation
   Click "Down" for down translation' );

###########################################
# Zinc
###########################################
my $zinc_width=600;
my $zinc_height=400;
my $zinc = $mw->Zinc(-width => $zinc_width, -height => $zinc_height,
		     -font => "10x20",
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

###########################################
# Waypoints
###########################################

my $wp_group = $zinc->add('group', 1, -visible => 1);

my $p1=[200, 200];
my $wp1 = $zinc->add('waypoint',$wp_group, 1,
		    -position => $p1,
		    -connectioncolor => 'green',
		    -symbolcolor => 'blue',
		    -labelformat => 'x20x18+0+0',
		    -leaderwidth=>'0',
		    -labeldx=>'-20'
		   );
$zinc->itemconfigure($wp1, 0,
		     -text => "DO",
		    );

my $p2=[300, 300];
my $wp2 = $zinc->add('waypoint',$wp_group, 1,
		     -position => $p2,
		     -connecteditem => $wp1,
		     -connectioncolor => 'blue',
		     -symbolcolor => 'blue',
		     -labelformat => 'x20x18+0+0',
		     -leaderwidth=>'0',
		     -labeldx=>'-20',
		     #-labeldy=>'30'
		    );

$zinc->itemconfigure($wp2, 0,
		     -text => "RE",
		    );

my $p3=[400, 150];
my $wp3 = $zinc->add('waypoint', $wp_group, 2,
		     -position => $p3,
		     -connecteditem => $wp2,
		     -connectioncolor => 'blue',
		     -symbolcolor => 'blue',
		     -labelformat => 'x20x18+0+0',
		     -leaderwidth=>'0',
		     -labeldx=>'20',
		     -labeldy=>'+10'
		    );
$zinc->itemconfigure($wp3, 0,
		     -text => "MI",
		    );

###################################################
# control panel
###################################################
my $rc = $mw->Frame()->pack();
my $up=$rc->Button(-width => 2, 
		   -height => 2,
		   -text => 'Up',
		   -command=>sub{
		     #--------------------------------
		     # Up translation
		     #--------------------------------
		     $zinc->translate("$wp_group",0,-10);
		   })->grid(-row => 0,
			    -column => 1);

my $left=$rc->Button(-width => 2, 
		     -height => 2,
		     -text => 'Left',
		     -command=>sub{
		       #--------------------------------
		       # Left translation
		       #--------------------------------
		       $zinc->translate("$wp_group",-10,0);
		     })->grid(-row => 1,
			      -column => 0);

my $right=$rc->Button(-width => 2, 
		      -height => 2,
		      -text => 'Right',
		      -command=>sub{
			#--------------------------------
			# Right translation
			#--------------------------------
			$zinc->translate("$wp_group",10,0);
		      })->grid(-row => 1,
			       -column => 2);

my $down=$rc->Button(-width => 2, 
		     -height => 2,
		     -text => 'Down',
		     -command=>sub{
		       #--------------------------------
		       # Down translation
		       #--------------------------------
		       $zinc->translate("$wp_group",0,10);
		     })->grid(-row => 2,
			      -column => 1);




MainLoop;
