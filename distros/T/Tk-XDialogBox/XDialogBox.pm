#
# DialogBox is similar to Dialog except that it allows any widget
# in the top frame. Widgets can be added with the add method. Currently
# there exists no way of deleting a widget once it has been added.
#
# ... and need many Features ;-) This is a patched Version from original
# Tk::DialogBox, written by xpix
#
# - Show - new Option 'nograb'
# - check_callback new Option check_callback, return true and Window is close 
# - Focus($widget), set Focus on Widget
# - width and height for size from the dialogbox 
# - from_x and from_y for koordinates to open the dialog box 

package Tk::XDialogBox;

use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '3.032'; # $Id: //depot/Tk8/Tixish/DialogBox.pm#32 $

use base  qw(Tk::Toplevel);

Tk::Widget->Construct('XDialogBox');

sub Populate {
    my ($cw, $args) = @_;

    $cw->SUPER::Populate($args);
    my $buttons = delete $args->{'-buttons'};
    $buttons = ['OK'] unless defined $buttons;
    my $default_button = delete $args->{'-default_button'};
    $default_button = $buttons->[0] unless defined $default_button;
    my $check_cb = delete $args->{'-check_callback'};
    my $height = delete $args->{'-height'};
    my $width  = delete $args->{'-width'};
    $cw->{'selected_button'} = '';
#    $cw->transient($cw->Parent->toplevel);
#    $cw->withdraw;
    $cw->protocol('WM_DELETE_WINDOW' => sub {});

    # Patch: center from Mainwindow
    my $from_x = delete $args->{'-from_x'};
    my $from_y = delete $args->{'-from_y'};
    my ($p_posw, $p_posh, $p_posx, $p_posy) = split(/[x\+]/,$cw->MainWindow->geometry);    
    my $new_geometry = sprintf('%s+%d+%d', (defined $width and defined $height ? sprintf('%dx%d', $width, $height) : ''), int($p_posx + ($from_x || 50)), int($p_posy + ($from_y || 50)));
    $cw->geometry( $new_geometry );
    # --	

    # Patch: Close at Escape
    $cw->bind('<Escape>', sub{ $cw->destroy } );

   
    # create the two frames
    my $top = $cw->Component('Frame', 'top');
    $top->configure(-relief => 'raised', -bd => 1) unless $Tk::platform eq 'MSWin32';
    my $bot = $cw->Component('Frame', 'bottom');
    $bot->configure(-relief => 'raised', -bd => 1) unless $Tk::platform eq 'MSWin32';
    $bot->pack(qw/-side bottom -fill both -ipady 3 -ipadx 3/);
    $top->pack(qw/-side top -fill both -ipady 3 -ipadx 3 -expand 1/);

    # create a row of buttons in the bottom.
    my $bl;  # foreach my $var: perl > 5.003_08
    foreach $bl (@$buttons)
     {
	my $b = $bot->Button(
		-text => $bl, 
		-command => sub { 
				# Patch, new Option check_callback 
				if(defined $check_cb and ref $check_cb eq 'CODE' and &$check_cb($bl)) { 
					$cw->{'selected_button'} = "$bl"; 
				} elsif(! defined $check_cb) { 
					$cw->{'selected_button'} = "$bl"; 
				}
			},
		);
	$cw->Advertise("B_$bl" => $b);
        if ($Tk::platform eq 'MSWin32')
         {
          $b->configure(-width => 10, -pady => 0);
         }
	if ($bl eq $default_button) {
            if ($Tk::platform eq 'MSWin32') {
                $b->pack(-side => 'left', -expand => 1,  -padx => 1, -pady => 1);
            } else {
	        my $db = $bot->Frame(-relief => 'sunken', -bd => 1);
	        $b->raise($db);
	        $b->pack(-in => $db, -padx => '2', -pady => '2');
	        $db->pack(-side => 'left', -expand => 1, -padx => 1, -pady => 1);
            }
	    $cw->bind('<Return>' => [ $b, 'Invoke']);
	    $cw->bind('<KP_Enter>' => [ $b, 'Invoke']);
    	    $cw->bind('<Control-Return>', [ $b, 'Invoke'] );
    	    $cw->bind('<Control-KP_Enter>', [ $b, 'Invoke'] );
	    $cw->{'default_button'} = $b;
	} else {
	    $b->pack(-side => 'left', -expand => 1,  -padx => 1, -pady => 1);
	}
    }
    $cw->ConfigSpecs(-command    => ['CALLBACK', undef, undef, undef ],
                     -foreground => ['DESCENDANTS', 'foreground','Foreground', 'black'],
                     -background => ['DESCENDANTS', 'background','Background',  undef],
                    );
    $cw->Delegates('Construct',$top);
}

sub add {
    my ($cw, $wnam, @args) = @_;
    my $w = $cw->Subwidget('top')->$wnam(@args);
    $cw->Advertise("\L$wnam" => $w);
    return $w;
}

sub Focus {
	my $cw = shift;
	my $widget = shift || return $cw->{'focus'};
	$cw->{'focus'} = $widget;
}

