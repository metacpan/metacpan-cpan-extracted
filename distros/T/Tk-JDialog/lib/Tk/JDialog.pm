package Tk::JDialog;

use 5.006;
use strict;
use warnings;

=head1 NAME

Tk::JDialog - a translation of `tk_dialog' from Tcl/Tk to TkPerl (based on John Stoffel's idea).

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.20';


=head1 SYNOPSIS

 use Tk::JDialog;

 my $Dialog = $mw->JDialog( -option => value, ...  );
 ...
 my $button_label = $Dialog->Show;

=head1 DESCRIPTION

 This is an OO implementation of `tk_dialog'.  First, create all your Dialog
 objects during program initialization.  When it's time to use a dialog, 
 invoke the `show' method on a dialog object; the method then displays 
 the dialog, waits for a button to be invoked, and returns the text 
 label of the selected button.

 A Dialog object essentially consists of two subwidgets: a Label widget for
 the bitmap and a Label wigdet for the text of the dialog.  If required, you 
 can invoke the `configure' method to change any characteristic of these 
 subwidgets.

 Because a Dialog object is a Toplevel widget all the 'composite' base class
 methods are available to you.

=head1 EXAMPLE

 #!/usr/bin/perl

 use Tk::JDialog;

 my $mw = MainWindow->new;
 my $Dialog = $mw->JDialog(
     -title          => 'Choose!',   #DISPLAY A WINDOW TITLE
     -text           => 'Press Ok to Continue',  #DISPLAY A CAPTION
     -bitmap         => 'info',      #DISPLAY BUILT-IN info BITMAP.
     -default_button => '~Ok',
     -escape_button  => '~Cancel',
     -buttons        => ['~Ok', '~Cancel', '~Quit'], #DISPLAY 3 BUTTONS
     -images         => ['/tmp/ok.xpm', '', ''],     #EXAMPLE WITH IMAGE FILE
 );
 my $button_label = $Dialog->Show( );
 print "..You pressed [$button_label]!\n";
 exit(0);

=head1 OPTIONS

=over 4

=item -title

     (string) - Title to display in the dialog's decorative window frame.
     Default:  ''.

=item -text

     (string) - Message to display in the dialog widget.  Default:  ''.

=item -bitmap

     (string) - Bitmap to display in the dialog.
     If non-empty, specifies a bitmap to display in the top portion of
     the Dialog, to the left of the text.  If this is an empty string
     then no bitmap is displayed in the Dialog.
     There are several built-in Tk bitmaps: 'error', 'hourglass', 'info', 
     'questhead', 'question', 'warning', 'Tk', and 'transparent'.
     You can also use a bitmap file name, ie. '@/path/to/my/bitmap'
     Default:  ''.

=item -default_button

     (string) - Text label of the button that is to display the
     default border and is to be selected if the user presses [Enter].  
     (''signifies no default button).  Default:  ''.

=item -escape_button

     (string) - Text label of the button that is to be invoked when the 
     user presses the <Esc> key.  Default:  ''.

=item -button_labels

     (Reference) - A reference to a list of one or more strings to
     display in buttons across the bottom of the dialog.  These strings 
     (labels) are also returned by the Show() method corresponding to 
     the button selected.  NOTE:  A tilde ("~") can be placed before a 
     letter in a label string to indicate the <Alt-<letterkey>> that 
     the user can also press to select the button, for example:
     "~Ok" means select this button if the user presses <Alt-<O>>.  
     The tilde is not displayed for the button text.  The text is also 
     not displayed if an image file is specified in the corresponding 
     optional -images array, but is returned if the button is pressed.
     If this option is not given, a single button labeled "OK" is created.

=item -images

     (Reference) - Specify the optional path and file id for an image 
     for each button to display an image in lieu of the label text 
     ('' if a corresponding button is to use text).  NOTE: button
     will use text if the image file is not found.  Also the 
     "-button_labels" option MUST ALWAYS be specified anyway to provide 
     the required return string.

