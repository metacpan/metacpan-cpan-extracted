######################################## SOH ###########################################
## Function : Wrapper for the Tk::SplashScreenZ based Boot-Splash procedures
##
## Copyright (c) 2003 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V0.1	05-Dec-2003 	Derived from Tavern. MK
##            V0.2	14-Jan-2004 	Added some documentation. MK
##
######################################## EOH ###########################################
package Tk::BootSplash;

require 5.005_62;
use Tk 800.023;

require Exporter;

our @ISA = qw(Exporter);

# Default-Exported Functions
our @EXPORT = qw(SetupBootSplash SetBootPhase
				WaitSplash UpdateSplash FinalizeSplash);

##############################################
### Use
##############################################
use strict;
use vars qw($VERSION);

$VERSION = '0.2';
#
use Carp;
# graphical stuff
#use Tk::widgets qw/Label Canvas ProgressBar/;
use Tk::widgets qw/Label Canvas/; # Note: We use here the enhanced Progressbar which is NOT yet part of std. Perl-Tk
use Tk::ProgressBarPlus;

BEGIN {
	eval {
		require Tk::SplashScreenZ;
		import Tk::SplashScreenZ;
	};
	if ($@) { # ups, no Tk::SplashScreenZ, use this one here
		########################################################################
		package Tk::SplashScreenZ;
		########################################################################
		$Tk::SplashScreenZ::VERSION = '1.0';
		use Tk qw/Ev/;
		use Tk qw/:eventtypes/;
		use Tk::waitVariableX;
		use Tk::widgets qw/Toplevel/;
		use base qw/Tk::Toplevel/;

		Construct Tk::Widget 'SplashScreenZ';

		sub Populate {
    		my ($self, $args) = @_;

    		$self->withdraw;
    		$self->overrideredirect(1);

    		$self->SUPER::Populate($args);

    		$self->{ofx} = 0;           # X offset from top-left corner to cursor
    		$self->{ofy} = 0;           # Y offset from top-left corner to cursor
    		$self->{tm0} = 0;           # microseconds time widget was Shown

    		$self->ConfigSpecs(
        		-milliseconds => [qw/PASSIVE milliseconds Milliseconds 0/],
    		);

    		$self->bind('<ButtonPress-3>'   => [$self => 'b3prs', Ev('x'), Ev('y')]);
    		$self->bind('<ButtonRelease-3>' => [$self => 'b3rls', Ev('X'), Ev('Y')]);

		} # end Populate

		# Object methods.

		sub Destroy {


    		my ($self, $millis) = @_;

    		$millis = $self->cget(-milliseconds) unless defined $millis;
    		my $t = Tk::timeofday;
    		$millis = $millis - ( ($t - $self->{tm0}) * 1000 );
    		$millis = 0 if $millis < 0;

    		my $destroy_splashscreen = sub {
			$self->update;
			$self->after(100);	# ensure 100% of PB seen
			$self->destroy;
    		};

    		do { &$destroy_splashscreen; return } if $millis == 0;

    		while ( $self->DoOneEvent (DONT_WAIT | TIMER_EVENTS)) {}

    		$self->waitVariableX( [$millis, $destroy_splashscreen] );

		} # end Destroy

		sub Splash {

    		my ($self, $millis) = @_;

    		$millis = $self->cget(-milliseconds) unless defined $millis;
    		$self->{tm0} = Tk::timeofday;
    		$self->configure(-milliseconds => $millis);
    		$self->Popup;

		} # end_splash

		# Private methods.

		sub b3prs {
    		my ($self, $x, $y) = @_;
    		$self->{ofx} = $x;
    		$self->{ofy} = $y;
		} # end b3prs

		sub b3rls {
    		my($self, $X, $Y) = @_;
    		$X -= $self->{ofx};
    		$Y -= $self->{ofy};
    		$self->geometry("+${X}+${Y}");
		} # end b3rls

		1;
	}
}
########################################################################

##############################################
# Local Variables
##############################################
my ($window, $parent, $canvas,
	$boot_percentage, $bootpercentage_border,
	$boot_cb_id, $bootpicture, $boot_phase, $update_ongoing);

########################################################################
# boot splash functions
########################################################################

