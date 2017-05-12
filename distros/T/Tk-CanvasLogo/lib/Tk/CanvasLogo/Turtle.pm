


package Tk::CanvasLogo::Turtle;


use 5.008005;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.1'; 

use Data::Dumper;
use Carp;
use Math::Trig;

sub _newTurtle {
	my ($inv, $canvas, $turtlename)=@_;

	# a bunch f different tags: 1 for turtle, 1 for just tail, 1 for all lines,
	# and 1 that gets assigned to everything related to turtle so we can delete it

	my $tag_prefix = 'TurtleTag_';
	my $global_tag = $tag_prefix . 'Global_' . $turtlename;
	my $turtle_tag = $tag_prefix . 'Turtle_' . $turtlename;
	my $line_tag   = $tag_prefix . 'Line_'   . $turtlename;
	
	my @tags = $canvas->gettags('all');
	#print Dumper \@tags;
	foreach my $existing_tag (@tags) {
		if($existing_tag eq $global_tag) {
			croak "Error: turtlename already used ('$turtlename')";
		}
	}
	
	my $obj= {
		canvas => $canvas, # the canvas on which the turtle is drawn
		global_tag => $global_tag,
		turtle_tag => $turtle_tag,
		line_tag => $line_tag,
		width => 12,
		height => 20,
		color => 'black',
		pen => 'down',
		turtle_visible => 1,
	};
	
	
	$obj = bless($obj, $inv);

	$obj->LOGO_HOME;

	return $obj;
}	


sub _draw_turtle {
	my ($turtle)=@_;

	my $canvas = $turtle->{canvas};

	$canvas->delete($turtle->{turtle_tag});	# delete old turtle if it existed

	if($turtle->{turtle_visible}) {		# if visible, redraw

		my $x=$turtle->{x};
		my $y=$turtle->{y};
		my $h=$turtle->{height};
		my $w=$turtle->{width}/2;

		my $bearing = $turtle->{bearing};

		$canvas->createPolygon(		# draw triangle of turtle
			$x, $y,
			_find_destination_of_forward_command($x,$y, $w, $bearing+90),
			_find_destination_of_forward_command($x,$y, $h, $bearing),
			_find_destination_of_forward_command($x,$y, $w, $bearing-90),
			$x, $y,
			-fill=>undef,
			-outline=> $turtle->{color},
			-tags => [$turtle->{global_tag},$turtle->{turtle_tag}],
		);
	
		if($turtle->{pen} eq 'down') {	# if pen down, draw tail.
			$canvas->createOval(
				_find_destination_of_forward_command($x,$y, $w/2, 360-45),
				_find_destination_of_forward_command($x,$y, $w/2, 180-45),
				-tags => [$turtle->{global_tag},$turtle->{turtle_tag}],
			);
		}
	}

	$canvas->idletasks();
}

# given start x,y, a distance to move forward, and a heading,
# calculate final coordinate
sub _find_destination_of_forward_command {
	my ($start_x, $start_y, $distance, $heading)=@_;
	my $radians = $heading * ( 3.1415927 / 180 ); 
	my $delta_y = cos($radians) * $distance;
	my $delta_x = sin($radians) * $distance;
	my $final_x = $start_x + $delta_x;
	my $final_y = $start_y + $delta_y;

	return ($final_x, $final_y);
}

##############################################
# logo methods
##############################################

# LOGO: forward
sub LOGO_FD {
	my ($turtle, $distance)=@_;
		
	my ($x1, $y1) = ($turtle->{x}, $turtle->{y});
	my ($x2, $y2) = _find_destination_of_forward_command(
		 $x1, $y1, $distance, $turtle->{bearing}
	);

	my $tag = $turtle->{tag};
	$tag .= '_Line';

	if($turtle->{pen} eq 'down') {
		$turtle->{canvas}->createLine($x1,$y1,$x2,$y2, 
			-fill=>$turtle->{color},
			-tags => [$turtle->{global_tag},$turtle->{line_tag}],
		);
	}

	$turtle->{x}=$x2;
	$turtle->{y}=$y2;

	$turtle->_draw_turtle;
}

# LOGO: backward
sub LOGO_BK {
	my ($turtle, $distance)=@_;
	$turtle->LOGO_FD(-1*$distance);
}

# LOGO: Right Turn
sub LOGO_RT {
	my ($turtle, $angle)=@_;
	$turtle->{bearing} -= $angle;
	$turtle->_draw_turtle;
}	

# LOGO: Left Turn
sub LOGO_LT {
	my ($turtle, $angle)=@_;
	$turtle->{bearing} += $angle;
	$turtle->_draw_turtle;
}	

# LOGO: Pen Up
sub LOGO_PU {
	my ($turtle)=@_;
	$turtle->{pen} = 'up';
	$turtle->_draw_turtle;	
}

# LOGO: Pen Down
sub LOGO_PD {
	my ($turtle)=@_;
	$turtle->{pen} = 'down';
	$turtle->_draw_turtle;	
}

# LOGO: Clear Screen, actually will only clear the turtle and any lines drawn by turtle
sub LOGO_CS {
	my ($turtle)=@_;
	$turtle->{canvas}->delete($turtle->{global_tag});
}

sub LOGO_HOME {
	my ($turtle)=@_;
	$turtle->{x}= $turtle->{canvas}->cget('-width')  /2;
	$turtle->{y}= $turtle->{canvas}->cget('-height') /2;
	$turtle->{bearing} = 180;
	$turtle->_draw_turtle;
}		



1;

