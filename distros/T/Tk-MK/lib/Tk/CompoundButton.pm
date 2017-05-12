######################################## SOH ###########################################
## Function : Additional Tk Class for a Button with Text and image or bitmap
##
## Copyright (c) 2004-2009 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V0.1	22-Jul-2004 	Class released. MK
## History  : V0.2	08-Mar-2007 	Added side-default from Optionbase. Thx to hkuhlmann. MK
## History  : V0.3	05-Nov-2009 	Complete ReImplemention based on Tk::Compound. MK
##
######################################## EOH ###########################################
package Tk::CompoundButton;

##############################################
### Use
##############################################
use Tk;
use Tk::Button;
use Tk::Frame;
use Tk::Compound;

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '0.3';

use base qw (Tk::Frame);

########################################################################
Tk::Widget->Construct ('CompoundButton');

#---------------------------------------------
sub ClassInit
{
	# Parameters
	my ($class, $window) = @_;

	$class->SUPER::ClassInit($window);

	#-------------------------------------------------
	# Setup proper bindings for handling the 'active' behavior
	$window->bind ($class, '<Enter>', 'enter');
	$window->bind ($class, '<Leave>', 'leave');
}

#---------------------------------------------
sub Populate
{
	# Parameters
	my ($this, $args) = @_;
	# Locals
	my (%attrs, @sides, @txtjst_sides, $button, @text_ref_text);
 
	@sides = qw(left right top bottom);
	@txtjst_sides = qw(left right center none);
	#-------------------------------------------------
	# Retrieve special option (which are not feasible for configure
	$attrs{side}   = delete $args->{-side} || $this->optionGet( 'side', 'Side' ) || 'right';
	croak "Error: Allowed values for '-side' are " . join(', ', @sides) . "!\n" unless grep /$attrs{side}/, @sides;
	$attrs{gap}    = delete $args->{-gap}; unless (defined $attrs{gap}) { $attrs{gap} = $this->optionGet( 'gap', 'Gap' ) || '3' }
	$attrs{textjustify}   = delete $args->{-textjustify} || $this->optionGet( 'textjustify', 'Textjustify' ) || 'none';
	croak "Error: Allowed values for '-textjustify' are " . join(', ', @txtjst_sides) . "!\n" unless grep /$attrs{textjustify}/, @txtjst_sides;
	#-------------------------------------------------
	# We must remove padx/y otherwise during widget creation the padx/y is calc'd as padx/y PLUS optionbased padx/y
	$attrs{padx}   = delete $args->{-padx}; unless (defined $attrs{padx}) { $attrs{padx} = $this->optionGet( 'padx', 'padX' ) || '3m' }
	$attrs{pady}   = delete $args->{-pady}; unless (defined $attrs{pady}) { $attrs{pady} = $this->optionGet( 'pady', 'padY' ) || '1m' }
	# similar problem for abchor
	$attrs{anchor} = delete $args->{-anchor} || $this->optionGet( 'anchor', 'Anchor' ) || 'center';
	#-------------------------------------------------
	# The following 2 opts MUST also be deleted otherwise the Bttn gets filled ONLY with the image
	$attrs{image}  = delete $args->{-image};
	$attrs{bitmap} = delete $args->{-bitmap};
	#-------------------------------------------------

	#-------------------------------------------------
	# Create a worker-button
 	$this->{_Button} = $button = $this->Button()->pack;
	#-------------------------------------------------

	#-------------------------------------------------
	# Walk through the BaseClass
	$this->SUPER::Populate($args);
	#-------------------------------------------------

	#-------------------------------------------------
	# Prepare the minimum necessary options
	$this->ConfigSpecs(
    		-padx    => ['SELF', 'padx', 'padX', '-1'], # Mandatory to avoid 'doubled' padx insertion (1x Bttn, 1x Frm)
    		-pady    => ['SELF', 'pady', 'padY', '-1'], # Mandatory to avoid 'doubled' pady insertion (1x Bttn, 1x Frm)
 		'DEFAULT'		=> [$button],
	);
	#-------------------------------------------------

	#-------------------------------------------------
	# Redirect all operations to the 'main' button
	$this->Delegates('DEFAULT' => $button);
	#-------------------------------------------------

	#-------------------------------------------------
	# Now apply the saved attrs to the button
	$button->configure(-padx => $attrs{padx}, -pady => $attrs{pady}, -anchor => $attrs{anchor});
	#-------------------------------------------------

	#-------------------------------------------------
	# store values needed for building the Compount Element(s)
	$attrs{width} = $args->{-width} || $this->optionGet( 'width', 'Width' ) || $this->cget('-Width');
	$attrs{background} = $args->{-bg} || $args->{-background} || $this->optionGet( 'background', 'Background' ) || $this->cget('-background');
	$attrs{foreground} = $args->{-fg} || $args->{-foreground} || $this->optionGet( 'foreground', 'Foreground' ) || $this->cget('-foreground');
	$attrs{justify}    = $args->{-justify} || $this->optionGet( 'justify', 'Justify' )  || $this->cget('-justify');
	$attrs{underline}  = $args->{-underline} || $this->optionGet( 'underline', 'Underline' )  || $this->cget('-underline');
	$attrs{wraplength} = $args->{-wraplength} || $this->optionGet( 'wraplength', 'WrapLength' )  || $this->cget('-wraplength');
	$attrs{font} 	   = $args->{-font} || $this->optionGet( 'font', 'Font' )  || $this->cget('-font');
	$attrs{text} 	   = $args->{-text} || $this->optionGet( 'text', 'Text' )  || $this->cget('-text');
	# store coloring for an 'active' looking Compount Element too
	$attrs{activebackground} = $args->{-activebackground} || $this->optionGet( 'activebackground', 'ActiveBackground' ) || $this->cget('-activebackground');
	$attrs{activeforeground} = $args->{-activeforeground} || $this->optionGet( 'activeforeground', 'ActiveForeground' ) || $this->cget('-activeforeground');

	#-------------------------------------------------
	# Take care of text references
	if ($args->{-textvariable}) {
		# Setup a Tie to watch for changes on the textvar
    	use Tie::Watch;
   		my $st = [sub {  my ($watch, $new_val) = @_;
							 my $argv= $watch->Args('-store');
							 $argv->[0]->create_all_compounds($button, %attrs, text => $new_val);
							 $watch->Store($new_val);
						  }, $this];

    	$this->{_BPI_VRWatch} = Tie::Watch->new(-variable => $args->{-textvariable}, -store => $st);


		# Preset will the current var-value
		@text_ref_text = (text => ${$args->{-textvariable}});
	}
	#-------------------------------------------------

	#-------------------------------------------------
	# Now create an initial set of compounds
	$this->create_all_compounds($button, %attrs, @text_ref_text);

	#-------------------------------------------------
	# Remove the Watchpoint after it's no more needed
	$this->OnDestroy( sub { $this->{_BPI_VRWatch}->Unwatch if $this->{_BPI_VRWatch};
					 		$this->{_BPI_CompNormal}->delete if $this->{_BPI_CompNormal};
					 		$this->{_BPI_CompActive}->delete if $this->{_BPI_CompActive};
					  } );

}