sub Wait
{
 my $cw = shift;
 $cw->waitVariable(\$cw->{'selected_button'});
 $cw->grabRelease;
 $cw->withdraw;
 $cw->Callback(-command => $cw->{'selected_button'});
}

sub Show {
    my ($cw, $grab) = @_;
    croak 'DialogBox: "Show" method requires at least 1 argument'
	if scalar @_ < 1;
    my $old_focus = $cw->focusSave;
    my $old_grab = $cw->grabSave;

#    $cw->Popup();
    $cw->update;

    Tk::catch {
	    if (defined $grab && length $grab && ($grab =~ /global/)) {
		$cw->grabGlobal;
	    } elsif(defined $grab && length $grab && ($grab =~ /nograb/)) {
		# No Grab
	    } else {
		$cw->grab;
	    }
    };
    if (defined $cw->{'focus'}) {
	$cw->{'focus'}->focus;
    } elsif (defined $cw->{'default_button'}) {
	$cw->{'default_button'}->focus;
    } else {
	$cw->focus;
    }
    $cw->Wait;
    &$old_focus;
    &$old_grab;
    return $cw->{'selected_button'};
}

1;


=head1 NAME

Tk::XDialogBox - create and manipulate a dialog screen with added Features.

=for pm Tixish/DialogBox.pm

=for category Tix Extensions

=head1 SYNOPSIS

    use Tk::DialogBox
    ...
    $d = $top->DialogBox(
    	-title => "Title", 
    	-buttons => ["OK", "Cancel"],
	-check_callback => sub {
		my $answer = shift;
		if ( $answer eq 'OK') {
			error('Col1 must be a number!');
			return undef;
		} 
		return 1;
	  },
    	);
    $w = $d->add(Widget, args);
    $d->Focus(Widget); # set new Focus on a Widget    
    $button = $d->Show;

=head1 DESCRIPTION

B<DialogBox> is very similar to B<Dialog> except that it allows
any widget in the top frame. B<DialogBox> creates two
frames---"top" and "bottom". The bottom frame shows all the
specified buttons, lined up from left to right. The top frame acts
as a container for all other widgets that can be added with the
B<add()> method. The non-standard options recognized by
B<DialogBox> are as follows:

=head1 PATCHES

- Show - new Option 'nograb'

- check_callback new Option check_callback, return true and Window is close 

- Focus($widget), set Focus on Widget

- width and height for resize the dialogbox 

- from_x and from_y for coordinates to open the dialog box 


=head1 OPTIONS


=over 4

=item B<-title>

Specify the title of the dialog box. If this is not set, then the
name of the program is used.

=item B<-buttons>

The buttons to display in the bottom frame. This is a reference to
an array of strings containing the text to put on each
button. There is no default value for this. If you do not specify
any buttons, no buttons will be displayed.

=item B<-default_button>

Specifies the default button that is considered invoked when user
presses <Return> on the dialog box. This button is highlighted. If
no default button is specified, then the first element of the
array whose reference is passed to the B<-buttons> option is used
as the default.

=item B<-check_callback>

Option check_callback, this will run the subroutine when submit ever 
button. The callback have one Parameter, the buttontext. If the return undef, 
then the dialogbox will not close. 

  -check_callback => sub {
	my $answer = shift;
	if ( $answer eq 'Save') {
		error('Col1 must be a number!');
		return undef;
	} 
	return 1;
  },

=item B<-width>

Width in pixel.

=item B<-heigth>

Heigth in pixel.

=item B<-from_x>

Specifies the Coordinates to place 
the dialogbox in the screen. It is default 50.

=item B<-from_y>

Specifies the Coordinates to place 
the dialogbox in the screen. It is default 50.


=back

=head1 METHODS

B<DialogBox> supports only two methods as of now:

=over 4

=item B<add(>I<widget>, I<options>B<)>

Add the widget indicated by I<widget>. I<Widget> can be the name
of any Tk widget (standard or contributed). I<Options> are the
options that the widget accepts. The widget is advertized as a
subwidget of B<DialogBox>.

=item B<Show(>I<grab>B< or -nograb)>

Display the dialog box, until user invokes one of the buttons in
the bottom frame. If the grab type is specified in I<grab>, then
B<Show> uses that grab; otherwise it uses a local grab. With -nograb switch off the grabbing
Returns the name of the button invoked.

=item B<Focus(>I<widget>B<)>

Set the focus on the widget and not on the defaultbutton.

=back

=head1 BINDINGS

=item Escape

close the Dialogbox

=item Return and KP_Enter

Submit the first Button

=item <Control-Return> and <Control-KP_Enter>

Submit the first Button


=head1 BUGS

There is no way of removing a widget once it has been added to the
top frame.

There is no control over the appearance of the buttons in the
bottom frame nor is there any way to control the placement of the
two frames with respect to each other e.g. widgets to the left,
buttons to the right instead of widgets on the top and buttons on
the bottom always.

=head1 AUTHOR

B<Rajappa Iyer> rsi@earthling.net

This code is distributed under the same terms as Perl.

Patched and additional features by Frank (xpix) Herrmann

=cut

