package Tk::TOTD;

use strict;
use warnings;
use Tk;
use Tk::ROText;
use Tk::DialogBox;
use Tk::Widget;

our $VERSION = '0.5';

Tk::Widget->Construct ('TOTD');

sub new {
	my $proto = shift;
	my $mw = shift;
	my $class = ref($proto) || $proto || 'Tk::TOTD';

	my $self = {
		mw     => $mw,
		dialog => undef,
		@_,
	};

	bless ($self,$class);
	return $self;
}

sub Show {
	my ($args) = @_;

	my $self = $args->{mw}->DialogBox (
		-title      => $args->{'-title'} || 'Tip Of The Day',
		-background => $args->{'-background'} || '#BFBFBF',
		-buttons    => [],
	);
	$self->geometry ('460x260');
	$self->resizable (0,0);

	# Keep a reference to get back to it later.
	$args->{dialog} = $self;

	my $header = $args->{'-slogan'} || 'Did you know that...',

	my $totd;
	if (exists $args->{'-image'}) {
		$totd = $args->{'-image'};
	}
	else {
		$totd = $self->Photo (-data => &hint, -format => 'gif');
	}

	my @messages = (
		'This is the Tk::TOTD module, for incorporating Tip Of The Day '
			. 'functionality into any Perl/Tk program!',
		"As you can see,\n\neven if your messages are\n\nVERY,\nVERY\n\n"
			. "long,\n\na scrollbar is made available to see the rest\n\n"
			. "of the contents\n\nof your tip!",
		'If all tips are displayed, the queue starts over again to make the '
			. 'tip rotation infinite.',
		'If you use B<-checkvariable> you can have your program allow the user '
			. 'to choose whether he/she wants to have your Tip Of The Day '
			. 'pop up on every startup.',
		'You can have as many tips as you like.',
		'You can incorporate TOTD into a program with only one function call!',
		'You can customize all the colors and fonts used in this dialog window--'
			. 'even the labels such as "Did you know that..." and "Show tips '
			. 'at startup"!',
		'The messages are displayed randomly each time you spawn a TOTD window.',
		'The number of the tip you are viewing and the whole number of tips is '
			. 'displayed in the lower left edge of the window. This is to '
			. 'help you keep track of which tips you have read and to know how '
			. 'many to expect!',
		'There are 10 tips here--so there\'s plenty for you to read!',
	);

	if (exists $args->{'-messages'}) {
		@messages = @{$args->{'-messages'}};
	}

	$self->{colors} = {
		bg    => $args->{'-background'} || '#BFBFBF',
		left  => $args->{'-leftbackground'} || '#808080',
		main  => $args->{'-mainbackground'} || '#FFFFFF',
		slide => $args->{'-slidecolor'}     || '#FFFF99',
		fg    => $args->{'-foreground'}     || '#000000',
	};
	$self->{fonts} = {
		main => {
			family => $args->{'-mainfont'} || 'Arial',
			size   => $args->{'-mainfontsize'} || 10,
		},
		title => {
			family => $args->{'-titlefont'} || 'Times New Roman',
			size   => $args->{'-titlefontsize'} || 14,
		},
	};

	my $top = $self->Frame (
		-width      => 440,
		-height     => 200,
		-background => $self->{colors}->{bg},
	);
	my $bot = $self->Frame (
		-height     => 40,
		-width      => 440,
		-background => $self->{colors}->{bg},
	);
	$bot->pack (-side => 'bottom', -fill => 'both', -ipady => 3, -ipadx => 3);
	$top->pack (-side => 'top', -fill => 'both', -pady => 10, -padx => 10, -expand => 1);

	my $pan = $top->Frame (
		-width      => 60,
		-height     => 200,
		-border     => 0,
		-background => $self->{colors}->{left},
	)->pack (-side => 'left', -fill => 'y', -pady => 0, -padx => 0, -expand => 1);

	$pan->Label (
		-image      => $totd,
		-background => $self->{colors}->{left},
	)->place (-x => 15, -y => 10);

	my $pos = $pan->Label (
		-text       => "1/" . scalar(@messages),
		-foreground => $self->{colors}->{slide},
		-background => $self->{colors}->{left},
		-font       => [
			-family => $self->{fonts}->{main}->{family},
			-size   => $self->{fonts}->{main}->{size},
			-weight => 'bold',
		],
	)->place (-x => 15, -y => 170);

	my $main = $top->Frame (
		-width      => 380,
		-height     => 200,
		-border     => 0,
		-background => $self->{colors}->{main},
	)->pack (-side => 'right', -fill => 'both', -pady => 0, -padx => 0, -expand => 1);

	my $ttab = $main->Frame (
		-width      => 380,
		-height     => 50,
		-border     => 0,
		-background => $self->{colors}->{main},
	)->pack (-side => 'top', -fill => 'x', -pady => 0, -padx => 0, -expand => 1);

	my $title = $ttab->Label (
		-text       => $header,
		-foreground => $self->{colors}->{fg},
		-background => $self->{colors}->{main},
		-font       => [
			-family => $self->{fonts}->{title}->{family},
			-size   => $self->{fonts}->{title}->{size},
			-weight => 'bold',
		],
	)->place (-x => 25, -y => 10);

	my $mtab = $main->Frame (
		-width      => 380,
		-height     => 125,
		-border     => 0,
		-background => $self->{colors}->{main},
	)->pack (-side => 'bottom', -fill => 'both', -pady => 0, -padx => 0, -expand => 1);

	my $pod = $mtab->Scrolled ('ROText',
		-foreground => $self->{colors}->{fg},
		-background => $self->{colors}->{main},
		-scrollbars => 'e',
		-wrap       => 'word',
		-relief     => 'flat',
		-font       => [
			-family => $self->{fonts}->{main}->{family},
			-size   => $self->{fonts}->{main}->{size},
		],
	)->pack (-fill => 'both', -expand => 1);

	my $void = 1;

	my $bl = $bot->Frame (
		-height     => 40,
		-background => $self->{colors}->{bg},
	);
	my $br = $bot->Frame (
		-height     => 40,
		-background => $self->{colors}->{bg},
	);
	$bl->pack (-side => 'left', -fill => 'both', -ipady => 0, -ipadx => 0, -expand => 1);
	$br->pack (-side => 'right', -fill => 'both', -ipady => 0, -ipadx => 0, -expand => 1);

	my $checkbox = $bl->Checkbutton (
		-text       => $args->{'-checklabel'} || 'Show tips at startup',
		-variable   => $args->{'-checkvariable'} || \$void,
		-foreground => $self->{colors}->{fg},
		-background => $self->{colors}->{bg},
		-activeforeground => $self->{colors}->{fg},
		-activebackground => $self->{colors}->{bg},
		-onvalue    => 1,
		-offvalue   => 0,
		-font       => [
			-family => $self->{fonts}->{main}->{family},
			-size   => $self->{fonts}->{main}->{size},
		],
	)->place (-x => 10, -y => 15);

	# Shuffle the messages array.
	srand;
	my @new = ();
	while (@messages) {
		push (@new, splice (@messages, rand @messages, 1));
	}
	(@messages) = (@new);

	# Begin keeping track of things.
	my $index = 0;
	$pod->insert ('end',$messages[0]);

	my $close = $br->Button (
		-text       => $args->{'-closebutton'} || 'Close',
		-foreground => $self->{colors}->{fg},
		-background => $self->{colors}->{bg},
		-activeforeground => $self->{colors}->{fg},
		-activebackground => $self->{colors}->{bg},
		-font       => [
			-family => $self->{fonts}->{main}->{family},
			-size   => $self->{fonts}->{main}->{size},
		],
		-command    => sub {
			$self->{'selected_button'} = 'Close';
		},
	)->pack (-side => 'right', -padx => 10);

	my $next = $br->Button (
		-text       => $args->{'-nextbutton'} || 'Next Tip',
		-foreground => $self->{colors}->{fg},
		-background => $self->{colors}->{bg},
		-activeforeground => $self->{colors}->{fg},
		-activebackground => $self->{colors}->{bg},
		-font       => [
			-family => $self->{fonts}->{main}->{family},
			-size   => $self->{fonts}->{main}->{size},
		],
		-command    => sub {
			$index++;
			my $num = $index + 1;

			if ($num > scalar(@messages)) {
				$num = 1;
				$index = 0;
			}

			$pos->configure (-text => "$num/" . scalar(@messages));

			my $data = $messages[$index];
			$pod->delete ('1.0','end');
			$pod->insert ('end',$data);
			$pod->insert ('end',"\n");
			$self->update;
		},
	)->pack (-side => 'right', -padx => 5);

	$self->Show;
}

