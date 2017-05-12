######################################## SOH ###########################################
## Function : Additional Tk Class for a nicer Checkbutton
##
## Copyright (c) 2002-2007 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V2.1	24-Oct-2002 	Class released. MK
##            V2.2	12-Nov-2002 	Small Bugfix. MK
##            V2.3	30-Sep-2004 	Enhanced state disabled w/o highlightthickness. MK
##            V2.4	03-May-2005 	Added variable size option. MK
##            V2.5	19-Jul-2005 	Bugfix for noInitialCallback option - executed never if set. MK
##            V2.6	03-Apr-2007 	Added activeForeground option. MK
##            V2.7	14-Feb-2008 	Added -variable retrieval. MK
##            V2.8	21-Sep-2011 	Added -background update during set for catching unchanged BGs due to earlier invisibility. MK
##
######################################## EOH ###########################################
package Tk::Checkbox;

##############################################
### Use
##############################################
use Tk;
use Tk::Canvas;
use Tk::Frame;

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '2.7';

use base qw (Tk::Derived Tk::Frame);

########################################################################
Tk::Widget->Construct ('Checkbox');

#---------------------------------------------
sub ClassInit {
	my ($class, $window) = (@_);
	$class->SUPER::ClassInit($window);

	# Note these keyboard-Keys are only usable, if the widget gets 'focus'
	$window->bind ($class, '<ButtonPress-1>', 'set');
	$window->bind ($class, '<space>', 'set');
	$window->bind ($class, '<Control-Tab>','focusNext');
	$window->bind ($class, '<Control-Shift-Tab>','focusPrev');
	$window->bind ($class, '<Tab>', 'focus');
}

