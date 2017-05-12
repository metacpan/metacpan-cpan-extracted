#!/usr/bin/perl -w
# $Id: simpleradar.pl,v 1.7 2004/03/19 11:34:25 mertz Exp $
# This simple radar has been initially developped by P. Lecoanet <lecoanet@cena.fr>
# It has been adapted by C. Mertz <mertz@cena.fr> for demo purpose.

package simpleradar; # for avoiding symbol collision between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);


use Tk;
use Tk::Zinc;

use strict;

# to find the SimpleRadarControls module
require Tk->findINC('demos/zinc_pm/SimpleRadarControls.pm');

my $mw = MainWindow->new();

my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2,
		     -height => 11);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
	      'This a very simple radar display, where you can see flight tracks,
   a so-called ministrip (green) and and extend flight label (tan background).
   The following operations are possible:
     Shift-Button 1 for using a squarre lasso (result in the terminal).
     Click Button 2 for identifiying the closest item (result in the terminal).
     Button 3 for dragging most items, but not the ministrip (not in the same group).
     Shift-Button 3 for zooming independently on X and Y axis.
     Ctrl-Button 3 for rotationg graphic objects.
     Enter/Leave in flight label fields, speed vector, position and leader,
       and in the ministrip fields.
     Click Button 1 on flight track to display a route.');



###################################################
# creation zinc
###################################################
my $top = 1;
my $scale = 1.0;
my $center_x = 0.0;
my $center_y = 0.0;
my $zinc_width = 800;
my $zinc_height = 500;
my $delay = 2000;
my $rate = 0.3;
my %tracks = ();

my $pause = 0; # if true the flight are no more moving
my $zinc = $mw->Zinc(-backcolor => 'gray65',
		     -relief => 'sunken',
		     -font => "10x20");
$zinc->pack(-expand => 1, -fill => 'both');
$zinc->configure(-width => $zinc_width, -height => $zinc_height);
#$radar = $top;
my $radar = $zinc->add('group', $top, -tags => ['controls', 'radar']);
$zinc->configure(-overlapmanager => $radar);


###################################################
# creation panneau controle
###################################################
my $rc = $mw->Frame()->pack();
$rc->Button(-text => 'Up',
	    -command => sub { $center_y -= 30.0;
			      update_transform($zinc); })->grid(-row => 0,
								-column => 2,
								-sticky, 'ew');
$rc->Button(-text => 'Down',
	    -command => sub { $center_y += 30.0;
			      update_transform($zinc); })->grid(-row => 2,
								-column => 2,
								-sticky, 'ew');
$rc->Button(-text => 'Left',
	    -command => sub { $center_x += 30.0;
			      update_transform($zinc); })->grid(-row => 1,
								-column => 1);
$rc->Button(-text => 'Right',
	    -command => sub { $center_x -= 30.0;
			      update_transform($zinc); })->grid(-row => 1,
								-column => 3);
$rc->Button(-text => 'Expand',
	    -command => sub { $scale *= 1.1;
			      update_transform($zinc); })->grid(-row => 1,
								-column => 4);
$rc->Button(-text => 'Shrink',
	    -command => sub { $scale *= 0.9;
			      update_transform($zinc); })->grid(-row => 1,
								-column => 0);
$rc->Button(-text => 'Reset',
	    -command => sub { $scale = 1.0;
			      $center_x = $center_y = 0.0;
			      update_transform($zinc); })->grid(-row => 1,
								-column => 2,
								-sticky, 'ew');

$rc->Button(-text => 'Pause',
	    -command => sub { $pause = ! $pause;
			  })->grid(-row => 0,
				   -column => 6);

###################################################
# Code de reconfiguration lors d'un
# redimensionnement.
###################################################
$zinc->Tk::bind('<Configure>', [\&resize]);

sub resize {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $width = $ev->w;
    my $height = $ev->h;
    my $bw = $zinc->cget(-borderwidth);
    $zinc_width = $width - 2*$bw;
    $zinc_height = $height - 2*$bw;
    update_transform($zinc);
}

sub update_transform {
    my ($zinc) = @_;
    $zinc->treset($top);
    $zinc->translate($top, -$center_x, -$center_y);
    $zinc->scale($top, $scale, $scale);
    $zinc->scale($top, 1, -1);
    $zinc->translate($top, $zinc_width/2, $zinc_height/2);
}