sub configure {
	my ($cw,%args) = @_;

	foreach my $arg (keys %args) {
		$cw->{$arg} = $args{$arg};
	}
}

sub hint {
	return 'R0lGODlhFwAfAOYAAAAAAICAAP//AAD//8DAwP///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///yH5
BAEAAH8ALAAAAAAXAB8AAAfVgH+Cg4SFhoeEAYqKiIiKApCQjI2DAQIFl5mYAZR/lgWgfwB/mJCj
jpegBQCsmgKnhgGqoKwAmKWwiamqta4BuYKfs6KkmQK/sbeztr7AnpG3r67Hzpau0dHIhgCRl8Sl
1IgA1pi9t9qH45HEkeiHA+rXv/CIA6vW3dQF9IX2tI+SfqniJ8hfKFaLas2iB8BgKFqsCBCwtXBU
w2GiCkhUOBDWRVWkak2sWOhjAUEaJ1Lc50yUwVqsOjYyyZFlJ5MkO7mcZVOnIJMEfe4MKtRlS6FH
BwUCADs=
';
}

sub Exit {
	my $cw = shift;

	undef $cw;
}

sub destroy {
	my $self = shift;

	if ($self->{dialog}) {
		$self->{dialog}->{selected_button} = 'Close';
	}
}

