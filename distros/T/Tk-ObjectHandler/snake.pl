#!/usr/bin/perl
########################################################################
#                                                                      #
#                    Snakes, by Simon Parsons                          #
#                                                                      #
# This example program is distributed under the terms of the GNU       #
# Public Licence and the Perl Artistic Licence.                        #
#                                                                      #
# Copyright Simon Parsons, 2002                                        #
########################################################################

use Tk::ObjectHandler;
use strict;

my $game = {
	play => 0,
	pause => 0,
	delay => 700,
	last => 'j',
	next => undef,
};
my $score = 0;
my $message = '';
my @keypresses = ();

my @stage;
my @snake = ();

my $snakedata = {
	up => -1,
	left => 0,
	growing => 0,
	shrinking => 0,
};
my $length = 0,

my $apple = {
	'ready' => 0,
	'count' => 5,
	'eaten' => 0,
	'type' => 0,
};
my @apple_colours = ('#FFFFFF','#339933', '#990033', '#999900');
my $mw;

sub about_window {
	my $widget = shift;

	$message = 'Snakes by Simon Parsons. Made with 
				Tk::ObjectHandler.';
}

sub init_game {

	# Set default snake starting position
	my $snake_head = {x=>25, y=>17};
	my $snake_tail = {x=>25, y=>18};
	$stage[$snake_head->{'x'}][$snake_head->{'y'}] = 1;
	$stage[$snake_tail->{'x'}][$snake_tail->{'y'}] = 1;

	# Init variables
	$game = {
		play => 1,
		message => '',
		pause => 0,
		delay => 500,
		last => 'z',
		next => undef,
	};
	$score = 0;
	
	$snakedata = {
		up => -1,
		left => 0,
		growing => 0,
		shrinking => 0,
		length => 0,
	};
	$length=2;
	
	$apple = {
		'ready' => 0,
		'count' => 5,
		'eaten' => 0,
		'type' => 0,
	};


	@snake = ();
	$snake[0] = $snake_head;
	$snake[1] = $snake_tail;

	# Clear area
	$mw->field->createRectangle(0, 0, $mw->field->cget(-width), 
			$mw->field->cget(-height), 
			-outline => $mw->field->cget(-background), 
			-fill => $mw->field->cget(-background));

	draw_snake(\@snake);

	# Set up keyboard commands

	#$mw->bind('<Key-Left>', sub{ push @keypresses, 'z'});
	#$mw->bind('<Key-Left>', sub{ push @keypresses, 'a'});
	#$mw->bind('<Key-Right>', sub{ push @keypresses, 'm'});
	#$mw->bind('<Key-Left>', sub{ push @keypresses, 'n'});
	$mw->bind('<Key-Down>', sub{ turn1(-1, 'z', 0, 1, 'a');});
	$mw->bind('<Key-Up>', sub{ turn1(1, 'a', 0, -1, 'z');});
	$mw->bind('<Key-Right>', sub{ turn2(-1, 'm', 1, 0, 'n');});
	$mw->bind('<Key-Left>', sub{ turn2(1, 'n', -1, 0, 'm');});
	$mw->bind('<p>', sub{ pause(); });
	$mw->bind('<P>', sub{ pause(); });
	$mw->after($game->{'delay'}, sub{ move() });
}

sub pause {	
	if($game->{'pause'}==0) {
		$game->{'pause'}=1;
	} else { 
		$game->{'pause'}=0; 
		move(); 
	}
}

sub turn {
	if("az" =~ /$_[0]/i) {
		turn1(turnargs($_[0]));
	} else {
		turn2(turnargs($_[0]));
	}
}

sub turnargs {
	my $dir = shift;
	if(lc($dir) eq 'a') {
		return [1, 'a', 0, -1, 'z']; 
	} elsif(lc($dir) eq 'z') {
		return [-1, 'z', 0, 1, 'a']; 
	} elsif(lc($dir) eq 'n') {
		return [1, 'n', -1, 0, 'm']; 
	} else {
		return [-1, 'm', 1, 0, 'n']; 
	}
}

sub turn1 {
	return if($game->{'last'} eq $_[1]);
	if($snakedata->{'up'} != $_[0] or $game->{'last'} ne $_[1]) {
		$snakedata->{'left'} = $_[2];
		$snakedata->{'up'} = $_[3];
		$game->{'next'} = $_[4];
	}
}

sub turn2 {
	return if($game->{'last'} eq $_[1]);
	if($snakedata->{'left'} != $_[0] or $game->{'last'} ne $_[1]) {
		$snakedata->{'left'} = $_[2];
		$snakedata->{'up'} = $_[3];
		$game->{'next'} = $_[4];
	}
}