#---------------------------------------------
sub Populate {
	my ($this, $args) = @_;

	# Retrieve standard background
	if (defined ($args->{-bg})) {
		$args->{-background} = $args->{-bg};
	}
	# Retrieve standard foreground
	if (defined ($args->{-fg})) {
		$args->{-foreground} = $args->{-fg};
	}
	my $common_background = (defined($args->{-background})) ? 
										$args->{-background} :
										$this->cget ('-background');
	my $common_foreground = (defined($args->{-foreground})) ? 
										$args->{-foreground} :
										$this->parent->cget('-foreground');

	# retrieve extra option
	$this->{m_noInitialCallback} = delete $args->{-noinitialcallback};
	my $size = delete $args->{-size} || 15;
	
	# Create a Closure for saving the current value,
	# if there is no variable spec'd
	unless (defined $args->{-variable}) {
		my $gen = (defined ($args->{-offvalue})) ? $args->{-offvalue} : 0;
		my $var = \$gen;
		$args->{-variable} = $var;
	}
	# retrieve default values
	$this->{m_OffValue} = (defined($args->{-offvalue})) ? delete $args->{-offvalue} : 0;
	$this->{m_OnValue}  = (defined($args->{-onvalue} )) ? delete $args->{-onvalue}  : 1;
	

	$this->SUPER::Populate ($args);

	#Widget Creation
	my $canvas = $this->Canvas(
    	-height => $size,
    	-width => $size,
	)->pack(
    	-fill => 'both',
    	-expand => '1',
	);
	
	my @points = ( 0, 7, 3, 12, 4, 14, 4, 15, 11, 4, 15, 0, 4, 11, 0, 7);
	$_ = int($_ * $size / 15) foreach @points;	
	$this->{m_CheckMark} = $canvas->createPolygon(@points);
	
	$canvas->Tk::bind ('<ButtonPress-1>' => sub { $this->set(); } );
	$canvas->Tk::bind ('<Enter>' => sub { $this->enter(); } );
	$canvas->Tk::bind ('<Leave>' => sub { $this->leave(); } );
	$this->bind ('<Tab>' => sub { $this->focus(); } );

	$this->Advertise( 'canvas' => $canvas );
	
	$this->ConfigSpecs(
    	-background				=> ['METHOD', 'background', 'Background', 'grey'],
    	-foreground				=> ['METHOD', 'foreground', 'Foreground', 'black'],
    	-activebackground		=> [['SELF', 'DESCENDANTS', 'PASSIVE'], 'activeBackground', 'ActiveBackground', '#ececec'],
    	-activeforeground		=> [['SELF', 'DESCENDANTS', 'PASSIVE'], 'activeForeground', 'ActiveForeground', 'Black'],
    	-disabledforeground 	=> [['SELF', 'DESCENDANTS', 'PASSIVE'], 'disabledForeground', 'DisabledForeground', '#a3a3a3'],
    	-disabledbackground 	=> [['SELF', 'DESCENDANTS', 'PASSIVE'], 'disabledBackground', 'DisabledBackground', '#AE00B200C300'],
    	-borderwidth			=> [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', 2],
    	-relief					=> [['SELF', 'PASSIVE'], 'relief', 'Relief', 'sunken'],
    	-onvalue				=> ['METHOD', 'onvalue', 'OnValue', '1'],
    	-offvalue				=> ['METHOD', 'offvalue', 'OffValue', '0'],
	   	-state					=> ['METHOD', 'state', 'State', 'normal'],
    	-command 				=> ['CALLBACK',undef,undef, undef],
    	-variable 				=> ['METHOD', 'variable', 'Variable', undef],
		-takefocus				=> [$canvas , 'takeFocus','TakeFocus',1],
		-highlightthickness 	=> [['SELF'], 'highlightThickness','HighlightThickness', 1]
	);

	# Preset the internal Savers
	$this->{m_Normalbackground} = $common_background;
	$this->{m_Normalforeground} = $common_foreground;
	$this->{m_State} = 'normal';
	$this->{m_Entered} = 'false';
}

#---------------------------------------------
# promote the new background color to the canvas
# and the checkmark
#---------------------------------------------
sub background
{
	# Parameters
    my ($this, $arg) = @_;

	if ($arg) {
		if ($this->viewable) {
			# Prepare the background
			my $canvas = $this->Subwidget('canvas');
			$canvas->configure( -background => $arg);
			# Apply Checker-Color
			if ($this->{watch}->Fetch ne $this->{m_OnValue}) {
				$canvas->itemconfigure(
						$this->{m_CheckMark},
						-outline => $arg,
						-fill => $arg,
				);
			}
		}
		# Store it
	    $this->{m_Normalbackground} = $arg;
	}
	return $this->{m_Normalbackground};
}

#---------------------------------------------
# promote the new foreground color to the 
# canvas - checkmark
#---------------------------------------------
sub foreground
{
	# Parameters
    my ($this, $arg) = @_;

	if ($arg) {
		if ($this->viewable) {
			# Prepare the foreground
			my $canvas = $this->Subwidget('canvas');
			#$canvas->configure( -foreground => $arg);# wrong n/a in canvas !!
			# Apply Checker-Color
			if ($this->{watch}->Fetch eq $this->{m_OnValue}) {
				$canvas->itemconfigure(
						$this->{m_CheckMark},
						-outline => $arg,
						-fill => $arg,
				);
			}
		}
		# Store it
	    $this->{m_Normalforeground} = $arg;
	}
	return $this->{m_Normalforeground};
}

#---------------------------------------------
# switch to 'normal', 'disabled'
#---------------------------------------------
sub state {
	# Parameters
    my ($this, $arg) = @_;
	#print "reached state with >@_<\n";

	if (defined($arg)) {
		if ($this->viewable) {
			my ($canvas, $var, $color);
			$canvas = $this->Subwidget('canvas');
			$var = $this->{watch}->Fetch;
			#
			if ($arg eq 'disabled') {
				# Prepare the background
				$canvas->configure( -background => $this->cget ('-disabledbackground') );
				# Store/Delete HLT
				$this->{m_Highlightthickness} = $canvas->cget ('-highlightthickness');
				$canvas->configure(-highlightthickness => '0');

				#Prepare the checkmark foreground
				if ($var eq $this->{m_OnValue}) {
					$color = $this->cget ('-disabledforeground');
				}
				else {
					$color = $this->cget ('-disabledbackground');
				}
			}
			else {
				# Prepare the background
				$canvas->configure( -background => $this->{m_Normalbackground} );
				# Restore HLT
				$canvas->configure(-highlightthickness => ($this->{m_Highlightthickness} || '1'));

				#Prepare the checkmark foreground
				if ($var eq $this->{m_OnValue}) {
					$color = $this->{m_Normalforeground};
				}
				else {
					$color = $this->{m_Normalbackground};
				}
			}
			# Apply Checker-Color
			$canvas->itemconfigure(
					$this->{m_CheckMark},
					-outline => $color,
					-fill => $color,
			);
		
		}
		else {
			my ($canvas, $var, $color);
			$canvas = $this->Subwidget('canvas');

			#Prepare the checkmark foreground
			$color = $this->{m_Normalbackground};

			# Prepare the background
			$canvas->configure( -background => $this->{m_Normalbackground} );
			# Apply Checker-Color
			$canvas->itemconfigure(
					$this->{m_CheckMark},
					-outline => $color,
					-fill => $color,
			);
			if ($arg eq 'disabled') {
				# Store/Delete HLT
				$this->{m_Highlightthickness} = $canvas->cget ('-highlightthickness');
				$canvas->configure(-highlightthickness => '0');
			}
			else {
				# Restore HLT
				$canvas->configure(-highlightthickness => ($this->{m_Highlightthickness} || '0') );
			}
		}
		# Store it
	    $this->{m_State} = $arg;
	}
	return $this->{m_State};
}

#---------------------------------------------
# internal function to trace any on/off-value updates
#---------------------------------------------
sub onvalue
{
	# Parameters
	my ($this, $onvalue)  = @_;
	
	# if we're not in a cget we might consider changing the value
	if (defined $onvalue) {
		if ($this->viewable) {
			$this->{m_OnValue} = $onvalue;
		}
		else {
			# avoid misleading resetting to the default '1'
			if ($onvalue ne '1') {
				$this->{m_OnValue} = $onvalue;
			}
		}
	}
	# needed for cget
	return $this->{m_OnValue};
}
#---------------------------------------------
sub offvalue
{
	# Parameters
	my ($this, $offvalue)  = @_;
	
	# if we're not in a cget we might consider changing the value
	if (defined $offvalue) {
		if ($this->viewable) {
			$this->{m_OffValue} = $offvalue;	
		}
		else {
			# avoid misleading resetting to the default '0'
			if ($offvalue ne '0') {
				$this->{m_OffValue} = $offvalue;
			}
		}
	}
	# needed for cget
	return $this->{m_OffValue};
}


#---------------------------------------------
# Setting 'active' look after getting the focus
#---------------------------------------------
sub enter {
	# Parameters
	my $this = shift;

	if ($this->viewable) {
		my ($canvas, $color, $fgcolor);
		$canvas = $this->Subwidget('canvas');
		#
		if ($this->{m_State} ne 'disabled') {
			$this->{m_Entered} = 'true';
			$this->{m_Lastbackground} = $canvas->cget ('-background');
			$color = $this->cget ('-activebackground');
			$fgcolor = $this->cget ('-activeforeground');
			# Prepare the background			
			$canvas->configure( -background => $color );
			
			#Prepare the checkmark foreground
			if ($this->{watch}->Fetch eq $this->{m_OnValue}) {
				$canvas->itemconfigure(
						$this->{m_CheckMark},
						#-outline => $color,
						#-fill => $color,
						-outline => $fgcolor,
						-fill => $fgcolor,
				);
			}
			else {
				$canvas->itemconfigure(
						$this->{m_CheckMark},
						-outline => $color,
						-fill => $color,
				);
			}
		}
	}	
}

#---------------------------------------------
# Restore the default look after leaving the focus
#---------------------------------------------
sub leave {
	my $this = shift;

	if ($this->{m_Entered} eq 'true') {
		my ($canvas, $color);
		$canvas = $this->Subwidget('canvas');
		$this->{m_Entered} = 'false';
		
		# Prepare the background			
		$canvas->configure( -background => $this->{m_Lastbackground} );
		
		#Prepare the checkmark foreground
		if ($this->{watch}->Fetch eq $this->{m_OnValue}) {
			#$color = $this->cget ('-foreground');
			$color = $this->{m_Normalforeground};
		}
		else {
			$color = $canvas->cget ('-background');
		}
		$canvas->itemconfigure(
				$this->{m_CheckMark},
				-outline => $color,
				-fill => $color,
		);
	}	
}

#---------------------------------------------
# Ties the scalar variable to the widget
#---------------------------------------------
sub variable {
    use Tie::Watch;

	# Parameters
    my ($this, $vref) = @_;
	#
	if ($vref) {
    	my $st = [sub {  my ($watch, $new_val) = @_;
						 my $argv= $watch->Args('-store');
						 $argv->[0]->set($new_val);
						 $watch->Store($new_val);
					  }, $this];

    	$this->{watch} = Tie::Watch->new(-variable => $vref, -store => $st);

		# Remove the Watchpoint after it's no more needed
		$this->OnDestroy( sub { $this->{watch}->Unwatch if $this->{watch} } );

		# Preset will the current var-value
		$this->set($$vref);
		# Store internally
		$this->{m_VarRef} = $vref;
	}
	return $this->{m_VarRef};
} # end variable


#---------------------------------------------
# Set Value by Pressing the Mouse Bttn or via Parm
#---------------------------------------------
sub set {
	# Parameters
    my ($this, $newvalue) = @_;

	if ( $this->{m_State} ne 'disabled') {
		my ($canvas, $color);
		$canvas = $this->Subwidget('canvas');
		#
		#toggle stored value, if no external value was given
		unless (defined($newvalue)) {
			$newvalue = $this->{watch}->Fetch;
			if (defined ($newvalue)) {
				if ($newvalue eq $this->{m_OnValue}) {
					$newvalue = $this->{m_OffValue};
				}
				else {
					$newvalue = $this->{m_OnValue};
				}
			}
			else {
				$newvalue = $this->{m_OffValue};
			}
		}
		#safety check for illegal values
		if ($newvalue ne $this->{m_OnValue} && $newvalue ne $this->{m_OffValue}) {
			if ($newvalue eq '1') {
				$newvalue = $this->{m_OnValue};
			}
			else {
				$newvalue = $this->{m_OffValue};
			}
		}

		$this->{watch}->Store($newvalue);

		#setup the coloring
		if ($newvalue eq $this->{m_OnValue}) {
			$color = $this->{m_Normalforeground};
		}
		else {
			$color = $this->cget ('-background');
			if ($this->{m_Entered} eq 'true') {
				$color = $this->cget ('-activebackground');
			}
		}
		# Refresh background in case not yet applied due to not yet viewable
		$canvas->configure( -background => $this->{m_Normalbackground});
		#Prepare the checkmark foreground
		$canvas->itemconfigure(
				$this->{m_CheckMark},
				-outline => $color,
				-fill => $color,
		);

		# invoke callback for normal execution
		my @args = ( $newvalue );
		my $inhibit = delete $this->{m_noInitialCallback};
		$this->Callback(-command => @args) unless $inhibit;
	}
}

########################################################################
1;
__END__


=head1 NAME

Tk::Checkbox - Yet Another Checkbutton widget (with a sizable marker)

=head1 SYNOPSIS

    use Tk;
    use Tk::Checkbox;

    my $var = 'Up';
    my $mw = MainWindow->new();


    my $cb1 = $mw->Checkbox (
        -variable => \$var,
        -command  => \&test_cb,
        -onvalue  => 'Up',
        -offvalue => 'Down',
        #-noinitialcallback => '1',
		#-size => '8',
   )->pack;
	
    Tk::MainLoop;
	
    sub test_cb
    {
        print "test_cb called with [@_], \$var = >$var<\n";
    }
	

=head1 DESCRIPTION

Another check button style widget that uses a check mark in a fixed
box. Useful as a boolean field. 
It's based on Damion K. Wilson's version from Tk-DKW-0.03, suitable
for perl Tk800.x (developed with Tk800.024).

You can tie a scalar-value to the Checkbox widget, enable/disable it,
assign a callback, that is invoked each time the Checkbox is changed,
as well as set ON- and OFF-values and configure any of the options
understood by Tk::Frame(s) like -relief, -bg, ... .

=head1 METHODS

=over 4

=item B<set()>

'set($newvalue)' allows to set/reset the the widget methodically,
$newvalue must be either 'onvalue' or 'offvalue'.

You should prefer interacting with the widget via a variable.

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


=item B<-onvalue>

'-onvalue' can be used to supply a value that is used/returned,
if the checkmark is 'checked'. default is '1'.

=item B<-offvalue>

'-offvalue' is the opposite of 'onvalue', it isused/returned,
if the checkmark is 'unchecked'. default is '0'.

=item B<-noinitialcallback>

'-noinitialcallback' can be used to suppress the invocation of an (assigned)
callback, immediate after a (new) variable has been configured with -variable.

=item B<-size>

'-size' can be used to specify the widget- (and checker) size (default 15 pt)

=back

=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V2.8  (C) September 2011

=cut

###
### EOF
###

