################################################################################
# Tk::StyleDialog - Stylish Dialogboxes with Custom Icons		       #
################################################################################
package Tk::StyleDialog;

use strict;
use warnings;
use Tk;
use Tk::Toplevel;
use Tk::PNG;
use Tk::Widget;

our $VERSION = '0.04';
Tk::Widget->Construct ('StyleDialog');

# CORE Built-in icons.
# attention, error, info, question
our $BUILTIN_ICONS = {
	'attention' => 'iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAAG/biZnAAAAElBMVEUAAACAgACZmZnAwMD//wAA
AABjkWUwAAAAAXRSTlMAQObYZgAAAPNJREFUKM9lkEsOgzAMRA3KAVrJ7KOcoAvYV2DvEU3uf5X6
BwqtJZAZXjzjAGi9AVKTpwKMxZS0Q3oDsX0Pq0pYs7Q0y0ci2jLASco/JZjlP1OGtNEOyLQCkbzG
UmxoesURkeN04rqGxNXFpN3qlFZ2u0omNqtymkfhfk2OcRKUT4/LDZf5CKyF7yAdh++EDiIx0eEJ
2G0Hi8KeRfIpiNLNBqInlW6IfAC2demCPh/wE5q24yaoyVLuiGx+5DtyhyRsaz0kiCodhKFckE7Z
2qebZBtMnV0s3Nn5kouecsgR0skBhRLFJV9XQ37KrsMv5iz4ry/n4U7to4iyMAAAAABJRU5ErkJg
gg==',
	'error' => 'iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAAG/biZnAAAAD1BMVEUAAAD/AACZmZn///9gAADt
zF8pAAAAAXRSTlMAQObYZgAAAPVJREFUKM9dko2twyAMhGmUAd4BAyD0FrBYoETsP1PPP7RNLSVx
Ps7mcJIS4wFe0uyZmpKEmoA0s70DTwpKgd9JJnryOGHF+EsYwqLC25SR2QxZS6k+WiiXlUxoGBmC
oTKKxwBq80w0O1HgqwptkXGs1Vu6xzKDvkWktkXdSNTFg83K0OVJl9wjmxXdNzKJrARjhRTB5bWw
LDr3fY6sZo6Nbv6Ob6OL8e3Zh2AWP9Y9njfF5+gE9A83Wt9k+MTMgHUhMgD1631LAFwtiGpuhIri
6GoxGIn2VQ9y2hy1l0r6r8M469pg9f2H/Btb1xvoZCx+v2PEC2oELiZOaMTkAAAAAElFTkSuQmCC',
	'info' => 'iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAAD1BMVEVlYXIAAP+ZmZn///8AAADI
hm6AAAAAAXRSTlMAQObYZgAAAAFiS0dEAIgFHUgAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElN
RQfVAQUJAhHTzodBAAAAn0lEQVQoz63S0Q3EIAgAUGNcgNwChusCrQ5wUfef6UQQzHn9Kx9tfEGi
oHM3gT3WtcfUA6PBO424lAQ6zRRaAND3YyknwKv/sqWIcBJX4V2cpHWHRNlkUaaA1DFJKvEx0RMO
yfhX/CpldLLyCYky9zYsd5DOVr3nbH8QykWbfzSCVmxCHlulLet88CCJ6xBJfuZcNwmbuLaJx/3F
3D2lL2ZNO/7TbRBBAAAAAElFTkSuQmCC',
	'question' => 'iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAAD1BMVEVlYXIAAP+ZmZn///8AAADI
hm6AAAAAAXRSTlMAQObYZgAAAAFiS0dEAIgFHUgAAAAJcEhZcwAACy8AAAsTAXMiW84AAAAHdElN
RQfVAQUINxbuWbpjAAAAp0lEQVQoz4XS0Q3EIAgGYGNcgLiA4bpAiwNc1P1nOrQIpqY5Xpp++dEU
6txLIdf67pG4MBl8aNSlJMA0I6T1tcgJEPmRLRIJQEMjEjmlobspiiRpUqEybwI5x0SOYUkm9JT4
X2axyHdKJqOKXD7Er1LGJKt15Xu2YTlXJlsn5Dn+IJSLDv9oHVqxDXlstbes+8GjS1qX2OWx57pJ
2MS1TTzuf8zbr/QD5Iw9gr+vgAwAAAAASUVORK5CYII=',
};