# --------------------------------------------------------
# Creates and initializes a Boot-Splash screen.
# --------------------------------------------------------
sub SetupBootSplash
{
	my (%args) = @_;
	#my ($myparent, $app_name) = @_;
	
	# locals
	my (@valid_keys, %valid_keys, $arg);

	# Check Args
	@valid_keys = qw(-parent -width -height -application_name -size -totaltime -image -x1 -y1 -x2 -y2 -x3 -y3);
	%valid_keys = map {$_ => '1'} @valid_keys;
	foreach $arg (keys %args) {
		 croak "Undefined Key [$arg] (only [@valid_keys] are valid)!\n" unless $valid_keys{$arg};
	}
	croak "No Application Name for Bootsplash defined!\n" unless $args{-application_name};
	croak "No Image for Bootsplash defined!\n" unless $args{-image};
	$parent = delete $args{-parent}; croak "No Parent Window for Bootsplash defined!\n" unless $parent;
	
	$window = $parent->SplashScreenZ(
			-milliseconds => $args{-totaltime} || 5000,
	);
	$canvas = $window->Canvas(
			-width => $args{-width},
			-height => $args{-height},
	)->pack();
	
	# Reset the counter
	$bootpercentage_border = 0;
	
	# Fill it
	$canvas->createImage(0,0,
					-image => $args{-image},
					-anchor => 'nw',
	);
	#------------------------------------------------
	$canvas->createText($args{-x1}+2, $args{-y1}+2, 
					-font => 'Helvetica -16 bold',
					-text => 'Booting ...',
					-fill => 'black',
					-anchor => 'nw',
	);
	$canvas->createText($args{-x1}, $args{-y1}, 
					-font => 'Helvetica -16 bold',
					-text => 'Booting ...',
					-fill => 'white',
					-anchor => 'nw',
	);
	#------------------------------------------------
	$canvas->createText($args{-x2}+2, $args{-y2}+2, 
					-font => 'Helvetica -' . $args{-size} . ' bold',
					-text => $args{-application_name},
					-fill => 'black',
					-stipple => (lc($Tk::platform) eq 'mswin32') ? undef : 'gray50',
					-anchor => 'center',
	);
	$canvas->createText($args{-x2}, $args{-y2}, 
					-font => 'Helvetica -' . $args{-size} . ' bold',
					-text => $args{-application_name},
					-fill => 'white',
					-stipple => (lc($Tk::platform) eq 'mswin32') ? undef : 'gray50',
					-anchor => 'center',
	);
	#------------------------------------------------
	$canvas->createText($args{-x3}+2, $args{-y3}+2, 
					-font => 'Helvetica -12 bold',
					-text => 'Bootphase:',
					-fill => 'black',
					-anchor => 'nw',
					-tags => 'bootphase1',
	);
	$canvas->createText($args{-x3}, $args{-y3}, 
					-font => 'Helvetica -12 bold',
					-text => 'Bootphase:',
					-fill => 'white',
					-anchor => 'nw',
					-tags => 'bootphase2',
	);
	#------------------------------------------------
	my $progressbar = $canvas->ProgressBarPlus(
					-borderwidth => '2',
					-relief => 'groove',
					-from => '0',
					-to => '100',
					-blocks => '100',
					-colors => [0, 'blue' ],
					-variable => \$boot_percentage,
					-showvalue => '1',
					#-valuecolor => 'yellow',
	);
	
	$canvas->createWindow(0, $args{-height}-16,
					-window => $progressbar,
					-anchor => 'nw',
					-width => $args{-width},
					-tags => 'progressbar',
	);
	
	# display the Splash, if we want to have it
	if ($boot_percentage < 100 ) {
		$bootpercentage_border = $boot_percentage = 0;
		#setup the counter-callback
		$boot_cb_id = $parent-> repeat(10, \&boot_cb);
		$window->update;
		$window->Splash;
	}
	return $bootpicture;
}

# --------------------------------------------------------
# Sets the current Bootphase and the
# belonging border in percent (0..100).
# --------------------------------------------------------
sub SetBootPhase
{
	my ($new_bootphase, $new_border) = @_;
	$boot_phase = $new_bootphase;
	$bootpercentage_border = $new_border;
	$bootpercentage_border = 100 if $bootpercentage_border > 100;
}

# --------------------------------------------------------
# Helper Function for the Boot-Splash-Screen Progress
# display. It will delay the execution for faster
# setup operations.
# --------------------------------------------------------
sub WaitSplash
{
	return unless $window;
	while ($boot_percentage <= $bootpercentage_border) {
		$window->update;
		$window->after(20);
	}
}

# --------------------------------------------------------
# Helper Function for the Boot-Splash-Screen Progress
# display. It will show current stage on screen.
# --------------------------------------------------------
sub UpdateSplash
{
	$window->update;
}