########################################################################

#---------------------------------------------
# create_all_compounds
# The procedure below is invoked to create ALL
# compounds needed for the current widget.
#---------------------------------------------
sub create_all_compounds
{
	# Paremeters
	my ($this, $button, %attrs) = @_;

	#-------------------------------------------------
	# Create a 'normal' Compount Element and attach it
	$this->{_BPI_CompNormal} = create_compound($button, %attrs);
 	$button->configure(-image => $this->{_BPI_CompNormal});

	#-------------------------------------------------
	# Create an 'active' Compount Element and store it
	$attrs{background} = $attrs{activebackground};
	$attrs{foreground} = $attrs{activeforeground};
	#
	$this->{_BPI_CompActive} = create_compound($button, %attrs);
}

#---------------------------------------------
# create_compound
# The procedure below is invoked to create a
# single compound according given attr-spec.
#---------------------------------------------
sub create_compound
{
	# Paremeters
	my ($button, %attrs) = @_;

	# Locals
	my ($compound, %text_attrs);

	#-------------------------------------------------
	# Create a new storage element
	$compound = $button->Compound(-padx => $attrs{padx}, -pady => $attrs{pady}, -font => $attrs{font}, 
					  #-showbackground => 1, -relief => 'ridge', -borderwidth => 2, ## for debugging only
					  -background => $attrs{background}, -foreground => $attrs{foreground});
	# a shortcut to save effort
	%text_attrs = (-text => $attrs{text}, -font => $attrs{font}, -justify => $attrs{justify},
						-underline => $attrs{underline}, -wraplength => $attrs{wraplength});	

	#-------------------------------------------------
	# Provide a dynamic TEXT justification (by calculating dynamic gap between image/bitmap and text
	if ($attrs{textjustify} ne 'none' and $attrs{width}) {
		my ($im_width, $txt_width, $delta);
		
		$im_width  = 0;
		if ($attrs{image}) {
			$im_width  = $attrs{image}->width;
		}
		elsif ($attrs{bitmap}) {
			croak "Error: Option '-textjustify' is NOT usable together with '-bitmap', use a pixmap via '-image' instead!\n";
		}
		$txt_width = $button->fontMeasure($attrs{font}, $attrs{text});
		$delta = $attrs{width} - $im_width - $txt_width - $attrs{gap};

		if ($attrs{textjustify} eq 'center') {
			$delta /= 2;
		}
		else {
			if (($attrs{textjustify} eq 'right' and $attrs{anchor} =~ /e$/io)
			or  ($attrs{textjustify} eq 'left' and $attrs{anchor} =~ /w$/io)) {
				$delta = 0;
			}
		}

		$delta = 0 if $delta < 0; # failsafe in case of multicolumn-text
		$attrs{gap} += $delta;
	}

	#-------------------------------------------------
	# Differentiate build according side
	if ($attrs{side} =~ /left|right/io) {
		$compound->Line(-anchor => $attrs{anchor});
		if ($attrs{side} =~ /left/io) {
			if ($attrs{image}) {
				$compound->Image(-image => $attrs{image})
			}
			elsif ($attrs{bitmap}) {
				$compound->Bitmap(-bitmap => $attrs{bitmap})
			}
			$compound->Space(-width => $attrs{gap});
 	        $compound->Text(%text_attrs);
		}
		else {
 	        $compound->Text(%text_attrs);
			$compound->Space(-width => $attrs{gap});
			if ($attrs{image}) {
				$compound->Image(-image => $attrs{image})
			}
			elsif ($attrs{bitmap}) {
				$compound->Bitmap(-bitmap => $attrs{bitmap})
			}
		}
	}
	else { # Side Top or Bottom
		$compound->Line(-anchor => $attrs{anchor});
		if ($attrs{side} =~ /top/io) {
			if ($attrs{image}) {
				$compound->Image(-image => $attrs{image})
			}
			elsif ($attrs{bitmap}) {
				$compound->Bitmap(-bitmap => $attrs{bitmap})
			}
			$compound->Line(-anchor => $attrs{anchor});
			$compound->Space(-height => $attrs{gap});
			$compound->Line(-anchor => $attrs{anchor});
 	        $compound->Text(%text_attrs);
		}
		else {
 	        $compound->Text(%text_attrs);
			$compound->Line(-anchor => $attrs{anchor});
			$compound->Space(-height => $attrs{gap});
			$compound->Line(-anchor => $attrs{anchor});
			if ($attrs{image}) {
				$compound->Image(-image => $attrs{image})
			}
			elsif ($attrs{bitmap}) {
				$compound->Bitmap(-bitmap => $attrs{bitmap})
			}
		}
	}
	return $compound;
}

