#!/usr/bin/perl 

# woodlice.pl v2.03

use strict;
use warnings;

if ( $ARGV[0] && $ARGV[0] =~ /^-{1,2}(h|help|\?)$/i )
{
	system ( "perldoc", $0 ) and die "For usage, use perldoc $0\n";
	exit( 0 );
}

use Tk qw( DONT_WAIT DoOneEvent );
use Tk::Taxis;
use Time::HiRes;

############################### global state ###################################

my $running           = 0;       # is the simulation running?
my $counter           = 0;       # seconds since simulation was started
my $paused            = 0;       # is the simulation paused?
my $dry               = 0;       # dry/damp mode on?
my $light             = 1;       # light/dark mode on?
my $supress_refresh   = 1;       # when we start up the we don't refresh
my $mode              = 'light'; # default mode

my %mode = 
(
	none                    =>
	{
		fill =>
		[
			[ '#7DDE4D', '#7DDE4D' ],
			[ '#7DDE4D', '#7DDE4D' ],
		],
		prefs => [ 1, 1 ],
	},	
	dry                     => 
	{
		fill =>
		[
			[ '#C1B24E', '#C1B24E' ],
			[ '#7695EF', '#7695EF' ],
		],
		prefs => [ 1, 7 ],
	},
	light                   => 
	{
		fill =>
		[
			[ 'white', 'gray' ],
			[ 'white', 'gray' ],
		],
		prefs => [ 1000, 1 ],
	},
	both                    =>
	{
		fill =>
		[
			[ '#F6D388', '#705824' ],
			[ '#B7C8DB', '#215187' ],
		],		
		prefs => [ 1000, 7 ],
	}
);

################################# defaults #####################################

my $population   = 20;
my $critters     = 'woodlice';
my $vert         = 500;
my $horiz        = 500;
my $speed        = 0.006;
my $refresh      = 20;         # milliseconds between refreshes

################################ gui settings ##################################

my $background   = 'gray';
my $foreground   = '#B65DE9';
my %menu_opt     =
(
	# settings for cascaded menu items
	-font        => 'sserife 8',
);
my %label_opt    = 
(
	# options for text labels
	-font        => 'sserif 14', 
	-width       => 12, 
	-borderwidth => 2, 
	-relief      => 'groove',
);
my %pad_opt      =
(
	# padding for generic pack and grid
	-padx        => 5, 
	-pady        => 5, 
);
my %wide_pad_opt      =
(
	# padding for wider label pack and grid
	-padx        => 15, 
	-pady        => 5, 
);
my %frame_opt    = 
(
	# settings for frames around widgets
	-relief      => 'groove', 
	-borderwidth => 2, 
	-background  => $background,
);

########################### command line options ###############################

use Getopt::Long;
GetOptions
(
	"foreground=s" => \$foreground,
	"background=s" => \$background,
	"vert=i"       => \$vert,
	"horiz=i"      => \$horiz,
	"image=s"      => \$critters,
	"refresh=i"    => \$refresh,
	"speed=f"      => \$speed,
);

$refresh /= 1000; # Time::HiRes need seconds, not milliseconds

################################## logging #####################################

use File::Temp 'tempfile';
use File::Spec;
my $logfile = tempfile
( 
	"woodliceXXXX",
	DIR    => File::Spec->tmpdir(), 
	SUFFIX => '.tmp', 
	UNLINK => 1, 
);
my $log_number = 1;

############################# keyboard bindings ################################

my $mw = new MainWindow( -title => "Woodlouse simulator (CASE 19)" );
$mw->Tk::bind( '<Alt-F4>'     => [ sub { Tk::exit 0 } ] );
$mw->Tk::bind( '<Control-F4>' => [ sub { Tk::exit 0 } ] );
$mw->Tk::bind( '<Control-s>'  => \&start_toggle );
$mw->Tk::bind( '<Control-p>'  => \&pause_toggle );
$mw->Tk::bind( '<F1>'         => \&help );
$mw->Tk::bind( '<Control-h>'  => \&help );
$mw->Tk::bind( '<Control-o>'  => \&options );
$mw->Tk::bind( '<Control-l>'  => \&save );
$mw->setPalette( $foreground );