sub new {
	my $proto = shift;
	my $mw = shift;
	my $class = ref($proto) || $proto || 'Tk::StyleDialog';

	my $self = {
		mw => $mw,
		@_,
	};

	bless ($self,$class);
	return $self->Show;
}

sub Show {
	my ($args) = @_;

	# Args:
	# mw = parent window
	# -title	  = Dialog Title
	# -text	          = Dialog message text
	# -icon	          = The icon to use inside the dialog
	# -buttons        = Arrayref of button labels
	# -default_button = The default button
	# -button_states  = Arrayref of button states (normal|disabled)

	# Prepare default arguments.
	my $title   = 'Error';
	my $text    = 'An error has occurred.';
	my $icon    = 'error';
	my $center  = 1;
	my $winicon = 'error';
	my $winmask = 'error';
	my $buttons = [ '  Ok  ' ];
	my $default_button = undef;
	my $cancel_button = undef;
	my $button_states  = [];
	my $standalone = 0;
	my $grab = '';

	# Collect args.
	$title = delete $args->{'-title'} if exists $args->{'-title'};
	$text  = delete $args->{'-text'}  if exists $args->{'-text'};
	$icon  = delete $args->{'-icon'}  if exists $args->{'-icon'};
	$center  = delete $args->{'-center'} if exists $args->{'-center'};
	$winicon = delete $args->{'-winicon'} if exists $args->{'-winicon'};
	$winmask = delete $args->{'-winmask'} if exists $args->{'-winmask'};
	$buttons = delete $args->{'-buttons'} if exists $args->{'-buttons'};
	$default_button = delete $args->{'-default_button'} if exists $args->{'-default_button'};
	$cancel_button  = delete $args->{'-cancel_button'} if exists $args->{'-cancel_button'};
	$button_states  = delete $args->{'-button_states'} if exists $args->{'-button_states'};
	$standalone = delete $args->{'-standalone'} if exists $args->{'-standalone'};
	$grab = delete $args->{'-grab'} if exists $args->{'-grab'};

	# Default default button = the first button.
	$default_button = $buttons->[0] unless defined $default_button;

	# Default cancel button = the last button.
	$cancel_button = $buttons->[-1] unless defined $cancel_button;

	# Internal variables.
	my $selectedbutton = undef;

	#######################################################
	## Create the Dialog Window                          ##
	#######################################################

	# Create the window.
	my $win = $args->{mw}->Toplevel (
		-title => $title || 'Error',
	);

	# Handle the clicking of the "X" button.
	$win->protocol ('WM_DELETE_WINDOW' => sub {
		$selectedbutton = $cancel_button;
	});

	# Handle keypresses.
	$win->bind ('<Return>', sub {
		$selectedbutton = $default_button;
	});
	$win->bind ('<space>', sub {
		$selectedbutton = $default_button;
	});
	$win->bind ('<Escape>', sub {
		$selectedbutton = $cancel_button;
	});

	# Unless standalone, make it a child of the main window.
	unless ($standalone) {
		$win->transient ($win->Parent->toplevel);
	}

	# Divide the window into frames.
	my $bottom_frame = $win->Frame->pack (-side => 'bottom', -fill => 'x');
	my $top_half     = $win->Frame->pack (-side => 'bottom', -fill => 'both', -expand => 1);
	my $icon_frame   = $top_half->Frame->pack (-side => 'left', -fill => 'y');
	my $label_frame  = $top_half->Frame->pack (-side => 'left', -fill => 'both', -expand => 1);
	my $button_frame = $bottom_frame->Frame->pack (-side => 'top', -fill => 'y');

	#######################################################
	## Button Frame			                     ##
	#######################################################

	# Draw the window buttons.
	for (my $i = 0; $i < scalar @{$buttons}; $i++) {
		my $label = $buttons->[$i];

		# Get this button's state.
		my $state = 'normal';
		if (scalar @{$button_states} > $i) {
			$state = (defined $button_states->[$i] ? $button_states->[$i] : 'normal');
		}

		# If this is the default button, draw a border around it.
		if ($label eq $default_button) {
			my $border = $button_frame->Frame (
				-background => '#000000',
			)->pack (-side => 'left', -padx => 10, -pady => 10);
			my $btn = $border->Button (
				-text    => $label,
				-state   => $state,
				-command => sub {
					$selectedbutton = $label;
				},
				-highlightthickness => 0,
			)->pack (-side => 'top', -padx => 1, -pady => 1);
		}
		else {
			my $btn = $button_frame->Button (
				-text    => $label,
				-state   => $state,
				-command => sub {
					$selectedbutton = $label;
				},
				-highlightthickness => 0,
			)->pack (-side => 'left', -padx => 10, -pady => 10);
		}
	}

	#######################################################
	## Icon Frame				             ##
	#######################################################

	# If they gave us a Photo object, use it.
	my $photo = undef;
	if (ref($icon)) {
		$photo = $icon;
	}
	else {
		# Get the internal one. Does it exist?
		if (!exists $BUILTIN_ICONS->{$icon}) {
			# Load Tk::StyleDialog::Builtins.
			require Tk::StyleDialog::Builtins;
		}
		$icon = 'error' unless exists $BUILTIN_ICONS->{$icon};

		if (exists $BUILTIN_ICONS->{$icon}) {
			$photo = $win->Photo (
				-data   => $BUILTIN_ICONS->{$icon},
				-format => 'PNG',
				-width  => 34,
				-height => 34,
			);
		}
	}

	my $iconimg = $icon_frame->Label (
		-image  => $photo,
		-border => 0,
	)->pack (-side => 'top', -pady => 10, -padx => 20);

	#######################################################
	## Label Frame			                     ##
	#######################################################

	my $label = $label_frame->Label (
		-text => $text,
		-justify => 'left',
	)->pack (-side => 'top', -anchor => 'nw', -pady => 20, -padx => 10);

	# Update the window to get realistic dimensions.
	$win->withdraw;
	$win->update;

	# Center the window?
	if ($center) {
		my $screenwidth = $args->{mw}->screenwidth;
		my $screenheight = $args->{mw}->screenheight;
		my $posX = ($screenwidth - $win->width) / 2;
		my $posY = ($screenheight - $win->height) / 2;
		$win->MoveToplevelWindow (int($posX),int($posY));
	}

	# Set the minsize to be its default size.
	$win->minsize ($win->width,$win->height);

	# Set the app icon.
	$win->Icon (-image => $photo);

	$win->deiconify;

	# Grab.
	if ($grab eq 'global') {
		$win->grabGlobal;
	}
	else {
		$win->grab;
	}

	# Wait for a button.
	$win->focusForce;
	$win->waitVariable (\$selectedbutton);
	$win->destroy;

	# Return the selected button.
	return $selectedbutton;
}