=item -noballoons

     (boolean) - if true (1) then no balloon displaying the "button_labels" 
     label text value will be displayed when the mouse hovers over the 
     corresponding buttons which display imiages.  If false (0), then 
     text balloons will be displayed when hovering.  Default: 0.

=back

=head1 METHODS

=over 4

=item Show ( [ -global | -nograb ] )

 $answer = $dialog->B<Show>( [ -global | -nograb ] );

 This method displays the Dialog box, waits for the user's response, and
 stores the text string of the selected Button in $answer.  This allows 
 the programmer to determine which button the user selected.
 
 NOTE:  Execution goes into a wait-loop here until the the user makes a 
 selection!
 
 If -global is specified a global (rather than local) grab is
 performed (No other window or widget can be minipulated via the keyboard 
 or mouse until a button is selected) making the dialog "modal".  
 Default: "-nograb" (the dialog is "non-modal" while awaiting input).

 The actual Dialog is shown using the Popup method. Any other
 options supplied to Show are passed to Popup, and can be used to
 position the Dialog on the screen. Please read L<Tk::Popup> for
 details.

=item Populate ( -option => value, ... )

 (Constructor) - my $Dialog = $mw->JDialog( -option => value, ... );

=back

=head1 ADVERTISED WIDGETS

 Tk::JDialog inherits all the Tk::Dialog exposed widgets and methods plus 
 the following two subwidgets:
 
=over 4

=item message

     The dialog's Label widget containing the message text.
 
=item bitmap

     The dialog's Label widget containing the bitmap image.

=back

=head1 AUTHOR

Jim Turner, C<< <turnerjw784 at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-jdialog at rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-JDialog>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::JDialog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-JDialog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-JDialog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-JDialog>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-JDialog/>

=back