###################################################
# Creation de pistes.
###################################################
my $one_of_track_item;
sub create_tracks {
    my $i = 20;
    my $j;
    my $track;
    my $x;
    my $y;
    my $w = $zinc_width / $scale;
    my $h = $zinc_height / $scale;
    my $d;
    my $item;
    
    for ( ; $i > 0; $i--) {
	$track = {};
	$track->{'item'} = $item = $zinc->add('track', $radar, 6);
	$one_of_track_item = $item;
	$tracks{$item} = $track;
	$track->{'x'} = rand($w) - $w/2 + $center_x;
	$track->{'y'} = rand($h) - $h/2 + $center_y;
	$d = (rand() > 0.5) ? 1 : -1;
	$track->{'vx'} =  (8.0 + rand(10.0)) * $d;
	$d = (rand() > 0.5) ? 1 : -1;
	$track->{'vy'} =  (8.0 + rand(10.0)) * $d;
	$zinc->itemconfigure($item,
			     -position => [$track->{'x'}, $track->{'y'}],
			     -speedvector => [$track->{'vx'}, $track->{'vy'}],
			     -speedvectorsensitive => 1,
			     -labeldistance => 30,
			     -markersize => 20,
			     -historycolor => 'gray30',
			     -filledhistory => 0,
			     -circlehistory => 1,
			     -labelformat => "x80x60+0+0 x63a0^0^0 x33a0^0>1 a0a0>2>1 x33a0>3>1 a0a0^0>2");
	$zinc->itemconfigure($item, 0,
			     -filled => 0,
			     -backcolor => 'gray60',
#			     -border => "contour",
			     -sensitive => 1
			     );
	$zinc->itemconfigure($item, 1,
			     -filled => 1,
			     -backcolor => 'gray55',
			     -text => sprintf ("AFR%03i",$i));
	$zinc->itemconfigure($item, 2,
			     -filled => 0,
			     -backcolor => 'gray65',
			     -text => "360");
	$zinc->itemconfigure($item, 3,
			     -filled => 0,
			     -backcolor => 'gray65',
			     -text => "/");
	$zinc->itemconfigure($item, 4,
			     -filled => 0,
			     -backcolor => 'gray65',
			     -text => "410");
	$zinc->itemconfigure($item, 5,
			     -filled => 0,
			     -backcolor => 'gray65',
			     -text => "Balise");
	my $b_on = sub { $zinc->itemconfigure('current', $zinc->currentpart(),
					      -border => 'contour')};
	my $b_off = sub { $zinc->itemconfigure('current', $zinc->currentpart(),
					       -border => 'noborder')};
	my $tog_b = sub { my $current = $zinc->find('withtag', 'current');
			  my $curpart = $zinc->currentpart();
			  if ($curpart =~ '[0-9]+') {
			      my $on_off = $zinc->itemcget($current, $curpart, -sensitive);
			      $zinc->itemconfigure($current, $curpart,
						   -sensitive => !$on_off);
			  }
		      };
	for ($j = 0; $j < 6; $j++) {
	    $zinc->bind($item.":$j", '<Enter>', $b_on);
            $zinc->bind($item.":$j", '<Leave>', $b_off);
            $zinc->bind($item, '<1>', $tog_b);
            $zinc->bind($item, '<Shift-1>', sub {});
        }
	$zinc->bind($item, '<Enter>',
		    sub {$zinc->itemconfigure('current',
					      -historycolor => 'red3',
					      -symbolcolor => 'red3',
					      -markercolor => 'red3',
					      -leaderwidth => 2,
					      -leadercolor => 'red3',
					      -speedvectorwidth => 2,
					      -speedvectorcolor => 'red3')});
        $zinc->bind($item, '<Leave>',
                    sub {$zinc->itemconfigure('current',
					      -historycolor => 'black',
					      -symbolcolor => 'black',
					      -markercolor => 'black',
					      -leaderwidth => 1,
					      -leadercolor => 'black',
					      -speedvectorwidth => 1,
					      -speedvectorcolor => 'black')});
        $zinc->bind($item.':position', '<1>', [\&create_route]);
        $zinc->bind($item.':position', '<Shift-1>', sub { });
        $track->{'route'} = 0;
    }
}

create_tracks();