################################### menu bar ###################################

	my $menu = $mw->Menu();
		my $file = $menu->cascade
		(
			-label     => 'File',
			-underline => 0,
			-tearoff   => 0,
		);
			$file->command
			(
				-label     => 'Save log file',
				-underline => 0,
				-command   => \&save,
				%menu_opt,
			);
			$file->command
			(
				-label     => 'Exit',
				-underline => 1,
				-command   => [ sub { Tk::exit(0) } ],
				%menu_opt,
			);
		my $simulate = $menu->cascade
		(
			-label     => 'Simulate',
			-underline => 0,
			-tearoff   => 0,
		);
			my $start_menu = $simulate->command
			(
				-label     => 'Start',
				-underline => 0,
				-command   => \&start_toggle,
				%menu_opt,
			);
			my $pause_menu = $simulate->command
			(
				-label     => 'Pause',
				-underline => 0,
				-command   => \&pause_toggle,
				-state     => 'disabled',
				%menu_opt,
			);
			my $option_menu = $simulate->command
			(
				-label     => 'Options',
				-underline => 0,
				-command   => \&options,
				%menu_opt,
			);
		my $help = $menu->cascade
		(
			-label     => 'Help',
			-underline => 0,
			-tearoff   => 0,
		);
			$help->command
			(
				-label     => 'Help',
				-underline => 0,
				-command   => \&help,
				%menu_opt,
			);
			$help->command
			(
				-label     => 'About',
				-underline => 0,
				-command   => \&about,
				%menu_opt,
			);
		$mw->configure( -menu => $menu );

################################## simulation ##################################
	
	my %counters;
	my $main = $mw->Frame( -background => $background )->pack();
		
		$counters{ top_left } = $main->Label
		( 
			%label_opt,
		)
		->grid
		(
			-column   => 0, 
			-row      => 0, 
			%wide_pad_opt,
		);
		
		my $taxis_frame = $main->Frame
		(
			%frame_opt,
		)
		->grid
		(
			-column    => 1,
			-row       => 0,
			-rowspan   => 2,
			%pad_opt,
		);
			my $taxis = $taxis_frame->Taxis
			( 
				-width      => $horiz,
				-height     => $vert,
				-preference => $mode{$mode}{prefs},
				-fill       => $mode{$mode}{fill},
				-population => $population,
				-images     => $critters,
				-speed      => $speed,
			)
			->pack();
		
		$counters{ top_right } = $main->Label
		( 
			%label_opt,
		)
		->grid
		(
			-column   => 2, 
			-row      => 0, 
			%wide_pad_opt,
		);

		$counters{ bottom_left } = $main->Label
		( 
			%label_opt,
		)
		->grid
		(
			-column   => 0, 
			-row      => 1, 
			%wide_pad_opt,
		);

		$counters{ bottom_right } = $main->Label
		( 
			%label_opt,
		)
		->grid
		(
			-column   => 2, 
			-row      => 1, 
			%wide_pad_opt,
		);
		
		my $frame = $main->Frame
		(
			%frame_opt,
		)
		->grid
		(
			-column   => 1, 
			-row      => 2, 
			%wide_pad_opt,
		);
			my $start_button = $frame->Button
			( 
				-text     => "Start",
				-command  => \&start_toggle,
				%label_opt,
			)
			->grid
			(
				-column   => 0, 
				-row      => 0,
				%wide_pad_opt,
			);
			$start_button->focus();
			my $pause_button = $frame->Button
			( 
				-text     => "Pause",
				-command  => \&pause_toggle,
				-state    => 'disabled',
				%label_opt,
			)
			->grid
			(
				-column   => 1, 
				-row      => 0, 
				%wide_pad_opt,
			);
			my $timer = $frame->Label
			( 
				-text        => "Time (s): 0",
				%label_opt,
			)
			->grid
			(
				-column   => 2, 
				-row      => 0, 
				-sticky   => 'ns',
				%wide_pad_opt, 
			);
	
################################## event loop ##################################

$mw->repeat
(
	1000,
	[ 
		sub 
		{ 
			if ( $running && not $paused )
			{
				my %c = $taxis->cget( -population );
				if ( $light && $dry )
				{
					print $logfile "$counter\t$c{top_left}\t$c{bottom_left}\t$c{top_right}\t$c{bottom_right}\n";
				}
				elsif ( $dry )
				{
					print $logfile "$counter\t$c{top}\t$c{bottom}\n"
				}
				elsif ( $light )
				{
					print $logfile "$counter\t$c{left}\t$c{right}\n"
				}
				else
				{
					print $logfile "$counter\t$c{top_left}\t$c{bottom_left}\t$c{top_right}\t$c{bottom_right}\n";
				}
				$counter++;
			}
		}
	] 
);

