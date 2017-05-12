######################################## SOH ###########################################
## Function : Additional Tk Class for a Button with Text and image
##
## Copyright (c) 2004-2007 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V0.1	22-Jul-2004 	Class released. MK
## History  : V0.2	08-Mar-2007 	Added side-default from Optionbase. Thx to hkuhlmann. MK
##
######################################## EOH ###########################################
package Tk::Buttonplus;

##############################################
### Use
##############################################
use Tk;
use Tk::Button;
use Tk::Frame;

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '0.2';

use base qw (Tk::Frame);

########################################################################
Tk::Widget->Construct ('Buttonplus');

my ($buttonWindow, $relief);
#---------------------------------------------
sub ClassInit
{
	my ($class, $window) = (@_);

	$class->SUPER::ClassInit($window);
}

#---------------------------------------------
sub Populate
{
	my ($this, $args) = @_;

	my ($side, $image, $button);

	# Retrieve special option
	$side = delete $args->{-side} || $this->optionGet( 'side', 'Side' ) || 'right';


	# Walk through the BaseClass
	$this->SUPER::Populate ($args);


	# Widget Creation - Button 1
	if ($args->{-bitmap} || $args->{-image}) {
		$image = $this->Button( %$args,		
			-highlightthickness => '0',
			-relief => 'flat',
			-borderwidth => '0',
		)->pack(-side => $side, -fill => 'both');
		$this->Advertise( 'image' => $image );
		#
		# Setup proper bindings for the image button
 		$image->Tk::bind ('<Enter>' => sub { $this->Enter() } );
 		$image->Tk::bind ('<Leave>' => sub { $this->Leave() } );
		#
		$image->Tk::bind ('<ButtonPress-1>' => sub { $this->butDown() } );
		$image->Tk::bind ('<ButtonRelease-1>' => sub { $this->butUp() } );

		# Delete options that are not needed for the second button
		delete $args->{-bitmap}; delete $args->{-image};	
	}	
	# Widget Creation - Button 2
	$button = $this->Button(%$args,		
		-highlightthickness => '0',
		-relief => 'flat',
		-borderwidth => '0',
	)->pack(-fill => 'both');
	$this->Advertise( 'button' => $button );
	#
	# Setup proper bindings for the text button
	$button->Tk::bind ('<Enter>' => sub { $this->Enter() } );
	$button->Tk::bind ('<Leave>' => sub { $this->Leave() } );
	#
	$button->Tk::bind ('<ButtonPress-1>' => sub { $this->butDown() } );
	$button->Tk::bind ('<ButtonRelease-1>' => sub { $this->butUp() } );


	# Prepare the minimum necessary options
	$this->ConfigSpecs(
		-width			=> [['SELF', 'PASSIVE'], 'width', 'Width', 0],
    	-borderwidth	=> [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', 2],
    	-relief 		=> [['SELF', 'PASSIVE'], 'relief', 'Relief', 'raised'],
		-side           => [['SELF', 'PASSIVE'], 'side', 'Side', 'right'],
		-state			=> [['DESCENDANTS'], 'state', 'State', 'normal'],
		'DEFAULT'		=> [$button],
	);

	# Redirect all operations to the 'main' button
	$this->Delegates(
		'DEFAULT'		=> $button,
	);
}

#---------------------------------------------
# Enter --
# The procedure below is invoked when the
# mouse pointer enters a button widget. It
# changes the state of the button to active
# unless the button is disabled.
#
# Arguments:
# this -		The name of the widget.
#---------------------------------------------
sub Enter
{
	my $this = shift;

	if ($this->cget('-state') ne 'disabled') {
		$this->Subwidget('image')->configure('-state' => 'active') if $this->Subwidget('image');
		$this->Subwidget('button')->configure('-state' => 'active');
	}
}

#---------------------------------------------
# Leave --
# The procedure below is invoked when the
# mouse pointer leaves a button widget. It
# changes the state of the button back to
# inactive.
#
# Arguments:
# this -		The name of the widget.
#---------------------------------------------
sub Leave
{
	my $this = shift;

	if ($this->cget('-state') ne 'disabled') {
		$this->Subwidget('image')->configure('-state' => 'normal') if $this->Subwidget('image');
		$this->Subwidget('button')->configure('-state' => 'normal');
	}
}

#---------------------------------------------
# butDown --
# The procedure below is invoked when the
# mouse button is pressed in the button widget.
# It records the fact that the mouse is in the
# button, saves the button's relief so it can
# be restored later, and changes the relief
# to sunken.
#
# Arguments:
# this -		The name of the widget.
#---------------------------------------------
sub butDown
{
	my $this = shift;

	$relief = $this->cget('-relief');
	if ($this->cget('-state') ne 'disabled') {
		$buttonWindow = $this;
		$this->configure('-relief' => 'sunken')
	}
}

#---------------------------------------------
# butUp --
# The procedure below is invoked when the
# mouse button is released in a button widget.
# It restores the button's relief and invokes
# the command as long as the mouse hasn't left
# the button.
#
# Arguments:
# this -		The name of the widget.
#---------------------------------------------
sub butUp
{
	my $this = shift;

	if (defined($buttonWindow) && $buttonWindow == $this) {
		undef $buttonWindow;
		$this->configure('-relief' => $relief);
	}
}

########################################################################
1;
__END__


=head1 NAME

Tk::Buttonplus - Enhanced Button widget with a bitmap/image B<AND> a text label

=head1 SYNOPSIS

    use Tk;
    use Tk::Buttonplus

    my $mw = MainWindow->new();

    my $downangle_data = <<'downangle_EOP';
    /* XPM */
    static char *arrow[] = {
    "14 9 2 1",
    ". c none",
    "X c black",
    "..............",
    "..............",
    ".XXXXXXXXXXXX.",
    "..XXXXXXXXXX..",
    "...XXXXXXXX...",
    "....XXXXXX....",
    ".....XXXX.....",
    "......XX......",
    "..............",
    };
    downangle_EOP

    my $downangle = $mw->Pixmap( -data => $downangle_data);

    my $text = 'bttn-text';
    my $bt1 = $mw->Buttonplus(
        -text => 'Enable',
        #-image => $downangle,
        -bitmap => 'error',
        -command => \&bttn_pressed_cb1,
        #-borderwidth => '12',
        #-relief => 'ridge',
        #-bg => 'orange',
        #-fg => 'green',
        -textvariable => \$text,
        #-side => 'bottom',
        #-activeforeground => 'skyblue',
    )->pack(-padx => 50, -pady => 50);

    my $bt2 = $mw->Button(
	    -text => 'Disable',
	    -command => [\&bttn_pressed_cb2, $bt1],
	    #-image => $downangle,
    )->pack;

	
    Tk::MainLoop;
	
    sub bttn_pressed_cb1
    {
        print "bttn 1 pressed.\n";

    }
    sub bttn_pressed_cb2
    {
        print "bttn 2 pressed.\n";
        $_[0]->configure(-state => ($_[0]->cget('-state') eq 'normal' ? 'disabled' : 'normal'));
    }
	

=head1 DESCRIPTION

A Button widget that can be used as a replacement for the
standard Button, if you need to display a bitmap/image B<AND> a text label.

=head1 METHODS

for details on supported methods  - see B<Tk::Button>


=head1 OPTIONS

=over 4

=item B<-side>

-side => 'I<value>' allows to specify the side at which the bitmap/image is 
positioned. Value may be one of B<top>, B<left>, B<bottom> or B<right>.

for details on all other options  - see B<Tk::Button>

=back


=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V0.2  (C) 2004, - 2007

=cut

###
### EOF
###