###################################################
# creation way point
###################################################
sub create_route {
    my ($zinc) = @_;
    my $wp;
    my $connected;
    my $x;
    my $y;
    my $i = 4;
    my $track = $tracks{$zinc->find('withtag', 'current')};
    
    if ($track->{'route'} == 0) {
	$x = $track->{'x'} + 8.0 * $track->{'vx'};
	$y = $track->{'y'} + 8.0 * $track->{'vy'};
	$connected = $track->{'item'};
	for ( ; $i > 0; $i--) {
	    $wp = $zinc->add('waypoint', 'radar', 2,
			     -position => [$x, $y],
			     -connecteditem => $connected,
			     -connectioncolor => 'green',
			     -symbolcolor => 'green',
			     -labelformat => 'x20x18+0+0');
	    $zinc->lower($wp, $connected);
	    $zinc->bind($wp.':0', '<Enter>',
			sub {$zinc->itemconfigure('current', 0, -border => 'contour')});
	    $zinc->bind($wp.':position', '<Enter>',
			sub {$zinc->itemconfigure('current', -symbolcolor => 'red')});
	    $zinc->bind($wp.':leader', '<Enter>',
			sub {$zinc->itemconfigure('current', -leadercolor => 'red')});
	    $zinc->bind($wp.':connection', '<Enter>',
			sub {$zinc->itemconfigure('current', -connectioncolor => 'red')});
	    $zinc->bind($wp.':0', '<Leave>',
			sub {$zinc->itemconfigure('current', 0, -border => '')});
	    $zinc->bind($wp.':position', '<Leave>',
			sub {$zinc->itemconfigure('current', -symbolcolor => 'green')});
	    $zinc->bind($wp.':leader', '<Leave>',
			sub {$zinc->itemconfigure('current', -leadercolor => 'black')});
	    $zinc->bind($wp.':connection', '<Leave>',
			sub {$zinc->itemconfigure('current', -connectioncolor => 'green')});
	    $zinc->itemconfigure($wp, 0,
				 -text => "$i",
				 -filled => 1,
                                 -backcolor => 'gray55');
	    $zinc->bind($wp.':position', '<1>', [\&del_way_point]);
	    $x += (2.0 + rand(8.0)) * $track->{'vx'};
	    $y += (2.0 + rand(8.0)) * $track->{'vy'};
	    $connected = $wp;
	}
	$track->{'route'} = $wp;
    }
    else {
	$wp = $track->{'route'};
	while ($wp != $track->{'item'}) {
	    $track->{'route'} = $zinc->itemcget($wp, -connecteditem);
	    $zinc->bind($wp.':position', '<1>', '');
	    $zinc->bind($wp.':position', '<Enter>', '');
	    $zinc->bind($wp.':position', '<Leave>', '');
	    $zinc->bind($wp.':leader', '<Enter>', '');
            $zinc->bind($wp.':leader', '<Leave>', '');
            $zinc->bind($wp.':connection', '<Enter>', '');
            $zinc->bind($wp.':connection', '<Leave>', '');
            $zinc->bind($wp.':0', '<Enter>', '');
            $zinc->bind($wp.':0', '<Leave>', '');
            $zinc->remove($wp);
	    $wp = $track->{'route'};
	}
	$track->{'route'} = 0;
    }
}

###################################################
# suppression waypoint intermediaire
###################################################
sub find_track {
    my ($zinc, $wp) = @_;
    my $connected = $wp;
    
    while ($zinc->type($connected) ne 'track') {
	$connected = $zinc->itemcget($connected, -connecteditem);
    }
    return $connected;
}

sub del_way_point {
    my ($zinc) = @_;
    my $wp = $zinc->find('withtag', 'current');
    my $track = $tracks{find_track($zinc, $wp)};
    my $next = $zinc->itemcget($wp, -connecteditem);
    my $prev;
    my $prevnext;

    $prev = $track->{'route'};
    if ($prev != $wp) {
	$prevnext = $zinc->itemcget($prev, -connecteditem);
	while ($prevnext != $wp) {
	    $prev = $prevnext;
	    $prevnext = $zinc->itemcget($prev, -connecteditem);
	}
    }
    $zinc->itemconfigure($prev, -connecteditem => $next);
    $zinc->bind($wp.':position', '<1>', '');
    $zinc->remove($wp);
    if ($wp == $track->{'route'}) {
	if ($next == $track->{'item'}) {
	    $track->{'route'} = 0;
	}
	else {
	    $track->{'route'} = $next;
	}
    }
}


###################################################
# creation macro
###################################################
my $macro = $zinc->add("tabular", $radar, 10,
    -labelformat => "x73x20+0+0 x20x20+0+0 x53x20+20+0"
    );