while( 1 )
{
	my $finish = $refresh + Time::HiRes::time;
	if ( $running && not $paused )
	{
		$taxis->taxis();
		$timer->configure( -text => sprintf "Time (s): %u", $counter );
	}
	my %c = $taxis->cget( -population );
	
	if ( $light && $dry )
	{
		$counters{top_left}->configure(     -text => "Light/Dry : $c{top_left}" );
		$counters{bottom_left}->configure(  -text => "Light/Damp : $c{bottom_left}" );
		$counters{top_right}->configure(    -text => "Dark/Dry : $c{top_right}" );
		$counters{bottom_right}->configure( -text => "Dark/Damp : $c{bottom_right}" );
	}
	elsif ( $dry )
	{
		$counters{top_left}->configure(     -text => "Dry : $c{top}" );
		$counters{bottom_left}->configure(  -text => "Damp : $c{bottom}" );
		$counters{top_right}->configure(    -text => "" );
		$counters{bottom_right}->configure( -text => "" );
	}
	elsif ( $light )
	{
		$counters{top_left}->configure(     -text => "Light : $c{left}" );
		$counters{bottom_left}->configure(  -text => "" );
		$counters{top_right}->configure(    -text => "Dark : $c{right}" );
		$counters{bottom_right}->configure( -text => "" );
	}
	else
	{
		$counters{top_left}->configure(     -text => "$c{top_left}" );
		$counters{bottom_left}->configure(  -text => "$c{bottom_left}" );
		$counters{top_right}->configure(    -text => "$c{top_right}" );
		$counters{bottom_right}->configure( -text => "$c{bottom_right}" );
	}

	while ( Time::HiRes::time < $finish  )
	{ 
		DoOneEvent( DONT_WAIT );
	}
}

################################### options ####################################

sub options
{
	return if $running;
	my %scale_opt =
	(
		-font       => 'sserif 14', 
		-orient     => 'horizontal',
		-background =>  $background,
		-length     => 300,
	);
	my $option_box = $mw->Toplevel
	(
		-background => $background,
		-title      => "Options",
	);
	
	my $population_frame = $option_box->Frame
	(
		%frame_opt,
	);
	my $population_scale = $population_frame->Scale
	(
		-label        => "Population",
		-from         => 0, 
		-to           => 50, 
		-tickinterval => 10,
		%scale_opt,
	)
	->pack();
	$population_scale->set( $population );
	$population_frame->grid
	(	
		-column       => 1, 
		-row          => 1, 
		-columnspan   => 2, 
		%pad_opt,
	);

	my $mode_frame = $option_box->Frame
	(
		%frame_opt,
	)
	->grid
	(	
		-column       => 1, 
		-row          => 2, 
		-columnspan   => 2, 
		%pad_opt,
	);	
	my $light_button  = $mode_frame->Checkbutton
	(
		-text         => "Light/Dark",
		-variable     => \$light,
		-selectcolor  => $background,
		%label_opt,
	)
	->grid
	(
		-column       => 1,
		-row          => 1,
		%pad_opt,		
	);
	my $dry_button    = $mode_frame->Checkbutton
	(
		-text         => "Dry/Damp",
		-variable     => \$dry,
		-selectcolor  => $background,
		%label_opt,
	)
	->grid
	(
		-column       => 2,
		-row          => 1,
		%pad_opt,
	);
	
	my $ok = $option_box->Button
	( 
		-text         => "OK", 
		-font         => "sserif 14",
		-command      => [
						sub
						{
							$population = $population_scale->get();
							$taxis->configure( -population => $population ); 
							if ( $light && $dry )
							{
								$taxis->configure( -fill => $mode{both}{fill} );
								$taxis->configure( -preference => $mode{both}{prefs} );
							}
							elsif ( $dry )
							{
								$taxis->configure( -fill => $mode{dry}{fill} );
								$taxis->configure( -preference => $mode{dry}{prefs} );
							}
							elsif ( $light )
							{
								$taxis->configure( -fill => $mode{light}{fill} );
								$taxis->configure( -preference => $mode{light}{prefs} );
							}
							else
							{
								$taxis->configure( -fill => $mode{none}{fill} );
								$taxis->configure( -preference => $mode{none}{prefs} );
							}							
							$option_box->destroy();
							$taxis->refresh();
							$supress_refresh = 1;
						}
					],
		-width        => 10,
	)->grid
	(
		-column       => 1,
		-row          => 3, 
		%pad_opt,
	);
	my $cancel = $option_box->Button
	( 
		-text         => "Cancel", 
		-font         => "sserif 14",
		-command      => [
						sub
						{
							$option_box->destroy();
						}
					],
		-width        => 10,
					
	)->grid(
		-column       => 2, 
		-row          => 3,
		%pad_opt,
	);
	$option_box->raise();
	$ok->focus();
	$option_box->Tk::bind( '<Alt-F4>' => [ sub { $option_box->destroy() } ] );
	$option_box->Tk::bind( '<Escape>' => [ sub { $option_box->destroy() } ] );
}