1;
__END__

=head1 NAME

Tk::StyleDialog - Stylish dialog boxes with custom icons.

=head1 SYNOPSIS

  use Tk::StyleDialog;

  my $how_say_you = $mw->StyleDialog (
    -title => 'Uh-oh!',
    -icon  => 'error2',
    -text  => "Now you've done it--you've broken the Internet!\n\n"
            . "What are you going to do now?",

    -buttons        => [ 'Blame the other guy', 'I didn\'t do it',
                         'Plead the 5th', 'Admit guilt' ],
    -button_states  => [ 'normal', 'normal', 'normal', 'disabled' ],
    -default_button => 'Blame the other guy',
    -cancel_button  => 'Plead the 5th',
  );

=head1 DESCRIPTION

Tk::StyleDialog adds a fun drop-in replacement to the standard Tk dialog boxes.
They look like your standard system dialog box, but with customizable icons and
buttons. The module comes with a handful of built-in PNG images, from various
generations of the standard C<error, warning, info,> and C<question> icons to
more familiar icons such as floppy disks, computers, Defragmenter, Control Panel,
MSN Butterfly, and Macintosh Apple.

The built-in icon images were obtained from Atom Smasher's Error Message
Generator (L<"SEE ALSO">).

=head1 OPTIONS

=over 4

