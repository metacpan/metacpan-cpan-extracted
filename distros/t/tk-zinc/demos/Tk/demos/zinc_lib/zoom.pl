#!/usr/bin/perl
# $Id: zoom.pl,v 1.4 2004/04/30 11:35:18 lecoanet Exp $
# This simple demo has been developped by C. Schlienger <celine@intuilab.com>

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);


use Tk;
use Tk::Zinc;
use strict;


my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();

###########################################
# Text zone
###########################################

my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2, -height => 4);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
	      'This toy-appli shows zoom actions on waypoint and curve items.
The following operations are possible:
   Click "-" to zoom out
   Click "+" to zoom in ' );

###########################################
# Zinc
###########################################
my $zinc_width=600;
my $zinc_height=500;
my $zinc = $mw->Zinc(-width => $zinc_width, -height => $zinc_height,
		     -font => "10x20",
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

###########################################
# Waypoints and sector
###########################################

my $wp_group = $zinc->add('group', 1, -visible => 1);

my $p1=[200, 100];
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

my $p2=[300, 150];
my $wp2 = $zinc->add('waypoint',$wp_group, 1,
		     -position => $p2,
		     -connecteditem => $wp1,
		     -connectioncolor => 'blue',
		     -symbolcolor => 'blue',
		     -labelformat => 'x20x18+0+0',
		     -leaderwidth=>'0',
		     -labeldx=>'-20',
		    );

$zinc->itemconfigure($wp2, 0,
		     -text => "RE",
		    );

my $p3=[400, 50];
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

my $p4=[350, 450];
my $wp4 = $zinc->add('waypoint', $wp_group, 2,
			     -position => $p4,
			     -connecteditem => $wp2,
			     -connectioncolor => 'blue',
			     -symbolcolor => 'blue',
		    -labelformat => 'x20x18+0+0',
		     -leaderwidth=>'0',
		     -labeldy=>'-15'
		    );
$zinc->itemconfigure($wp4, 0,
		     -text => "FA",
		    );

		    
my $p5=[300, 250];
my $wp5 = $zinc->add('waypoint', $wp_group, 2,
		     -position => $p5,
		     -connectioncolor => 'blue',
		     -symbolcolor => 'blue',
		     -labelformat => 'x20x18+0+0',
		     -leaderwidth=>'0',
		     -labeldy=>'-15'
		    );
$zinc->itemconfigure($wp5, 0,
		     -text => "SOL",
		    );


my $p6=[170, 240];
my $wp6 = $zinc->add('waypoint', $wp_group, 2,
		     -position => $p6,
		     -connecteditem => $wp5,
		     -connectioncolor => 'blue',
		     -symbolcolor => 'blue',
		     -labelformat => 'x20x18+0+0',
		     -leaderwidth=>'0',
		     -labeldx=>'-20'
		    );
$zinc->itemconfigure($wp6, 0,
		     -text => "LA",
		    );

my $p7=[550, 200];
my $wp7 = $zinc->add('waypoint', $wp_group, 2,
		     -position => $p7,
		     -connecteditem => $wp5,
		     -connectioncolor => 'blue',
		     -symbolcolor => 'blue',
		     -labelformat => 'x20x18+0+0',
		     -leaderwidth=>'0',
		     -labeldx=>'20'
		    );
$zinc->itemconfigure($wp7, 0,
		     -text => "SI",
		    );


my $sector = $zinc ->add('curve',$wp_group,[300,0,400,50,500,100,550,200,550,400,350,450,170,240,200,100,300,0]);

###################################################
# control panel
###################################################
my $rc = $mw->Frame()->pack();

#the reference of the scale function is top-left corner of the zinc object
#so we first translate the group to zoom in order to put its center on top-left corner
#change the scale of the group
#translate the group to put it back at the center of the zinc object 

my $minus=$rc->Button(-width => 2, 
		      -height => 2,
		      -text => '-',
		      -command=>sub{
			$zinc->translate($wp_group,-$zinc_width/2,-$zinc_height/2);
			$zinc->scale($wp_group,0.8,0.8);
			$zinc->translate($wp_group, $zinc_width/2,$zinc_height/2);
		      })->pack(-side=>'left');


my $plus=$rc->Button(-width => 2, 
		     -height => 2,
		     -text => '+',
		     -command=>sub{
		       $zinc->translate($wp_group, -$zinc_width/2,-$zinc_height/2);
		       $zinc->scale($wp_group,1.2,1.2);
		       $zinc->translate($wp_group,$zinc_width/2,$zinc_height/2);
		     })->pack(-side => 'right');



MainLoop;