$zinc->itemconfigure($macro, 0, -backcolor => "tan1", -filled => 1,
		     -fillpattern => "AlphaStipple7",
		     -bordercolor => "red3");
$zinc->itemconfigure($macro, 1 , -text => "a");
$zinc->itemconfigure($macro, 2, -text => "macro");

$zinc->itemconfigure($macro, -connecteditem => $one_of_track_item);
foreach my $part (0..2) {
    $zinc->bind("$macro:$part", "<Enter>", [ \&borders, "on"]);
    $zinc->bind("$macro:$part", "<Leave>", [ \&borders, "off"]);
}
###################################################
# creation ministrip
###################################################
my $ministrip = $zinc->add("tabular", 1, 10,
			   -labelformat => "x153x80^0^0 x93x20^0^0 x63a0^0>1 a0a0>2>1 x33a0>3>1 a0a0^0>2",
			   -position => [100, 10]);
$zinc->itemconfigure($ministrip, 0 ,
		     -filled => 1,
		     -backcolor => "grey70",
		     -border => "contour",
		     -bordercolor => "green",
		     );
$zinc->itemconfigure($ministrip, 1 ,
		     -text => 'ministrip', -color => "darkgreen",
		     -backcolor => "grey40", 
		     );
$zinc->itemconfigure($ministrip, 2 ,
		     -text => 'field1', -color => "darkgreen",
		     -backcolor => "grey40",
		     );
$zinc->itemconfigure($ministrip, 3 ,
		     -text => 'field2', -color => "darkgreen",
		     -backcolor => "grey40",
		     );
$zinc->itemconfigure($ministrip, 4 ,
		     -text => 'f3', -color => "darkgreen",
		     -backcolor => "grey40",
		     );
$zinc->itemconfigure($ministrip, 5 ,
		     -text => 'field4', -color => "darkgreen",
		     -backcolor => "grey40",
		     );

foreach my $field (1..5) {
    $zinc->bind("$ministrip:$field", '<Enter>',
		sub {
		    $zinc->itemconfigure('current', $field,
					 -border => 'contour',
					 -filled => 1,
					 -color => 'white'
					 )
		    });
$zinc->bind("$ministrip:$field", '<Leave>',
    sub {$zinc->itemconfigure('current', $field,
			      -border => '',
			      -filled => 0,
			      -color => 'darkgreen'
			      )});
}

###################################################
# creation map
###################################################
$mw->videomap("load", Tk->findINC("demos/zinc_data/videomap_paris-w_90_2"), 0, "paris-w");
$mw->videomap("load", Tk->findINC("demos/zinc_data/videomap_orly"), 17, "orly");
$mw->videomap("load", Tk->findINC("demos/zinc_data/hegias_parouest_TE.vid"), 0, "paris-ouest");

my $map = $zinc->add("map", $radar,
		     -color => 'gray80');
$zinc->itemconfigure($map,
		     -mapinfo => 'orly');

my $map2 = $zinc->add("map", $radar,
		      -color => 'gray60',
		      -filled => 1,
		      -priority => 0,
		      -fillpattern => "AlphaStipple6");
$zinc->itemconfigure($map2,
		     -mapinfo => 'paris-ouest');

my $map3 = $zinc->add("map", $radar,
		      -color => 'gray50');
$zinc->itemconfigure($map3,
		     -mapinfo => "paris-w");


###################################################
# Création fonctions de contrôle à la souris
###################################################
new SimpleRadarControls($zinc);

###################################################
# Rafraichissement des pistes
###################################################
my $timer = $zinc->repeat($delay, [\&refresh, $zinc]);
$mw->OnDestroy(\&destroyTimersub ); # this is 

my $timerIsDead = 0;
sub destroyTimersub {
    $timerIsDead = 1;
    $mw->afterCancel($timer);
    # the timer is not really cancelled when using zinc-demos! 
}

sub refresh {
    my ($zinc) = @_;

    return if $pause;
    return if $timerIsDead;
    foreach my $t (values(%tracks)) {
	$t->{'x'} += $t->{'vx'} * $rate;
	$t->{'y'} += $t->{'vy'} * $rate;
	$zinc->itemconfigure($t->{'item'},
			     -position => [$t->{'x'}, $t->{'y'}]);
    }
}

sub borders {
    my($widget, $onoff) = @_;
    $onoff = "on" unless $onoff;
    my $contour = "noborder";
    $contour = "contour" if ($onoff eq 'on');
    $zinc->itemconfigure('current', 0, -border => $contour);
}


Tk::MainLoop();