=item -title

The title of the dialog box. Default is "Error"

=item -text

The text of the dialog message. Default is "An error has occurred."

=item -icon

Name of a built-in icon or an already existing C<Tk::Photo> object.

=item -buttons

Array of button labels.

=item -default_button

The default button has a darker border around it, and is automatically selected
if the user hits the C<Return> key. By default, the default button is the first
button in your list. Specify the label of the default button here to override that.

=item -cancel_button

The cancel button is the default button that is returned if the user hits the
C<Escape> key, or closes the dialog via the window manager's "Close" button. The
default cancel button is the very last button in your list, or set the cancel
button to match the label of another button to override that.

=item -button_states

This is an array of the states for your buttons. The order of this array has to
line up with the order of C<-buttons>. Each element should be either C<normal>
or C<disabled>. An C<undef> value is assumed to be C<normal>.

=item -standalone

By default, the dialog window will be treated as a C<transient> window to the
window that called it. Until the dialog is cleared, input to its parent window
isn't allowed. This is suitable for most cases, but if you want the dialog to be
its own standalone Toplevel, set C<-standalone> to be 1.

=item -center

Center the window in the middle of your screen. By default, C<-center> is 1,
because a dialog box appearing in the middle of the screen seems to be standard
among all programs that summon dialog boxes. It gets a little tricky with
dual monitors, though, because C<Tk::screenwidth> and C<Tk::screenheight> will
report the combined dimensions of all monitors. This behavior was noted on Linux
with an NVIDIA graphics card and might not be true of all dual monitor setups.

If you'd prefer that your dialog doesn't center itself on the screen, set
C<-center> to be C<0>.

=item -grab

Set C<-grab> to equal C<global> for the dialog window to have a global grab over
the user's entire desktop, preventing all input to their desktop until the dialog
box has been answered. Note that system events won't be blocked by the global grab,
such as the three finger salute to Microsoft or the X Server events. The default
behavior is to only grab control away from the parent program.

=back

=head1 BUILT-IN ICONS

Four generic icons are built into the module: attention, error, info, and question.
The icons are base64-encoded in C<Tk::StyleDialog>. Additional icons from Atom
Smasher's collection are loaded only when one of them is called for the first time.

The module C<Tk::StyleDialog::Builtins> contains the base64 data for every icon in
Atom Smasher's set, whereas C<Tk::StyleDialog> alone only contains the four generic
icons. C<Tk::StyleDialog::Builtins> will be dynamically loaded if you reference a
built-in icon outside of the default four.

You can create your own built-in icons in a sub-class by modifying the data structure
at C<$Tk::StyleDialog::BUILTIN_ICONS>, for example:

  $Tk::StyleDialog::BUILTIN_ICONS->{"attention"} = $base64_data;