=head1 ACKNOWLEDGEMENTS

 Tk::JDialog derived from the L<Tk::Dialog> wiget from Tcl/Tk to TkPerl 
 (based on John Stoffel's idea).  It addes the options:  -escape_button 
 and -images, 

=head1 LICENSE AND COPYRIGHT

Copyright 1997-2023 Jim Turner.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=head1 SEE ALSO

 L<Tk::Dialog>, L<Tk::Label>, L<Tk::Widget>, L<Tk>

=cut

# JDialog - a translation of `tk_dialog' from Tcl/Tk to TkPerl (based on
# John Stoffel's idea).
#
# Modified 2/13/97 by Jim Turner of Computer Sciences Corporation to
# add underline character (alt-key) activation of buttons, fix bug in the
# bindings for <Return> key where default button always activated even if
# another button had the keyboard focus.  Now, the default button starts
# with the input focus!!!
#
# Jim Turner also added the "escape_button" option on 2/14/97 to allow
# programmer to specify a button to invoke if user presses the <Escape> key!
# Jim Turner also added the "images" option on 2/14/97 to allow programmer
# to specify gifs in leu of text for the buttons.
#
# Jim Turner also removed the "wraplength" option on 2/19/97 to allow
# longer label strings (>3") to not be broken.  User can specify -wraplength!
# Stephen O. Lidie, Lehigh University Computing Center.  94/12/27
# lusol@Lehigh.EDU
#
# 04/22/97 Jim Turner fixed bug where screen completely locks up if the calling
# script invokes a Motif app (ie. xv or another Perl/Tk app) shortly after    
# calling this dialog box.  Did not seem to adversely effect keyboard focus.
# fixed by commenting out 1 line of code (&$old_focus);
#
# This is an OO implementation of `tk_dialog'.  First, create all your Dialog
# objects during program initialization.  When it's time to use a dialog, 
# invoke the `show' method on a dialog object; the method then displays the 
# dialog, waits for a button to be invoked, and returns the text label of the 
# selected button.
#
# A Dialog object essentially consists of two subwidgets: a Label widget for
# the bitmap and a Label wigdet for the text of the dialog.  If required, you 
# can invoke the `configure' method to change any characteristic of these 
# subwidgets.
#
# Because a Dialog object is a Toplevel widget all the 'composite' base class
# methods are available to you.

use Carp;
#use strict qw(vars);
our $useBalloon = 0;
use Tk ":eventtypes";
eval 'use Tk::Balloon; $useBalloon = 1; 1';
require Tk::Toplevel;

@Tk::JDialog::ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('JDialog');

sub Populate
{
	# Dialog object constructor.  Uses `new' method from base class
	# to create object container then creates the dialog toplevel.

	my($cw, $args) = @_;

	$cw->SUPER::Populate($args);

	my ($w_bitmap,$w_but,$pad1,$pad2,$underlinepos,$mychar,$blshow,$i);
	my ($btnopt,$undopt,$balloon);

	my $buttons = delete $args->{'-buttons'};
	my $images = delete $args->{'-images'};
	$buttons = ['~OK']  unless (defined $buttons);
	my $default_button = delete $args->{-default_button};
	my $escape_button = delete $args->{-escape_button};
	my $noballoons = delete $args->{-noballoons};
	$useBalloon = 0  if ($noballoons);
	$default_button = $buttons->[0] unless (defined $default_button);

	# Create the Toplevel window and divide it into top and bottom parts.

	$cw->{'selected_button'} = '';
	my (@pl) = (-side => 'top', -fill => 'both');
	($pad1, $pad2) =
	([-padx => '3m', -pady => '3m'], [-padx => '3m', -pady => '2m']);

	$cw->withdraw;
	$cw->iconname('JDialog');
	$cw->protocol('WM_DELETE_WINDOW' => sub {});
	$cw->transient($cw->Parent->toplevel)  unless ($^O =~ /Win/i);

	my $w_top = $cw->Frame(Name => 'top',-relief => 'raised', -borderwidth => 1);
	my $w_bot = $cw->Frame(Name => 'bot',-relief => 'raised', -borderwidth => 1);
	$w_top->pack(@pl);
	$w_bot->pack(@pl);

	# Fill the top part with the bitmap and message.

	@pl = (-side => 'left');

	$w_bitmap = $w_top->Label(Name => 'bitmap');
	$w_bitmap->pack(@pl, @$pad1);
	my $w_msg = $w_top->Label(
			#-wraplength => '3i',    --!!! Removed 2/19 by Jim Turner
			-justify    => 'left'
	);

	$w_msg->pack(-side => 'right', -expand => 1, -fill => 'both', @$pad1);

	# Create a row of buttons at the bottom of the dialog.

	my ($w_default_button, $bl) = (undef, '');
	$cw->{'default_button'} = undef;
	$cw->{'escape_button'} = undef;
	$i = 0;
	foreach $bl (@$buttons) {
		$blshow = $bl;
		$underlinepos = ($blshow =~ s/^(.*)~/$1/) ? length($1): undef;
		if (defined($$images[$i]) && $$images[$i] gt ' ' && -e $$images[$i]) {		
			$cw->Photo($blshow, -file => $$images[$i]);
			$btnopt = '-image';
		} else {
			$btnopt = '-text';
		}
		if (defined($underlinepos)) {		
			$mychar = substr($blshow,$underlinepos,1);
			$w_but = $w_bot->Button(
				$btnopt => $blshow,
				-underline => $underlinepos,
				-command => [
					sub {
						$_[0]->{'selected_button'} = $_[1];
					}, $cw, $bl,
				]
			);
			$cw->bind("<Alt-\l$mychar>", [$w_but => "Invoke"]);
			$cw->bind("<Key-\l$mychar>", [$w_but => "Invoke"]);
		} else {
			$w_but = $w_bot->Button(
				$btnopt => $blshow,
				-command => [
				sub {
					$_[0]->{'selected_button'} = $_[1];
					}, $cw, $bl,
				]
			);
		}
		if ($useBalloon && $btnopt eq '-image') {
		
			$balloon = $cw->Balloon();
			$balloon->attach($w_but, -state => 'balloon', -balloonmsg => $blshow);
		}
		if ($bl eq $default_button) {
			$w_default_button = $w_bot->Frame(
					-relief      => 'sunken',
					-borderwidth => 1
			);
			$w_but->raise($w_default_button);
			$w_default_button->pack(@pl, -expand => 1, @$pad2);
			$w_but->pack(-in => $w_default_button, -padx => '2m',
					-pady => '2m'
			);

			$cw->{'default_button'} = $w_but;
			goto JWT_SKIP1;
			$cw->bind(
					'<Return>' => [
						sub {
							$_[1]->flash; 
							$_[2]->{'selected_button'} = $_[3];
						}, $w_but, $cw, $bl,
					]
			);
			JWT_SKIP1:
		} else {
			$w_but->pack(@pl, -expand => 1, @$pad2);
			$cw->{'default_button'} = $w_but  unless(defined($cw->{'default_button'}));
		}
		if (defined($escape_button) && $bl eq $escape_button) {
			$cw->{'escape_button'} = $w_but;
			$cw->bind('<Escape>' => [$w_but => "Invoke"]);
		}
		++$i;
	} # end for all buttons

	$cw->Advertise(message => $w_msg);
	$cw->Advertise(bitmap  => $w_bitmap );
	#!!!$cw->{'default_button'} = $w_default_button;
	if ($^O =~ /Win/i) {
		$cw->ConfigSpecs(
				-image      => ['bitmap',undef,undef,undef],
				-bitmap     => ['bitmap',undef,undef,undef],
				-fg         => ['ADVERTISED','foreground','Foreground','black'],
				-foreground => ['ADVERTISED','foreground','Foreground','black'],
				-bg         => ['DESCENDANTS','background','Background',undef],
				-background => ['DESCENDANTS','background','Background',undef],
				-font       => ['message','font','Font','{MS Sans} 14'],
				DEFAULT     => ['message',undef,undef,undef]
		);
	} else {
		$cw->ConfigSpecs(
				-image      => ['bitmap',undef,undef,undef],
				-bitmap     => ['bitmap',undef,undef,undef],
				-fg         => ['ADVERTISED','foreground','Foreground','black'],
				-foreground => ['ADVERTISED','foreground','Foreground','black'],
				-bg         => ['DESCENDANTS','background','Background',undef],
				-background => ['DESCENDANTS','background','Background',undef],
				# JWT for TNT!  -font       => ['message','font','Font','-*-Times-Medium-R-Normal-*-180-*-*-*-*-*-*'],
#x				-font       => ['message','font','Font','-adobe-helvetica-bold-r-normal--17-120-100-100-p-92-iso8859-1'],
				-font       => ['message','font','Font','Helvetica -17 bold'],
				DEFAULT     => ['message',undef,undef,undef]
		);
	}
} # end Dialog constructor

sub Show {   	# Dialog object public method - display the dialog.

	my ($cw, $grab_type) = @_;

	croak "Dialog:  `show' method requires at least 1 argument"
			if scalar @_ < 1 ;

	my $old_grab  = $cw->grabSave;

	# Update all geometry information, center the dialog in the display
	# and deiconify it

	$cw->Popup(); 

	# set a grab and claim the focus.
	if (defined $cw->{'default_button'}) { 
		$cw->{'default_button'}->focus;
	} else {
		$cw->focus;
	}
	unless (!defined($ENV{DESKTOP_SESSION}) || $ENV{DESKTOP_SESSION} =~ /kde/o) {
		if (defined $grab_type && length $grab_type) {
			$cw->grab($grab_type)  if ($grab_type !~ /no/io);  #JWT: ADDED 20010517 TO ALLOW NON-GRABBING!
		} else {
			$cw->grab;
		}
	}
	$cw->update;

	# Wait for the user to respond, restore the focus and grab, withdraw
	# the dialog and return the label of the selected button.

	$cw->waitVariable(\$cw->{'selected_button'});
	$cw->grabRelease;
	$cw->withdraw;
	#DIALOG (WINDOW) IS POPPED UP SHORTLY AFTERWARDS!
	&$old_grab;
	return $cw->{'selected_button'};

} # end Dialog show method

1; # End of Tk::JDialog
