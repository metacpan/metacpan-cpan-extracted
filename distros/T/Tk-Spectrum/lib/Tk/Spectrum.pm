package Tk::Spectrum;

use strict;
use warnings;
use Tk;
use Tk::PNG;
use Tk::DialogBox;
use Tk::Widget;
use Tk::LabFrame;

our $VERSION = '0.02';

Tk::Widget->Construct ('Spectrum');

sub new {
	my $proto = shift;
	my $mw = shift;
	my $class = ref($proto) || $proto || 'Tk::Spectrum';

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
	# -title        = Dialog title
	# -initialcolor = Initial/Default Color
	# -buttons      = [ 'Ok', 'Cancel' ]
	my $btnOkay = 'Ok';
	my $btnCancel = 'Cancel';
	my $initColor = exists $args->{'-initialcolor'} ? $args->{'-initialcolor'} : '#FFFFFF';
	$args->{selectedbtn} = '';
	$args->{selectedcolor} = $initColor;
	$args->{redval} = 0;
	$args->{grnval} = 0;
	$args->{bluval} = 0;
	$args->{hexval} = $initColor;
	my $presets = [
		# Two rows: 9 on top, 9 on bottom.
		[
			'#FFFFFF', # White
			'#CCCCCC', # Light Grey
			'#FF0000', # Red
			'#FF9900', # Orange
			'#FFFF00', # Yellow
			'#00FF00', # Lime Green
			'#00FFFF', # Cyan
			'#0000FF', # Blue
			'#FF00FF', # Magenta
			'#FF9999', # Pastel Red
			'#99FF99', # Pastel Green
		],
		[
			'#000000', # Black
			'#999999', # Dark Grey
			'#990000', # Dark Red
			'#996600', # Brown
			'#999900', # Gold
			'#009900', # Green
			'#009999', # Teal
			'#000099', # Dark Blue
			'#990099', # Purple
			'#9999FF', # Pastel Blue
			'#FFFF99', # Pastel Yellow
		],
	];
	if (exists $args->{'-preset'}) {
		$presets = [];
		foreach my $row (@{$args->{'-preset'}}) {
			if (defined $row && ref($row) eq 'ARRAY') {
				push (@{$presets}, $row);
			}
			else {
				warn "Invalid -preset syntax for Tk::Spectrum\n";
			}
		}
	}
	if (exists $args->{'-buttons'}) {
		if (scalar @{$args->{'-buttons'}} == 1) {
			$btnOkay = $args->{'-buttons'}->[0];
		}
		elsif (scalar @{$args->{'-buttons'}} >= 2) {
			$btnOkay = $args->{'-buttons'}->[0];
			$btnCancel = $args->{'-buttons'}->[1];
		}
	}

	my $win = $args->{mw}->Toplevel (
		-title   => $args->{'-title'} || 'Select Color',
	);
	$win->protocol ('WM_DELETE_WINDOW' => sub {
		$args->{selectedbtn} = $btnCancel;
	});
	$win->transient ($win->Parent->toplevel);
	$win->grab;

	# Divide up the main frames.
	my $btnFrame = $win->Frame->pack (-side => 'bottom', -fill => 'x');
	my $topFrame = $win->Frame->pack (-side => 'bottom', -fill => 'both', -expand => 1);
	my $leftFrame = $topFrame->Frame->pack (-side => 'left', -fill => 'y');
	my $rightFrame = $topFrame->Frame->pack (-side => 'left', -fill => 'both', -expand => 1);

	# Create the buttons.
	$btnFrame->Button (
		-text => $btnCancel,
		-command => sub {
			$args->{selectedbtn} = $btnCancel;
		},
	)->pack (-side => 'right', -padx => 5, -pady => 5);
	$btnFrame->Button (
		-text => $btnOkay,
		-command => sub {
			$args->{selectedbtn} = $btnOkay;
		},
	)->pack (-side => 'right', -padx => 5, -pady => 5);

	########################################################################
	## Left Frame (Spectrum and Preview Widgets)                          ##
	########################################################################

	# Create the spectrum viewer.
	my $specPhoto = $win->Photo (
		-data   => $args->getSpectrum,
		-format => 'PNG',
		-width  => 200,
		-height => 100,
	);
	my $specLabel = $leftFrame->Label (
		-borderwidth => 2,
		-relief      => 'sunken',
		-image       => $specPhoto,
	)->pack (-side => 'top', -pady => 10, -padx => 5);

	# Create the color preview objects.
	my $preFrame = $leftFrame->Frame (
		-borderwidth => 1,
		-relief      => 'sunken',
		-width       => 102,
		-height      => 25,
	)->pack (-side => 'top');
	my $curColor = $preFrame->Frame (
		-background => $initColor,
		-width      => 50,
		-height     => 25,
	)->pack (-side => 'left');
	$preFrame->Frame (
		-borderwidth => 1,
		-relief      => 'raised',
		-width       => 2,
		-height      => 25,
	)->pack (-side => 'left');
	my $firstColor = $preFrame->Frame (
		-background => $initColor,
		-width      => 50,
		-height     => 25,
	)->pack (-side => 'left');

	# Bind mouse clicks on the spectrum.
	my $clicking = 0;
	$specLabel->bind ('<Button-1>', sub {
		my $x = $Tk::event->x;
		my $y = $Tk::event->y;
		$clicking = 1;

		if ($x < 200 && $y < 100 && $x > 0 && $y > 0) {
			my $color = $specPhoto->get ($x,$y);
			my $hex = $args->getHex($color);
			$curColor->configure (-background => $hex);
			$args->{selectedcolor} = $hex;
			$args->hexToRGB($hex);
		}
	});
	$specLabel->bind ('<Motion>', sub {
		if ($clicking) {
			my $x = $Tk::event->x;
			my $y = $Tk::event->y;

			my $hex = '';
			if ($y < 0) {
				$hex = '#ffffff';
			}
			elsif ($y > 100) {
				$hex = '#000000';
			}
			elsif ($x < 0 || $x > 200) {
				$hex = '#ff0000';
			}

			if (length $hex == 0) {
				if ($x < 200 && $y < 100 && $x > 0 && $y > 0) {
					my $color = $specPhoto->get ($x,$y);
					$hex = $args->getHex($color);
				}
			}

			if (length $hex) {
				$curColor->configure (-background => $hex);
				$args->{selectedcolor} = $hex;
				$args->hexToRGB($hex);
			}
		}
	});
	$specLabel->bind ('<ButtonRelease-1>', sub {
		$clicking = 0;
	});
	$firstColor->bind ('<Button-1>', sub {
		$curColor->configure (-background => $initColor);
		$args->{selectedcolor} = $initColor;
		$args->hexToRGB($initColor);
	});

	########################################################################
	## Right Frame (Text Boxes)                                           ##
	########################################################################

	my $labValues = $rightFrame->LabFrame (
		-label     => 'Values',
		-labelside => 'acrosstop',
	)->pack (-side => 'top', -fill => 'x', -padx => 5);

	$labValues->Label (
		-text => 'Red:',
	)->grid (-column => 0, -row => 0);
	my $txtRed = $labValues->Entry (
		-textvariable => \$args->{redval},
		-width        => 3,
	)->grid (-column => 1, -row => 0);
	$labValues->Label (
		-text => 'Green:',
	)->grid (-column => 2, -row => 0);
	my $txtGrn = $labValues->Entry (
		-textvariable => \$args->{grnval},
		-width        => 3,
	)->grid (-column => 3, -row => 0);
	$labValues->Label (
		-text => 'Blue:',
	)->grid (-column => 4, -row => 0);
	my $txtBlu = $labValues->Entry (
		-textvariable => \$args->{bluval},
		-width        => 3,
	)->grid (-column => 5, -row => 0);

	# Bind the return keys for these entries.
	$txtRed->bind ('<Return>', sub {
		my $hex = $args->getHex ([
			$args->{redval},
			$args->{grnval},
			$args->{bluval},
		]);
		$curColor->configure (-background => $hex);
		$args->{selectedcolor} = $hex;
		$args->hexToRGB($hex);
	});
	$txtGrn->bind ('<Return>', sub {
		my $hex = $args->getHex ([
			$args->{redval},
			$args->{grnval},
			$args->{bluval},
		]);
		$curColor->configure (-background => $hex);
		$args->{selectedcolor} = $hex;
		$args->hexToRGB($hex);
	});
	$txtBlu->bind ('<Return>', sub {
		my $hex = $args->getHex ([
			$args->{redval},
			$args->{grnval},
			$args->{bluval},
		]);
		$curColor->configure (-background => $hex);
		$args->{selectedcolor} = $hex;
		$args->hexToRGB($hex);
	});

	$labValues->Label (
		-text => 'Hex:',
	)->grid (-column => 0, -row => 1);
	my $txtHex = $labValues->Entry (
		-textvariable => \$args->{hexval},
	)->grid (-column => 1, -row => 1, -columnspan => 5, -sticky => 'ew');
	$txtHex->bind ('<Return>', sub {
		my $valid = 1;
		if (length $args->{hexval} > 7 || length $args->{hexval} < 6) {
			$valid = 0;
		}
		if ($args->{hexval} =~ /[^A-Fa-f0-9\#]/) {
			$valid = 0;
		}

		if ($valid) {
			$args->{hexval} = '#' . $args->{hexval} unless $args->{hexval} =~ /^#/;
			$curColor->configure (-background => $args->{hexval});
			$args->{selectedcolor} = $args->{hexval};
			$args->hexToRGB($args->{hexval});
		}
	});

	my $labPreset = $rightFrame->LabFrame (
		-label     => 'Preset Colors',
		-labelside => 'acrosstop',
	)->pack (-side => 'top', -fill => 'x', -padx => 5);

	my $y = 0;
	foreach my $row (@{$presets}) {
		my $x = 0;
		foreach my $color (@{$row}) {
			my $pre = $labPreset->Frame (
				-background  => $color,
				-borderwidth => 1,
				-relief      => 'sunken',
				-width       => 19,
				-height      => 19,
			)->grid (-column => $x, -row => $y);
			$pre->bind ('<Button-1>', sub {
				$curColor->configure (-background => $color);
				$args->{selectedcolor} = $color;
				$args->hexToRGB($color);
			});
			$x++;
		}
		$y++;
	}

	# Load the data for the initial color.
	$args->hexToRGB($initColor);

	$win->waitVariable (\$args->{selectedbtn});
	$win->destroy;

	if ($args->{selectedbtn} eq $btnOkay) {
		return $args->{selectedcolor};
	}
	else {
		return $initColor;
	}
}

sub getHex {
	my ($self,$color) = @_;

	for (my $i = 0; $i < 3; $i++) {
		if ($color->[$i] =~ /[^0-9]/) {
			$color->[$i] = 0;
		}
		if ($color->[$i] < 0) {
			$color->[$i] = 0;
		}
		elsif ($color->[$i] > 255) {
			$color->[$i] = 255;
		}
	}

	my $red = sprintf("%x",$color->[0]);
	my $grn = sprintf("%x",$color->[1]);
	my $blu = sprintf("%x",$color->[2]);

	$red = '0' . $red until length $red == 2;
	$grn = '0' . $grn until length $grn == 2;
	$blu = '0' . $blu until length $blu == 2;

	return '#' . join("",$red,$grn,$blu);
}

sub hexToRGB {
	my ($self,$hex) = @_;

	$hex =~ s/^#//g;

	my ($r,$g,$b) = $hex =~ /^(..)(..)(..)$/;
	my $red = oct("0x$r");
	my $grn = oct("0x$g");
	my $blu = oct("0x$b");

	$self->{redval} = $red;
	$self->{grnval} = $grn;
	$self->{bluval} = $blu;
	$self->{hexval} = '#' . $hex;
}

sub getSpectrum {
	return qq~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
aiCrcAAAAABJRU5ErkJggg==
~;
}

1;
__END__

=head1 NAME

Tk::Spectrum - A stylish color selection dialog.

=head1 SYNOPSIS

  use Tk::Spectrum;

  my $color = $mw->Spectrum (
    -title        => 'Pick a Color',
    -initialcolor => '#000000',
    -buttons      => [ 'Ok', 'Cancel' ],
    -preset       => [ $preset_colors ],
  );

  print "You chose $color\n";

=head1 DESCRIPTION

Tk::Spectrum is a stylish color selection dialog. It presents the user with
a full color spectrum with which they can click and drag to select colors,
as well as a form where they can select RGB and Hexadecimal color values. It
also supports a "preset color list" similar to the Win32 native color dialog
box. The program can define which colors go into this list.

B<Note:> This module only knows how to deal with hexadecimal numbers. It's
impossible from the end user's side to enter a non-hex value, but if your
program uses colors by name and you try to use named colors in Tk::Spectrum,
it will cause errors.

=head1 OPTIONS

The options supported by Tk::Spectrum are as follows:

=over 4

=item -title

Specifies the title of the dialog box. The default is "Select Color".

=item -initialcolor

Define the initial/default color for the dialog box. If the user hits Cancel,
the initial color is returned.

=item -buttons

Specify the labels for one or both of the buttons on the dialog box. If only one
label is given, it's used on the "Ok" button. If two are given, they're used
on "Ok" and "Cancel", respectively. The default values are "Ok" and "Cancel".

=item -preset

Define a preset color scheme. This takes a number of array references, one array
representing each row of colors to use. The default range of preset colors are
suitable for almost all situations. If your program really needs to override
the presets, you can do so.

  -preset => [
    # Row 1
    [ '#FF0000', '#00FF00', '#0000FF' ],
    # Row 2
    [ '#990000', '#009900', '#000099' ],
  ],

You can have virtually as many rows and columns as you need, but keep in mind
that the dialog window size may grow to accomodate.

=head1 CHANGES

  Version 0.02
  - Added dependency on Tk and Tk::PNG to Makefile.PL to stop CPAN's nagging

  Version 0.01
  - Initial release

=head1 AUTHOR

Casey Kirsle

This module is distributed under the same terms as Perl itself.

=cut