=head1 NAME

Tk::TOTD - Tip Of The Day dialog for Perl/Tk.

=head1 SYNOPSIS

  use Tk::TOTD;

  my $top = MainWindow->new();

  my $totd = $top->TOTD (
    -title    => 'Tip Of The Day -- MyPerlApp',
    -messages => \@messages,
  );

  $totd->Show;

=head1 DESCRIPTION

Tk::TOTD provides a simple Tip of the Day dialog for Perl/Tk programs.

=head1 OPTIONS

The options recognized by B<Show> are as follows:

=over 4

=item B<-title>

Specify the title of the Tip Of The Day dialog. Defaults to "Tip Of The Day"

=item B<-messages>

The array of tip messages. If omitted, a default 10 tips about this module
will be used instead.

=item B<-slogan>

Set the slogan at the top of the dialog. Default is "Did you know that..."

=item B<-image>

A L<Tk::Photo> object. If omitted, the default totd image is used. This default
image is appropriate for most TOTD usages, but if you use this as something other
than a Tip Of The Day you may want to use your own image. The default image's
dimensions are B<23x31>.

=item B<-background>

The main window's background color. Defaults to #BFBFBF

=item B<-leftbackground>

Background color for the left panel (where the image and slide number is). Defaults
to #808080

=item B<-mainbackground>

The background color of the main content area. Defaults to #FFFFFF (white).

=item B<-slidecolor>

The text color of the slide number (as on the left panel). Defaults to #FFFF99.

=item B<-foreground>

Main foreground color of text. Defaults to #000000 (black).

=item B<-mainfont>

The main font family used on most of the labels. Defaults to Arial.

=item B<-mainfontsize>

Font size of the main font. Defaults to 10.

=item B<-titlefont>

The font family used on the slogan text. Defaults to Times New Roman.

=item B<-titlefontsize>

Font size on the slogan text. Defaults to 14.

=item B<-checklabel>

The label on the checkbutton. Defaults to "Show tips at startup"

=item B<-checkvariable>

The variable to store the state of the checkbutton. 1 for checked, 0 for not.

=item B<-closebutton>

The text of the close button. Defaults to "Close"

=item B<-nextbutton>

The text of the next button. Defaults to "Next Tip"

=back

=head1 METHODS

=over 4

=item B<Show (? options ?)>

Displays the Tip Of The Day dialog. The TOTD dialog is based from Tk::DialogBox
and therefore will pause your main window.

=item B<configure (? options ?)>

Reconfigure previously set options.

=item B<destroy ()>

Completely clean up the TOTD DialogBox. This method is a workaround for an
underlying bug in C<Tk::DialogBox> wherein if a DialogBox is open, and you
close the C<MainWindow> by clicking on the "X" button from the window manager,
your program doesn't exit completely because the DialogBox is waiting on a
variable that's only set when a button has been clicked.

You can work around this bug by calling C<destroy()> on your C<Tk::TOTD>
object when your C<MainWindow> is exited.

  $mw->protocol('WM_DELETE_WINDOW', sub {
    $totd->destroy();
    exit(0);
  });

=back

=head1 CHANGES

  Version 0.5 - Sep 18 2015
  - Add dependency on Tk modules.

  Version 0.4 - Nov 11 2013
  - Add the destroy() method to allow for a workaround to a bug in
    Tk::DialogBox.

  Version 0.3 - Nov  1 2013
  - Fix a bug where using the "Close" button on the dialog wouldn't dismiss the
    dialog properly, and the program would never exit gracefully again.

  Version 0.2 - Jan 16 2005
  - The widget now behaves as a DialogBox as it should, blocking the main window
    until closed.

=head1 BUGS

None known yet.

=head1 AUTHOR

Noah Petherbridge, http://www.kirsle.net/

This code is distributed under the same terms as Perl.

=cut

1;