################################### toggles ####################################

sub start_toggle
{
	if ( $running )
	{
		$running = 0;
		$paused  = 0;
	}
	else
	{
		$counter = 0;
		$paused  = 0;
		$running = 1;
		if ( $supress_refresh )
		{
			$supress_refresh = 0;
		}
		else
		{
			$taxis->refresh();
		}
		new_log();
	}
	$start_button->configure
	(
		-text  => $running ? 'Stop' : 'Start',
	);
	$start_menu->configure
	(
		-label => $running ? 'Stop' : 'Start',
	);
	$pause_button->configure
	(
		-text  => 'Pause', 
		-state => $running ? 'normal' : 'disabled',
	);
	$pause_menu->configure
	(
		-label => 'Pause', 
		-state => $running ? 'normal' : 'disabled',
	);
	$option_menu->configure
	( 
		-state => $running ? 'disabled' : 'normal',
	);
}

sub pause_toggle
{
	$paused = $paused ? 0 : 1;
	$pause_button->configure
	(
		-text  => $paused ? 'Unpause' : 'Pause',
	);
	$pause_menu->configure
	(
		-label => $paused ? 'Unpause' : 'Pause',
	);	
}

#################################### popups ####################################

sub help
{
	my $help_text = << "THIS";
This software simulates the movement of organisms which work out where to go by 
measuring how dark it is where they are now, and comparing it to the darkness 
they experienced just a moment ago. If they find the conditions have got darker, 
they carry on running in the same direction, otherwise, they take a random 
tumble to a new direction. This makes them perform a biased random walk towards 
the dark. The author doesn't know whether woodlice do this, but they are more 
attractive than bacteria, which certainly do. To start a new simulation, press 
the 'Start' button. To pause it temporarily, press the 'Pause' button.\n
When the simulation is stopped, options can also be set using 'Options' on the 
'Simulate' menu. The population can be varied from 1 to 50 using the slider, 
and the critters' preference can be varied from 0 to +/-100.\n
The simulator can run damp vs. dry, dark vs. light, neither or both at the same
time. These options can be configured from the options menu.\n
A log is kept of the current option settings and the number of critters in the 
four quadrants, every second. This can be saved using 'Save log file' on 
'File' toolbar when the simulation is stopped.\n
Keyboard shortcuts:\n
\tF1\tHelp
\tCtrl-S\tStart/stop
\tCtrl-P\tPause/unpause
\tCtrl-O\tOptions (when stopped)
\tCtrl-L\tSave log file (when stopped)
\tAlt-F4\tExit\n
THIS
	my $help = $mw->Toplevel
	(
		-background   => $background,
		-title        => 'Help',
	);
	my $frame = $help->Frame
	(
		%frame_opt,
	)
	->grid
	(
		-column       => 1, 
		-row          => 1, 
		-columnspan   => 2, 
		%pad_opt,
	);
	my $text = $frame->Label
	(
		-font       => 'sserif 12',
		-text       => $help_text,
		-wraplength => 600,
		-justify    => 'left',
		-background => $background,
	)
	->grid
	(
		-column       => 1,
		-row          => 1, 
		%pad_opt, 
	);
	my $ok = $frame->Button
	( 
		-text         => "OK", 
		-font         => "sserif 14",
		-command      => [ sub { $help->destroy() } ],
		-width        => 10,
	)
	->grid
	(
		-column       => 1,
		-row          => 2, 
		%pad_opt, 
	);
    $help->Tk::bind( '<Alt-F4>' => [ sub { $help->destroy() } ] );
    $help->Tk::bind( '<Escape>' => [ sub { $help->destroy() } ] );
	$help->raise();
	$ok->focus();
}