sub draw_snake {
	my $snake = shift;

	foreach my $coord (@$snake) {
		draw('#000000', $coord);
	}
}

sub draw {
	my $colour = shift;
	my $x = $_[0]->{'x'} * 10;
	my $y = $_[0]->{'y'} * 10;
	$mw->field->createRectangle($x, $y, $x+9, $
		y+9, -outline => $colour, -fill => $colour);
}

sub move {
	return if($game->{'pause'});
	my $turn;

	# Normal movement
	proc_head($snake[0]->{'y'} + $snakedata->{'up'}, 
		$snake[0]->{'x'} + $snakedata->{'left'});

	# Growth movement
	if($snakedata->{'growing'}) {
		$snakedata->{'growing'}--;
		$message = '' if($snakedata->{'growing'} == 1);
	} else {
		proc_tail(pop @snake);
	}

	# Shrinking movement
	if($snakedata->{'shrinking'}) {
		$snakedata->{'shrinking'}--;
		proc_tail(pop @snake);
	}

	$length = $#snake + 1;
	$score++;

	# Draw Apple
	if(--$apple->{'count'} <= 0) {
		if($apple->{'ready'} == 0) {
			$apple->{'x'} = get_rand(49);
			$apple->{'y'} = get_rand(34);
			until(check_snake($apple->{'x'}, 
						$apple->{'y'})) {
				$apple->{'x'} = get_rand(49);
				$apple->{'y'} = get_rand(34);
			}

			$apple->{'type'} = (get_rand(100) <= 80 ? 1 : 
					(get_rand(100) <= 50 ? 2 : 3));

			draw($apple_colours[$apple->{'type'}], $apple);
		} else {
			draw('#FFFFFF', $apple);
		}
		$apple->{'ready'} = not $apple->{'ready'};
		$apple->{'count'} = ($apple->{'ready'} == 1 ? 
					get_rand(100)+50 : get_rand(5));
	}	

	if($game->{'play'} == -1) {
		$message = 'Ouch!!';
		$game->{'play'} = 0;
	}

	if($game->{'next'}) { $game->{'last'} = 
			$game->{'next'}; $game->{'next'} = undef; }

	$mw->after($game->{'delay'}, sub{ move() }) if $game->{'play'};
}

sub proc_tail {
	my $new_tail = shift;
	if($new_tail) {
		draw('#FFFFFF', $new_tail);
		$stage[$new_tail->{'x'}][$new_tail->{'y'}] = 0;
	}
}

sub proc_head {
	my $new_head = {
		'y' => shift,
		'x' => shift,
	};

	if(($new_head->{'x'} < 0 or $new_head->{'y'} < 0) or
		($new_head->{'x'} > 49 or $new_head->{'y'} > 34)) { 
		$game->{'play'} = -1;
	}

	# if a snake is there...
	if($stage[$new_head->{'x'}][$new_head->{'y'}] == 1) { 
		$game->{'play'} = -1;
	}
	$stage[$new_head->{'x'}][$new_head->{'y'}] = 1;

	if(($apple->{'ready'} == 1) and 
		($new_head->{'x'} == $apple->{'x'}) and 
		($new_head->{'y'} == $apple->{'y'})) {

		$apple->{'ready'} = 0;
		$apple->{'count'} = get_rand(10);
		$apple->{'eaten'}++;
		$message = 'Crunch!!';

		if($apple->{'type'} == 1) {
			$score += 100;
			$game->{'delay'} = sprintf "%d", ( $game->{'delay'} * 0.9);
			$snakedata->{'growing'} += 3+$apple->{'eaten'};
			$snakedata->{'shrinking'} = 0;
		} elsif($apple->{'type'} == 2) {
			$score += 500;
			$game->{'delay'} = sprintf "%d", ( $game->{'delay'} * 0.9);
			$snakedata->{'growing'} = 0;
			$snakedata->{'shrinking'} +=3+$apple->{'eaten'};
			if(($length - $snakedata->{'shrinking'}) < 2 ) {
				$snakedata->{'shrinking'} = $length-2;
			}
		} else {
			$score += 500;
			$game->{'delay'} += 100;
		}

	}


	unshift @snake, $new_head;
	draw('#000000', $new_head);
}

sub get_rand {
	my $max = shift;

	my $var = (rand() * ($max * 10) % $max) + 1;
	my $off = $var % 1;
	return $var - $off;
}

sub check_snake {
	my($x, $y) = @_;
	return 0 if($stage[$x][$y] == 1);
	return 1;
}