# --------------------------------------------------------
# Helper Function for the Boot-Splash-Screen finalization.
# --------------------------------------------------------
sub FinalizeSplash
{
	#Finalize the Splash, if we had one
	$window->update;
	if (defined $boot_cb_id ) {
		$parent->after(900);
		$window->Destroy;
		$boot_cb_id->cancel;
	}
	else {
		$parent->after(900);
		$parent->update;
	}

	# Wait for the Splash to finish
	SetBootPhase('Setup complete ...', 100);
}

# --------------------------------------------------------
# INTERNAL FUNCTION:
# Callback for updating the graphics of the
# Boot-Splash-Screen's progress display.
# --------------------------------------------------------
sub boot_cb
{
	if ($boot_percentage <= $bootpercentage_border) {
			$boot_percentage++;
	}
	if ($canvas) {
		$canvas->dchars('bootphase1', 0, 'end');
		$canvas->insert('bootphase1', 0, $boot_phase); 
		$canvas->dchars('bootphase2', 0, 'end');
		$canvas->insert('bootphase2', 0, $boot_phase); 
	}
	return if $update_ongoing;
	$update_ongoing = 1;
	$window->update;
	$update_ongoing = undef;
}
########################################################################
1;
__END__


=head1 NAME

Tk::BootSplash - wrapper for the common Tk::SplashScreen

=head1 SYNOPSIS

    use Tk;
    use Tk::BootSplash;


    $bootpicture = $main->Pixmap(-file => "xxx.xpm"); 
    SetupBootSplash(
       -totaltime => '5000', # time is msecs
       -parent => $main,
       -application_name => $app_name,
       -size => '60',
       -image => $bootpicture,
       -width => '208',
       -height => '120',
       -x1 => '10', -y1 => '4',  # Line 1 Txt 'Booting'
       -x2 => '4',  -y2 => '10', # Application Name in HUGE Letters
       -x3 => '20', -y3 => '87', # Line 3 TxtCurrent bootphase
    );
	

=head1 DESCRIPTION

This module is a fully customizable wrapper for the common Tk:SplashScreen, which can
be used to ease handling of a standardized boot splash screen with picture,
texts and a progress bar. (see I<Tk::SplashScreen> for details).

NOTE: This module is less a gimmick than a feature, since we
need to wait some time until all the Windows and/or Widgets
are layed out in their final positions/sizes. If we won't
wait we'd run the risk of having them messed up on the same position.

The TOTALTIME is the maximum time the Splash is shown.


=head1 METHODS

=over 4

=item B<SetupBootSplash()>

'SetupBootSplash()' allows to intialize / configure the upcoming Splashsceen.
See I<Options> for a detailed description of the parameters understood.

=item B<SetBootPhase()>

SetBootPhase() Sets a new Bootphase Text and the
belonging border in percent (0..100). Ex.: You can specify 20 (%) as the new border
for the next call to WaitSplash().

=item B<WaitSplash()>

WaitSplash() will delay the execution for faster (external) setup operations.
It will either keep waiting until the current applied border is reached
(and concurrently increase the progress-bar by 1%) or just do nothing. 

=item B<UpdateSplash()>

UpdateSplash() will promote any new bootphase and or current percentage
using B<SetBootPhase()> on screen. It may be used for spreading in any
external custom-initialization code to keep the Splash-texts up-to-date.

=item B<FinalizeSplash()>

FinalizeSplash() is a helper function for the Boot-Splash-Screen finalization.
It will necessary wait until the TOTALTIME is reached and safely shutdown
the Splash afterwards.

=back


=head1 OPTIONS

=over 4

=item B<-parent>

'-parent' allows to specify a reference to a valid parent window.
In almost every case this will be the toplevel reference,
received by MainWindow::->new().

=item B<-application_name>

'-application_name' can be used to supply the Name of the application.
It will be displayed in a dithred font across the BootImage.
Note: Currently the B<size> has to be adapted manually to the imagesize
with the B<-size> option.

=item B<-image>

'-image' must be used to supply a reference to a valid pixmap, such as
generated with $main->Pixmap( -file => "xxx.xpm") .

=item B<-width>

'-width' current width of the SplashScreen, should match to used image-size.

=item B<-height>

'-height' current height of the SplashScreen, should match to used image-size.

=item B<-x1>, B<-y1>

'-x1, -y1' must be used to define the x/y Position of the Line1 Text('Booting...').

=item B<-x2>, B<-y2>

'-x2, -y2' must be used to define the x/y Position of the Line2 Text(ApplicationName).

=item B<-x3>, B<-y3>

'-x3, -y3' must be used to define the x/y Position of the Line3 Text(Current BootPhase).

=back

=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V1.0  (C) December 2003

=cut

###
### EOF
###