This is a full breakdown of the built-in icons, including the four default icons
and the entire collection from C<Tk::StyleDialog::Builtins>.

  aim_guy         - Blue AIM guy icon
  aol_icon        - Blue AOL icon
  attention       - Yellow triangle around an exclamation mark
  bomb            - Round black bomb icon
  bomb_dynamite   - Icon of a bundle of dynamite and a trigger
  bomb_grenade    - Icon of a grenade
  bulb            - White light bulb
  butterfly       - MSN Butterfly icon
  cake            - Slice of pink cake on a blue plate
  circularsaw     - Icon of a handheld circular saw
  control_panel   - Generic control panel icon
  cow             - Icon of a cow and a computer tower
  defrag          - Disk Defragmenter icon
  disk_blue       - Generic blue floppy disk icon
  disk_blue_label - Blue floppy disk with a label
  disk_orange     - Generic orange floppy disk
  disk_red        - Generic red floppy disk
  disk_red_label  - Red floppy disk with a label
  disk_skull      - Gray floppy disk with skull and crossbones emblem on it
  disk_yellow     - Generic yellow floppy disk
  error           - Old-school X in a red circle error dialog icon (like Win 95)
  error2          - Modern, shiny incarnation of an error dialog icon
  error3          - Beveled error dialog icon (like Windows XP)
  error4          - A red X icon
  file_cabinet    - File cabinet icon
  find            - Find Files icon
  floppy_drive    - Generic floppy drive icon
  fortunecookie   - Icon of a fortune cookie
  garbage_empty   - Empty garbage can
  garbage_full    - Bloated garabage can
  gun             - Icon of a revolver pistol
  hammer          - Icon of a hammer
  heart           - Icon of a shiny red heart
  help            - Old-school Windows Help icon
  hub             - Icon of a hardware hub of sorts (networking?)
  hwinfo          - Icon of a PCI device with blue "i" bubble above it
  ie5             - Icon of old-school Internet Explorer
  info            - Speech bubble with an "i" inside
  keys            - Generic icon of keys
  keys2           - Old Windows key icon
  keys3           - Generic key and padlock icon
  labtec          - Icon of a server or something?
  mac             - Striped colorful Apple logo
  mail            - Generic icon of an envelope
  mail_deleted    - Same envelope with a red X emblem in the corner.
  mailbox         - Mailbox with the flag down
  mouth           - Smiling mouth icon
  msdos           - MS-DOS icon
  mycomputer      - A "My Computer" icon
  mycomputer2     - A "My Computer" icon
  mycomputer3     - A "My Computer" icon
  newspaper       - Generic newspaper icon
  peripheral      - Generic computer peripheral icon
  plant_leaf      - A certain green leafy plant
  pocketknife     - A swiss army pocket knife
  question        - Icon of a speech bubble with a "?" inside
  radiation       - Yellow and black radiation symbol
  ram             - Icon of a couple sticks of RAM
  recycle         - Green recycle arrows logo
  recycle2        - Recycle arrows enveloping a globe of Earth
  scanner         - Generic scanner icon
  screw           - Golden screw icon
  screw2          - Gray screw icon
  setup           - Generic icon for "setup.exe" type programs
  skull           - Black skull and crossbones
  skull2          - Picture of a skull
  skull3          - White skull and crossbones
  tux             - Icon of our favorite Linux mascot
  tux_config      - Tux dressed up like a repairman
  ups             - Icon of an uninterruptible power supply
  zipdisk         - Icon of a single zip disk
  zipdisks        - Icon of numerous zipdisks

=head1 METHODS

B<StyleDialog> doesn't have any methods. Creating a new StyleDialog automatically
calls the C<Show()> method, which takes the same arguments as the constructor. In
other words, don't worry about it.

=head1 ADVERTISED WIDGETS

No advertised widgets. The constructor and C<Show()> should grab control of your
program until the dialog is dismissed.

=head1 BUGS

To be discovered.

If anyone has any objection to the use of trademarked icons used in the
built-in collection, they'll have to be removed. To that end I'd probably
recommend that if the use of a particular icon is absolutely crucial to your
program that you include it with your program and pass in a Tk::Photo object
instead.

=head1 CHANGES

  0.04  Sep 24 2008
  - Fixed Makefile.PL to name Tk and Tk::PNG as dependencies (to stop being
    nagged by CPAN test failures :P)

  0.03  Sep 19 2008
  - Fixed a bug with "-grab => global" not working properly.

  0.02  Sep 19 2008
  - Added a binding so that the space bar invokes the default button in addition
    to just the return key.
  - Added an option of `-center => 0` to stop the default behavior of centering
    the dialog box on-screen.
  - Fixed the Makefile so it doesn't require Perl 5.10 :)

  0.01  Sep 18 2008
  - Initial release.

=head1 SEE ALSO

Atom Smasher's Error Message Generator, from which all the builtin icons were
obtained. http://atom.smasher.org/error/

=head1 AUTHOR

Casey Kirsle, http://www.cuvou.com/

This code is distributed under the same terms as Perl itself. The icon set was
downloaded from Atom Smasher's Error Message Generator, so see the author there
for additional information about the icons.

=cut

1;
