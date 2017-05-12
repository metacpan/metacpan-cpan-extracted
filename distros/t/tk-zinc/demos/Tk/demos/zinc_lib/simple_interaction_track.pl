#!/usr/bin/perl
# $Id: simple_interaction_track.pl,v 1.5 2003/09/15 12:25:05 mertz Exp $
# This simple demo has been developped by C. Schlienger <celine@intuilab.com>

package simple_interaction_track; # for avoiding symbol collision between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);


use Tk;
use Tk::Zinc;
use strict;

my $mw = MainWindow->new();



###########################################
# Zinc
###########################################
my $zinc_width=600;
my $zinc_height=500;
my $zinc = $mw->Zinc(-width => $zinc_width, -height => $zinc_height,
		     -font => "10x20",
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

# The explanation displayed when running this demo
$zinc->add('text', 1,
	   -position=> [10,10],
	   -text => 'This toy-appli shows some interactions on different parts
of a flight track item. The following operations are possible:
 - Drag Button 1 on the track to move it.
      Please Note the position history (past positions)
 - Enter/Leave flight label fields
 - Enter/Leave the speedvector, symbol (i.e. current position),
     label, or leader',
	   -font => "9x15",
	   );

###########################################
# Track
###########################################

#the label format (6 formats for 6 fields)#
my $labelformat = "x80x60+0+0 x60a0^0^0 x30a0^0>1 a0a0>2>1 x30a0>3>1 a0a0^0>2";

#the track#
my $x=250;
my $y=200;
my $track=$zinc->add('track', 1, 6, # 6 is the number of field in the flightlabel
		     -labelformat => $labelformat,
		     -position => [$x, $y],#position of the marker
		     -speedvector => [30, -15],#ccords of the speed vector
		     -markersize => 10,
		     );
# moving the track, to display past positions
foreach my $i (0..5) {  $zinc->coords($track,[$x+$i*10,$y-$i*5]); }

#fields of the label#
$zinc->itemconfigure($track, 0,#configuration of field 0 of the label
		     -filled => 0,
		     -bordercolor => 'DarkGreen',
		     -border => "contour",
		    );
$zinc->itemconfigure($track, 1,
		     -filled => 1,
		     -backcolor => 'gray60',
		     -text => "AFR6128");
$zinc->itemconfigure($track, 2,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "390");
$zinc->itemconfigure($track, 3,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "/");
$zinc->itemconfigure($track, 4,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "350");
$zinc->itemconfigure($track, 5,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "TUR");



###########################################
# Events on the track
###########################################
#---------------------------------------------
# Enter/Leave a field of the label of the track
#---------------------------------------------

foreach my $field (0..5) {
  #Entering the field $field higlights it#
  $zinc->bind("$track:$field", 
	      '<Enter>',
	      sub {
		if ($field==0){ 
		  higlight_label_on();
#		  print "CP=", $zinc->currentpart, "\n";
		}
		else{
		  highlight_fields_on($field);
#		  print "CP=", $zinc->currentpart, "\n";
		}
		
	      });
  #Leaving the field cancels the highlight of $field#
  $zinc->bind("$track:$field", 
	      '<Leave>',
	      sub {
		if($field==0){
		  higlight_label_off();
		}
		else{
		  if ($field==1){
		    highlight_field1_off();
		  }
		  else{
		    highlight_other_fields_off($field);
		  }
		}
	      });
}

#fonction#
sub higlight_label_on{
   $zinc->itemconfigure('current', 0,
			-filled => 0,
			-bordercolor => 'red',
			-border => "contour",
		    );
  
}
sub higlight_label_off{
   $zinc->itemconfigure('current', 0,
			-filled => 0,
			-bordercolor => 'DarkGreen',
			-border => "contour",
		    );
  
  
}

sub highlight_fields_on{
  my $field=$_[0];
  $zinc->itemconfigure('current', $field,
		       -border => 'contour',
		       -filled => 1,
		       -color => 'white'
		      );
  
}
sub highlight_field1_off{
    $zinc->itemconfigure('current', 1,
			 -border => '',
			 -filled => 1,
			 -color => 'black',
			 -backcolor => 'gray60'
			);
  
}

sub highlight_other_fields_off{
  my $field=$_[0];
  $zinc->itemconfigure('current', $field,
		       -border => '',
		       -filled => 0,
		       -color => 'black',
		       -backcolor => 'gray65'
		      );
}
#---------------------------------------------
# Enter/Leave other parts of the track
#---------------------------------------------
$zinc->bind("$track:position", 
	      '<Enter>',
	      sub {  $zinc->itemconfigure($track,
					  -symbolcolor=>"red",
					  );
#		  print "CP=", $zinc->currentpart, "\n";
		 });
$zinc->bind("$track:position", 
	      '<Leave>',
	      sub {  $zinc->itemconfigure($track,
					  -symbolcolor=>"black",
					  );
		 });

$zinc->bind("$track:speedvector", 
	      '<Enter>',
	      sub {  $zinc->itemconfigure($track,
					  -speedvectorcolor=>"red",
					  );
		 });
$zinc->bind("$track:speedvector", '<Leave>',
    sub {  $zinc->itemconfigure($track,
				-speedvectorcolor=>"black",
				);
       });

$zinc->bind("$track:leader", '<Enter>',
    sub {  $zinc->itemconfigure($track,
				-leadercolor=>"red",
				);
       });

$zinc->bind("$track:leader", '<Leave>',
    sub {  $zinc->itemconfigure($track,
				-leadercolor=>"black",
				);
       });

#---------------------------------------------
# Drag and drop the track
#---------------------------------------------
#Binding to ButtonPress event -> "move_on" state#
$zinc -> bind($track,'<ButtonPress-1>'=>[ sub { &select_color_on(); #change the color
						&move_on($_[1],$_[2]); #"move_on" state
					    }, Tk::Ev('x'),Tk::Ev('y') ]); 

#Binding to ButtonRelease event -> "move_off" state#
$zinc -> bind($track,'<ButtonRelease-1>'=>sub{&select_color_off(); #change the color
					      &move_off();}); #"move_off" state

#"move_on" state#
sub move_on{
    my ($xi,$yi)=@_;
    #Binding to Motion event -> move the track#
    $zinc -> bind($track,'<Motion>'=>
		  [sub{move($xi,$yi,$_[1],$_[2]); #move the track
		       $xi=$_[1];
		       $yi=$_[2];
		   },Tk::Ev('x'),Tk::Ev('y')]); 
}

#"move_off" state#
sub move_off{
    #Motion event not allowed on track
    $zinc -> bind($track,'<Motion>'=>""); 
}

#move the track#
sub move{
    my ($xi,$yi,$x,$y)=@_;
    select_color_on();
    my @coords=$zinc->coords($track);
    $zinc->coords($track,[$coords[0]+$x-$xi,$coords[1]+$y-$yi]);
}


sub select_color_on{
    $zinc->itemconfigure($track,
			 -speedvectorcolor=>"white",
			 -markercolor=>"white",
			 -leadercolor=>"white" );
}

sub select_color_off{
  $zinc->itemconfigure($track,
		       -speedvectorcolor=>"black",
		       -markercolor=>"black",
		       -leadercolor=>"black" );
}
 Tk::MainLoop;