sub report {
	$mw->add_widget('Toplevel', 'reportwin', -title => 
			'ObjectHandler Report');
	$mw->reportwin->add_widget('Label', 'title', -text => 
			'Tk::ObjectHandler Report For This Game')->pack(
			-expand => 0, -fill =>'both');
	$mw->reportwin->add_widget('Label', 'text', -background => 
			'#FFFFFF',  -justify => 'left', -text => 
			$mw->report, -font => 'Courier')->pack( 
			-expand => 0, -fill =>'both');
	$mw->reportwin->add_widget('Button', 'close', -text => 'Close', 
			-command => sub { $mw->reportwin->destroy(); }
			)->pack();

}

sub help {
	$mw->add_widget('Toplevel', 'helpwin', -title => 'Snake Help');
	$mw->helpwin->add_widget('Label', 'la', -font => 'Courier', 
			-justify => 'left', => -text => <<"HELPTEXT"
The object of the game is to move your little snake the black blobs
around the white area collecting 'apples' (the green, red and yellow
blobs) without hitting the edge of the arena or your snake's body.
Each colour apple has a different affect, described below. The
keys are:
			UP
			a
			^
			|
	LEFT	n <-        -> m    RIGHT
			|
			v
			z
		       DOWN

Green apples will cause your snake to grow and make it move faster.
Red apples will cause your snake to shrink and make it move faster.
Yellow apples will cause your snake to move slower.
HELPTEXT
)->pack(-expand => 0, -fill=> 'both');


	$mw->helpwin->add_widget('Button', 'close', -text => 'Close', 
		-command => sub { $mw->helpwin->destroy(); })->pack();
}



# Populate stage with blanks
for(my $x=0; $x<51; $x++){ 
	for(my $y=0; $y<36; $y++) { 
		$stage[$x][$y] = 0; }}

# Build the main window
$mw = Tk::ObjectHandler->new();
$mw->comment('Controlling widget');

$mw->add_widget('Frame', 'menu', -relief => 'groove', 
			-borderwidth => '1');
$mw->menu->comment('Menubar Frame.');

$mw->add_widget('Frame', 'score');
$mw->menu->comment('This frame holds score and snake length, etc.');

$mw->add_widget('Canvas', 'field', -width => 500, -height => 350, 
			-background => '#FFFFFF');
$mw->field->comment('The main playing area.');

$mw->add_widget('Frame', 'message', -relief => 'sunken',
			-borderwidth => '1');
$mw->message->comment('This frame is used to hold messages to the player');

# Menu Entries
$mw->menu->add_widget('Menubutton', 'game', -text => 'Game', 
-menuitems => [
	['command' => "Play   F1", -command =>sub{ init_game(); } ],
	'-', 
	['command' => "Quit   F10", -command =>sub{ $mw->destroy(); }]
])->pack(-side => 'left');
$mw->menu->game->comment('Holds game play commands');

$mw->menu->add_widget('Menubutton', 'rep', -text => 'Report', 
-menuitems => [
	['command' => 'Report', -command => sub{ report(); } ]
])->pack(-side => 'left');
$mw->menu->rep->comment('Prints a sample Tk::ObjectHandler report in a new window');

$mw->menu->add_widget('Menubutton', 'help', -text => 'Help', 
-menuitems => [
	[ 'command' => 'About', -command => sub{ about_window($mw) } ],
	[ 'command' => 'How To Play', -command => sub{ help() } ]
])->pack(-side => 'right');
$mw->menu->rep->comment('Displays help and copyright info.');

# Score entries
$mw->score->add_widget('Label', 'l1', -text => 'Score: ', 
	-justify => 'right')->pack(-fill => 'both', -side => 'left', 
	-expand => 0);
$mw->score->add_widget('Label', 'score', -textvariable => \$score
	)->pack(-fill => 'both', -side => 'left', -expand => 0);
$mw->score->add_widget('Label', 'l3', -text => 'Snake Length: ', 
	-justify => 'right')->pack(-fill => 'both', -side => 'left', 
	-expand => 0);
$mw->score->add_widget('Label', 'snake_length', 
	-textvariable => \$length)->pack(-fill => 'both', 
	-side => 'left', -expand => 0);
$mw->message->add_widget('Label', 'messages', 
	-textvariable => \$message)->pack(-side => 'left', 
	-fill => 'both', -expand => 0);

$mw->menu->pack( -side => 'top', -expand => 0, -fill => 'both');
$mw->score->pack( -side => 'top', -expand => 0, -fill => 'both');
$mw->field->pack( -side => 'top', -expand => 0, -fill => 'none');
$mw->message->pack( -side => 'top', -expand => 0, -fill => 'both');

$mw->bind('<F1>', sub{ init_game() if($game->{'play'} == 0);});
$mw->bind('<F10>', sub{ $mw->destroy(); });

$mw->MainLoop;