sub dialog
{
	my ( $dialog_text, $title ) = @_;
	my $dialog = $mw->Toplevel
	(
		-title => $title || 'Dialog',
		-width => 1000,
	);
	my $frame = $dialog->Frame
	(
		%frame_opt,
	);
	$frame->grid
	(
		-column       => 1, 
		-row          => 1, 
		-columnspan   => 2, 
		%pad_opt,
	);
	my $text = $frame->Label
	(
		-width      => 50,
		-font       => 'sserif 12',
		-text       => $dialog_text,
		-wraplength => 400,
		-justify    => 'left',
		-background => $background,
	);
	$text->grid
	(
		-column       => 1,
		-row          => 1, 
		%pad_opt,
	);
	my $ok = $frame->Button
	( 
		-text         => "OK", 
		-font         => "sserif 14",
		-command      => [ sub { $dialog->destroy() } ],
		-width        => 10,
	);
	$ok->grid
	(
		-column       => 1,
		-row          => 2, 
		%pad_opt, 
	);
    $dialog->Tk::bind( '<Alt-F4>'    => [ sub { $dialog->destroy() } ] );
    $dialog->Tk::bind( '<Escape>'    => [ sub { $dialog->destroy() } ] );
	$dialog->raise();
	$ok->focus();
}

sub about
{
	my $about_text = << "THIS";
Woodlouse Simulator (CASE 19) v2.02 © Dr. Cook 2003\n
This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
THIS
	dialog( $about_text, "About" );
}

################################### logging ####################################

sub save
{	
	my $default = "woodlice$log_number";
	my $save_window = $mw->getSaveFile
	(
		-filetypes        => [ [ 'Log files' => '.log' ] ],
		-initialfile      => $default,
		-defaultextension => '.log',
	);
	if ( defined $save_window )
	{
		local *LOG;
		unless ( open LOG, ">", $save_window )
		{
			dialog( "Can't save log to file $save_window: $!", "Error" );
			return;
		}
		seek $logfile, 0, 0;
		print LOG $_ while <$logfile>;
		close LOG;
		$log_number++;
	}
}

sub new_log
{
	truncate $logfile, 0;
	seek     $logfile, 0, 0;
	print    $logfile <<"THIS";
Woodlouse simulator log file
Population\t$population
THIS
	if ( $light && $dry )
	{
		print $logfile "Time\tLight/Dry\tLight/Damp\tDark/Dry\tDark/Damp\n";
	}
	elsif ( $dry )
	{
		print $logfile "Time\tDry\tDamp\n";
	}
	elsif ( $light )
	{
		print $logfile "Time\tLight\tDark\n";
	}
	else
	{
		print $logfile "Time\tTop Left\tBottom Left\tTop Right\tBottom Right\n";
	}
}

__END__

=head1 NAME

woodlice.pl - Perl script for running woodlouse simulator

=head1 SYNOPSIS

  perl woodlice.pl 
    [--foreground blue]
    [--background gray]
    [--horiz 400] 
    [--vert 400] 
    [--image bacteria] 
    [--speed 0.006]
    [--refresh 50]

=head1 ABSTRACT

Woodlouse simulation script

=head1 DESCRIPTION

Invokes a woodlouse simulation demo using C<Tk::Taxis> and 
C<Tk::Taxis::Critter>. Press F1 whilst executing for help. The C<foreground> 
colour scheme of the simulator, the C<background> colouring, C<horiz>(ontal) 
and C<vert>(ical) size of the arena, the critter C<image>s used, and 
the C<speed> and minimum C<refresh> rate (milliseconds between refreshes) can be
configured from the command line with the appropriate switches.

The simulation allows you to run up to fifty woodlouse critters in a light/dark
choice chamber, print results to a log file, simulate woodlice's preference for
the dark, damp or both. It was designed (as was the whole distribution) to
teach school-children about the preference of woodlice for damp dark, without
having to collect two thousand woodlice from the school grounds. I hope some
biologists or teachers out there may also find it saves getting your hands dirty
rooting around under rocks.

=head1 SEE ALSO

L<Tk::Taxis>

L<Tk::Taxis::Critter>

=head1 AUTHOR

Steve Cook, E<lt>steve@steve.gb.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Steve Cook

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