#---------------------------------------------
# enter
# The procedure below is invoked when the
# mouse pointer enters a button widget. It
# changes the 'visible' state of the button
#  to active unless the button is disabled.
#---------------------------------------------
sub enter
{
	my $this = shift;
	$this->{_Button}->configure(
			-image => $this->{_BPI_CompActive}) if $this->cget('-state') ne 'disabled'
}

#---------------------------------------------
# leave
# The procedure below is invoked when the
# mouse pointer leaves a button widget. It
# changes the 'visible' state of the button
#  back to normal.
#---------------------------------------------
sub leave
{
	my $this = shift;
	$this->{_Button}->configure(
			-image => $this->{_BPI_CompNormal}) if $this->cget('-state') ne 'disabled'
}


########################################################################
1;
__END__


=head1 NAME

Tk::CompoundButton - Enhanced Button widget with a bitmap/image B<AND> a text label

=head1 SYNOPSIS

    use Tk;
    use Tk::CompoundButton

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
    my $bt1 = $mw->CompoundButton(
		#-padx => -1,
		-text => 'Enable',
		-image => $downangle,
        -bitmap => 'error',
		-command => \&bttn_pressed_cb1,
		#-borderwidth => '12',
		#-relief => 'ridge',
		-bg => 'orange',
		-fg => 'green',
 		-textvariable => \$var,
		-side => 'bottom',
#		-side => 'top',
#		-side => 'left',
		-activebackground => 'red',
		-activeforeground => 'blue',
# 		-width => 200,
 		-height => 200,
		#-anchor => 'sw',
		#-anchor => 'e',
		#-justify => 'right',
		-gap => 20,
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
standard Button, if you want to display a bitmap/image B<AND> a text label.

=head1 METHODS

for details on supported methods  - see also B<Tk::Button>


=head1 OPTIONS

=over 4

=item B<-side>

-side => 'I<value>' allows to specify the side at which the bitmap/image is 
positioned. Value may be one of B<top>, B<left>, B<bottom> or B<right>.


=item B<-gap>

-gap => 'I<value>' allows to specify the size of the gap between
 the bitmap/image and the text.
default is 5px.


=item B<-textjustify>

-textjustify => 'I<value>' allows to justify the text independant
 from the image item.
Usable values are [left, right, center, or  B<none>],  default is none.
Normally image and text are placed as a contiguous block on either
 side according B<-anchor> option.
Using this option allows to break this rule.
Example: B<-textjustify> allows for a column of buttons of same size
to have all images on the right corner and the
text in front of it centered in respect ot the overall button-width:

 Default Mode: 
 +----------------+  +----------------+  +----------------+
 |        Text IMG|  |Text IMG        |	 |   Text IMG     |
 +----------------+  +----------------+	 +----------------+
 -anchor => 'e',       -anchor => 'w'      -anchor => 'e'
 -side   => 'right'    -side   => 'right'  -side   => 'right'



 textjustify Mode:
 +----------------+  +----------------+  +----------------+
 |Text         IMG|  |     Text    IMG|  |        Text IMG|
 +----------------+  +----------------+  +----------------+
 -anchor => 'e'      -anchor => 'e'      -anchor => 'e'
 -textjustify        -textjustify        -textjustify
       => 'left'           => 'center'         => 'center'
 -side => 'right'    -side => 'right'    -side => 'right'


NOTE: -textjustify does work only, if you specify also a B<fixed> B<WIDTH>
of the button. Furthermore
it does not work with -bitmap option, only -image.

***


For details on all other options especially -anchor, and -justify see B<Tk::Button>.

This widget is fully backward compatible to the standard Tk::Button and thus supports
all options found there.


=back


=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V0.3  (C) 2004 - 2009

=cut

###
### EOF
###

