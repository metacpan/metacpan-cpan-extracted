######################################## SOH ###########################################
## Function : Additional Tk Class for a (colored) status display
##
## Copyright (c) 2002 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V1.0	01-Oct-2002 	Class released. MK
##            V1.01 05-Dec-2002 	Bugfix/Enhancement for Set-Reset '-variable'
##
######################################## EOH ###########################################
package Tk::Statusbox;

##############################################
### Use
##############################################
use Tk;
use Tk::Button;
use Tk::Frame;

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '1.00';

use base qw (Tk::Derived Tk::Frame);

########################################################################
Tk::Widget->Construct ('Statusbox');

#---------------------------------------------
sub ClassInit {
	my ($class, $window) = (@_);

	$class->SUPER::ClassInit($window);
}

#---------------------------------------------
sub Populate {
	my ($this, $args) = @_;

	# Retrieve standard background
	if (defined ($args->{-bg})) {
		$args->{-background} = $args->{-bg};
	}
	my $common_background = (defined($args->{-background})) ? 
										$args->{-background} :
										$this->cget ('-background');
										
	# Create a Closure for saving the current value,
	# if there is no variable spec'd
	unless (defined $args->{-variable}) {
		my $gen = $common_background;
		my $var = \$gen;
		$args->{-variable} = $var;
	}

	$this->SUPER::Populate ($args);
	

	#Widget Creation
	my $canvas = $this->Canvas(
		-highlightthickness => '0',
		-relief => 'flat',
		-borderwidth => '0',
	)->pack(
    	-fill => 'both',
    	-expand => '1',
		-anchor => 'center',
	);

	$this->Advertise( 'canvas' => $canvas );
	$this->ConfigSpecs(
    	-background				=> [['DESCENDANTS'], 'background', 'Background', 'white'],
    	-foreground				=> [['SELF', 'PASSIVE'], 'foreground', 'Foreground', 'black'],
    	-activebackground		=> [['SELF', 'DESCENDANTS', 'PASSIVE'], 'activebackground', 'ActiveBackground', '#ececec'],
    	-disabledforeground 	=> [['SELF', 'DESCENDANTS', 'PASSIVE'], 'disabledForeground', 'DisabledForeground', '#a3a3a3'],
    	-disabledbackground 	=> [['SELF', 'DESCENDANTS', 'PASSIVE'], 'disabledBackground', 'DisabledBackground', '#AE00B200C300'],
    	-borderwidth			=> [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', 2],
    	-color					=> [['SELF', 'PASSIVE'], 'color', 'Color', 'red'],
    	-relief					=> [['SELF', 'PASSIVE'], 'relief', 'Relief', 'groove'],
    	-height					=> ['DESCENDANTS', 'height', 'Height', 15],
    	-width					=> ['DESCENDANTS', 'width', 'Width', 15],
    	-flashintervall			=> [['SELF', 'PASSIVE'], 'flashintervall', 'FlashIntervall', 500],
    	-command 				=> ['CALLBACK',undef,undef, undef],
    	-variable 				=> ['METHOD', 'variable', 'Variable', undef],
	);
	# Preset the internal Saver
	$this->{m_Normalbackground} = $common_background;
}

#---------------------------------------------
# Ties the scalar variable to the widget
#---------------------------------------------
sub variable {
    use Tie::Watch;
	# Parameters
    my ($this, $vref) = @_;
	#
	#print "Reached Statusbox::variable. with >@_<, caller",  caller ," args\n";
	#print "this = $this, vref = >", (defined $vref) ? "$vref" : "undef" ,"<\n";

    my $st = [sub {  my ($watch, $new_val) = @_;
					 my $argv= $watch->Args('-store');
					 $argv->[0]->color($new_val);
					 $watch->Store($new_val);
				  }, $this];

	if (defined $vref) {
		#assign a new one
		$this->{watch} = Tie::Watch->new(-variable => $vref, -store => $st);
		$this->{watch_variable} = $vref;
		# Remove the Watchpoint after it's no more needed
    	$this->OnDestroy( sub { $this->{watch}->Unwatch if $this->{watch} } );

		# Preset will the current var-value
		$this->color($$vref);
	}
	elsif ( (scalar @_ ) > 1 ) {
		$this->{watch}->Unwatch if $this->{watch};
	}
	
	# Return sth useful for -cget questionares
	return $this->{watch_variable};
} # end variable



#---------------------------------------------
# Set Value by Variable or by -color Parm
#---------------------------------------------
sub color {
	# Parameters
    my ($this, $newvalue) = @_;
#print "color: >@_<, caller = ", caller, "\n";
	return unless defined $newvalue;
	my ($canvas) = $this->Subwidget('canvas');
	#
	my $fetch = $this->{watch}->Fetch() || '-';
	if ($newvalue ne $fetch) {
		$this->{watch}->Store($newvalue);
	}
	#Prepare the button background
	$canvas->configure (-background => $newvalue );
	# invoke callback
	my @args = ( $newvalue );
	$this->Callback(-command => @args);
}


#---------------------------------------------
# Clear Value, 
#---------------------------------------------
sub clear {
    my $this = shift;
	
	$this->color($this->{m_Normalbackground});
}

#---------------------------------------------
# Set Value by Variable or by -color Parm
#---------------------------------------------
sub flash
{
	# Parameters
    my ($this, $startstop) = @_;
	
	# Locals
	if ($startstop =~ /start/i) {
		my ($canvas, $bgcolor, $fgcolor, $flashintervall);
		$canvas = $this->Subwidget('canvas');
		#
		$bgcolor = $this->{m_Normalbackground};
		$fgcolor = $this->{watch}->Fetch;
		$flashintervall = $this->cget ('-flashintervall');
		$this->{flash} = 'true';
		$this->flash_widget($canvas, '-background', $fgcolor, $bgcolor, $flashintervall);
	}
	else {
		$this->{flash} = 'false';
	}

}
sub flash_widget {  
    # Flash a widget attribute periodically.  
    my ($this, $w, $opt, $val1, $val2, $interval) = @_; 
	my $mw = $w->toplevel;
	
    $w->configure($opt => $val1);
	if ($this->{flash} eq 'true') {
		$mw->after($interval, [\&flash_widget, $this, $w, $opt,
				$val2, $val1, $interval]);
	}
	else {
		$this->clear();
	}
}  

########################################################################
1;
__END__


=head1 NAME

Tk::Statusbox - A recolorable status area (box) that also can flash

=head1 SYNOPSIS

    use Tk;
    use Tk::Statusbox

    my $mycolor = 'red';
    my $mw = MainWindow->new();


    my $stbox = $mw->Statusbox(
        -variable       => \$mycolor,
        -command        => \&status_changed_cb,
        -flashintervall => '100',  # time in msecs
        -height         => '30',
        -width          => '50',
        #-relief        => 'sunken',
        #-bg            => 'blue',	
    )->pack;

	
    Tk::MainLoop;
	
    sub test_cb
    {
        print "status_changed_cb called with [@_], \$mycolor = >$mycolor<\n";
        #$stbox->color('red');
        $mycolor = 'orange';
    }
	

=head1 DESCRIPTION

A cavas/frame style widget that uses a recolorable indicator box with
configurable flashing. Useful as an indicator field for common status
operations, suitable for perl Tk800.x (developed with Tk800.024).

You can tie a scalar-value to the Statusbox widget, immediate recolor it
with '-color' option, assign a callback, that is invoked each time
the Statusbox' color is changed, resize it with '-height' and '-width',
as well as set the flashintervall with '-flashintervall' and configure
any of the options understood by Tk::Frame(s) like -relief, -bg, ... .

=head1 METHODS

=over 4

=item B<color()>

'color()' setup a new color in the status area

=item B<flash('START')>

'flash('START')' starts flashing the status area by swapping the current
color in the status area with the normal background color
(the one restorable with the clear() method).

=item B<flash('END')>

'flash('END')' stops flashing the status area and restores the normal
background color (the one set with the clear() method).


=item B<clear()>

'clear()' restores the normal background color in the status area
(either the apps-background color or the widget's)

=back


=head1 OPTIONS

=over 4

=item B<-variable>

'-variable' allows to specify a reference to a scalar-value.
Each time the widget changes by user interaction, the variable
is changed too. Every variable change is immediately mapped in the
widget too.


=item B<-command>

'-command' can be used to supply a callback for processing after
each change of the Checkbox value.


=item B<-flashintervall>

'-flashintervall' can be used to set the flash-timing (on/offtime) in msecs.


=item B<-height>

'-height' sets the height of the status area widget in I<pixels>.


=item B<-width>

'-width' sets the width of the status area widget in I<pixels>.

=back


=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V1.0  (C) October 2002

=cut

###
### EOF
###

