package Tk::ColorPicker;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.10';
use Tk;

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'ColorPicker';

require Tk::NoteBook;
require Tk::Pane;
use Imager::Screenshot 'screenshot';
use Math::Round;
use Scalar::Util qw(looks_like_number);

my @colspaces = (
	[qw[RGB Red Green Blue]],
	[qw[CMY Cyan Magenta Yellow]],
	[qw[HSV Hue Saturation Value]],
);

my %depthvalues = (
	4 => 1,
	8 => 1,
	12 => 1,
	16 => 1,
);

my %convertcalls = (
	cmy => \&convertCMY,
	cmyX => \&convertCMYx,
	hex => \&convertHEX,
	hsv => \&convertHSV,
	rgb => \&convertRGB,
	rgbX => \&convertRGBx,
);

my %notationcalls = (
	cmy => \&getCMY,
	cmyX => \&getCMYx,
	hex => \&getHEX,
	hsv => \&getHSV,
	rgb => \&getRGB,
	rgbX => \&getRGBx,
);

my %validatecalls = (
	cmy => \&validateCMY,
	cmyX => \&validateCMYx,
	hsv => \&validateHSV,
	rgb => \&validateRGB,
	rgbX => \&validateRGBx,
);

=head1 NAME

Tk::ColorPicker - Frame based megawidget for selecting a color.

=head1 SYNOPSIS

  use Tk::ColorPicker;
  my $pick = $widow->ColorPicker->pack;

=head1 DESCRIPTION

Tk::ColorPicker lets you edit a color in RGB, CMY and HSV space.
It has a facility to pick a screen color with your mouse.
It offers a history of previous selected colors.
It can work in color depths of 4, 8, 12 or 16 bits per channel.
You can switch color depth on the fly.

=head1 OPTIONS

=over 4

=item Switch: B<-colordepth>

Default value 8 bits per color channel. Can be 4, 8, 12 or 16;

=item Switch: B<-depthselect>

Default value 0. If set a row of radiobuttons is diplayed allowing you to switch
color depth.

=item Switch: B<-historycolumns>

Default value 6. Number of columns in the history tab.

=item Switch: B<-historyfile>

Undefined by default. Here you set the filename from where the history is saved
and loaded.

=item Switch: B<-indborderwidth>

Default value 2. Borderwidth of indicator labels in the recent tab.

=item Switch: B<-indicatorwidth>

Default value 4. Width of the indicator labels in the recent tab.

=item Switch: B<-indrelief>

Default value 'sunken'. Relief of the indicator labels in the recent tab.

=item Switch: B<-maxhistory>

Default value 32.Specifies the maximum number of entries in the history list.

=item Switch: B<-notation>

Selects in which notation the color should be represented. Default value I<hex>.
Possible values are:

=over 4

=item B<cmy> C<cmy(0.5, 0.5, 0.5)>

The channel values can be between 0 and 1. It works with 3 decimals precision. For maximum
accuracy set your dolor depth to 12 bits per color.

=item B<cmyX> C<cmy8(127, 127, 127)>

The X stands for the color depth. The channel values are integers ranging from 0 to the max channel
value for the current selected color depth.

=item B<hex> C<#7F7F7F>

The hexadecimal notation of a color.

=item B<hsv> C<hsv(360, 0, 0.5)>

Hue value can be between 0 and 360 degrees with 1 decimal precision.
Saturation and value range from 0 to 1 with 3 decimals precision.

=item B<rgb> C<rgb(0.5, 0.5, 0.5)>

The channel values can be between 0 and 1. It works with 3 decimals precision. For maximum
accuracy set your dolor depth to 12 bits per color.

=item B<rgbX> C<rgb8(127, 127, 127)>

The X stands for the color depth. The channel values are integers ranging from 0 to the max channel
value for the current selected color depth.

=back

=item Switch: B<-notationselect>

Default value 0. If set a menubutton is diplayed allowing you to select a notation.

=item Switch: B<-sliderheight>

Default value 200. Sets the length of all channel sliders.

=item Switch: B<-updatecall>

Set this callback to reflect changes to the outside.
Gets the current color as parameter.

=back

=cut

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $sliderheight = delete $args->{'-sliderheight'};
	$sliderheight = 200 unless defined $sliderheight;

	$self->SUPER::Populate($args);
	
	my $dvar = '';
	my $nvar = '';
	my $rvar = '';
	$self->{COLORDEPTH} = \$dvar;
	$self->{CONFIG} = 1;
	$self->{DEPTHVAR} = \$rvar; #used for the radiobuttons in depthselect
	$self->{HISTORY} = [];
	$self->{NOTATION} = \$nvar;
	$self->{SLIDERHEIGHT} = 200;
	$self->{CURRENT} = '';

	my $pick = $self->Button(
		-text => 'Pick',
		-command => ['pickActivate', $self],
	)->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2,
	);
	$self->Advertise(Pick => $pick);
	$self->bind('<Escape>', [$self, 'pickCancel']);
	my $nb = $self->NoteBook->pack(-expand => 1, -fill => 'both');
	my %varpool = ();
	for (@colspaces) {
		my @space = @$_;
		my $lab = shift @space;
		my $page = $nb->add($lab, -label => $lab);
		for (@space) {
			my $channel = $_;
			my $slframe = $page->Frame->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'y');
			my $var = 0;
			$varpool{$channel} = \$var;
			my %hsv = (
				Hue => 359.9,
				Saturation => 1,
				Value => 1,
			);
			my @m = ();
			if (exists $hsv{$channel}) {
				push @m, -from => $hsv{$channel};
				unless ($channel eq 'Hue') {
					push @m, -resolution => 0.001;
				}
			}
			my $slider = $slframe->Scale(@m,
				-to => 0,
				
				-orient => 'vertical',
				-command => ['ChannelUpdate', $self, $channel],
				-variable => \$var,
			)->pack(-pady => 2, -expand => 1, -fill => 'y');
			$self->Advertise($_, $slider);
			$slframe->Label(-width => 8, -text => $_)->pack;
		}
	}
	
	$self->{VARPOOL} = \%varpool;
	my $recent = $nb->add('Recent', -label => 'Recent');
	my $hp = $recent->Scrolled('Pane',
		-sticky => 'new',
		-scrollbars => 'osoe',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
	my $history = $hp->Frame->pack(-anchor => 'nw');
	$self->Advertise(History => $history);

	
	$self->ConfigSpecs(
		-balloon => ['PASSIVE'],
		-colordepth => ['METHOD', undef, undef, 8],
		-depthselect =>['METHOD', undef, undef, 0],
		-historycolumns => ['PASSIVE', undef, undef, 6],
		-historyfile => ['PASSIVE'],
		-indborderwidth => ['PASSIVE', undef, undef, 2],
		-indicatorwidth => ['PASSIVE', undef, undef, 4],
		-indrelief => ['PASSIVE', undef, undef, 'sunken'],
		-maxhistory => ['PASSIVE', undef, undef, 32],
		-notation => ['METHOD', undef, undef, 'hex'],
		-notationselect => ['METHOD', undef, undef, 0],
		-sliderheight => ['METHOD', 'sliderHeight', 'SliderHeight', 200],
		-updatecall => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => [ $self ],
	);

	$self->Delegates(
		DEFAULT => $self,
	);
	$self->after(300, ['PostConfig', $self]);
}

sub ChannelUpdate {
	my ($self, $channel) = @_;
	return if $self->ConfigMode;
	if ($self->IsHSV($channel)) {
		$self->ChannelUpdateHSV;
	} elsif ($self->IsCMY($channel)) {
		$self->ChannelUpdateCMY;
	} elsif ($self->IsRGB($channel)) {
		$self->ChannelUpdateRGB;
	}
}

sub ChannelUpdateCMY {
	my $self = shift;

	my $max = $self->maxChannelValue;
	my $pool = $self->{VARPOOL};
	my $cvar = $pool->{'Cyan'};
	my $cyan = $$cvar;
	my $mvar = $pool->{'Magenta'};
	my $magenta = $$mvar;
	my $yvar = $pool->{'Yellow'};
	my $yellow = $$yvar;
	
	my $red = $max - $cyan;
	my $green = $max - $magenta;
	my $blue = $max - $yellow;
	my $hex = $self->rgb2hex($red, $green, $blue);
	$self->UpdateRGB($hex);
	$self->UpdateHSV($hex);
	$self->UpdateCall($hex);
}

sub ChannelUpdateHSV {
	my $self = shift;

	my $pool = $self->{VARPOOL};
	my $hvar = $pool->{'Hue'};
	my $hue = $$hvar;
	my $svar = $pool->{'Saturation'};
	my $satur= $$svar;
	my $vvar = $pool->{'Value'};
	my $value = $$vvar;
	$value = 99.9999 if $value eq 100;

	my ($red, $green, $blue) = $self->hsv2rgb($hue, $satur, $value);
	my $hex = $self->rgb2hex($red, $green, $blue);
	$self->UpdateRGB($hex);
	$self->UpdateCMY($hex);
	$self->UpdateCall($hex);
}

sub ChannelUpdateRGB {
	my $self = shift;

	my $depth = $self->colordepth;
	my $mul = (2**$depth);

	my $pool = $self->{VARPOOL};
	my $rvar = $pool->{'Red'};
	my $red = $$rvar;
	my $gvar = $pool->{'Green'};
	my $green = $$gvar;
	my $bvar = $pool->{'Blue'};
	my $blue = $$bvar;
	my $hex = $self->rgb2hex($red, $green, $blue);
	$self->UpdateCMY($hex);
	$self->UpdateHSV($hex);
	
	$self->UpdateCall($hex);
	
}

sub ClassInit {
	my ($class,$mw) = @_;
	$mw->bind($class, '<Escape>','pickCancel');
	return $class->SUPER::ClassInit($mw);
}

sub colordepth {
	my ($self, $value) = @_;
	my $valref = $self->{COLORDEPTH};
	if (defined $value) {
		unless (exists $depthvalues{$value}) {
			warn "invalid colordepth '$value'\n";
			return $$valref
		}
		my $oldmax = $self->maxChannelValue;
		$$valref = $value;
		my $radiovar = $self->{DEPTHVAR};
		$$radiovar = $value;
		my $newmax = (2**$value) - 1;
		my $varpool = $self->{VARPOOL};
		for (qw/Red Green Blue Cyan Magenta Yellow/) {
			my $var = $varpool->{$_};
			my $oldval = $$var;
			$self->Subwidget($_)->configure(-from => $newmax);
			my $ratio = ($newmax + 1)/($oldmax + 1);
			my $newval = $oldval * $ratio;
			$$var = $newval;
		}
		$self->UpdateCall($self->compoundColor);
	}
	return $$valref;
}

=item B<colorDepth>I<($hexcolor)>

Returns the color depth of $hexcolor.

=cut

sub colorDepth {
	my ($self, $color) = @_;
	$color =~ s/^\#//;
	my %valid = (
		3 => 4,
		6 => 8,
		9 => 12,
		12 => 16
	);
	my $length = length($color);
	return $valid{$length} if exists $valid{$length};
	warn "Invalid color '$color'\n";
	return undef
}

=item B<compoundColor>

Returns a hex color string based on the Red, Green and Blue channels.

=cut

sub compoundColor {
	my $self = shift;
	my $pool = $self->{VARPOOL};
	my $vred = $pool->{'Red'};
	my $red = $self->hexString($$vred);
	my $vgreen = $pool->{'Green'};
	my $green = $self->hexString($$vgreen);
	my $vblue = $pool->{'Blue'};
	my $blue = $self->hexString($$vblue);
	return "#$red$green$blue";
}

sub ConfigMode {
	my $self = shift;
	$self->{CONFIG} = shift if @_;
	return $self->{CONFIG}
}

sub convert {
	my ($self, $color) = @_;
	my $not = $self->notationDetect($color);
	return undef unless defined $not;
	my $call = $convertcalls{$not};
	return &$call($self, $color);
}

sub convertBase {
	my ($self, $val, $space) = @_;
	if ($val =~ /^$space\((.+)\)$/) {
		my $parstring = "$1, ";
		my @vals;
		for (1 .. 3) {
			if ($parstring =~ s/^^([^,]+),\s*//) {
				my $number = $1;
				if (looks_like_number($number)) {
					if (($space eq 'hsv') and ($_ eq 1)) {
						$number = $self->numround($number, 1);
					} else {
						$number = $self->numround($number, 3);
					}
					push @vals, $number
				}
			}
		}
		return @vals
	}
}

sub convertBaseX {
	my ($self, $val, $space) = @_;
	if ($val =~ /^$space\d+\((.+)\)$/) {
		my $parstring = "$1, ";
		my @vals;
		for (1 .. 3) {
			if ($parstring =~ s/^([^,]+),\s*//) {
				my $number = $1;
				push @vals, $number if $number =~ /^\d+$/
			}
		}
		return @vals
	}
}

=item B<convertCMY>I<($string)>

Returns the hex formatted representation of a cmy formatted string.

=cut

sub convertCMY {
	my ($self, $string) = @_;
	my ($cyan, $magenta, $yellow) = $self->convertBase($string, 'cmy');
	my $max = $self->maxChannelValue;
	my $red = int((1 - $cyan) * $max);
	my $green = int((1 - $magenta) * $max);
	my $blue = int((1 - $yellow) * $max);
	return $self->rgb2hex($red, $green, $blue);
}

=item B<convertCMYx>I<($string)>

Returns the hex formatted representation of a cmyX formatted string.

=cut

sub convertCMYx {
	my ($self, $string) = @_;
	my ($cyan, $magenta, $yellow) = $self->convertBaseX($string, 'cmy');
	my $max = $self->maxChannelValue;
	my $red = $max - $cyan;
	my $green = $max - $magenta;
	my $blue = $max - $yellow;
	return $self->rgb2hex($red, $green, $blue);
}

=item B<convertDepth>(I<$string>, ?<I$depth>?)

Converts the depth of $string to $depth.
If $depth is not specified, B<-colordepth> is used

=cut

sub convertDepth {
	my ($self, $string, $depth) = @_;
	$depth = $self->colordepth unless defined $depth;
	return $string if $self->colorDepth($string) eq $depth;

	$string =~ s/^(\#|Ox)//;
	
	my $length = length($string) / 3;
	$_ = $string;
	my ($r, $g, $b) = m/(\w{$length})(\w{$length})(\w{$length})/;
	my $conv = $depth / 4;
	for (\$r, \$g, \$b) {
		my $tag = $_;
		while (length($$tag) ne $conv) {
			if (length($$tag) > $conv) {
				$$tag =~ s/.$//
			} else {
				$$tag = $$tag . '0';
			}
		}
	}
	return '#' . $r. $g . $b
}

=item B<convertHEX>I<($string)>

Returns the hex formatted representation of a hex formatted string.
So basically it does nothing but return it's input.

=cut

sub convertHEX {
	my ($self, $string) = @_;
	return $string
}


=item B<convertHSV>I<($string)>

Returns the hex formatted representation of a hsv formatted string.

=cut

sub convertHSV {
	my ($self, $string) = @_;
	my ($hue, $sat, $val) = $self->convertBase($string, 'hsv');
	return $self->rgb2hex($self->hsv2rgb($hue, $sat, $val));
}

=item B<convertRGB>I<($string)>

Returns the hex formatted representation of a rgb formatted string.

=cut

sub convertRGB {
	my ($self, $string) = @_;
	my ($red, $green, $blue) = $self->convertBase($string, 'rgb');
	my $max = $self->maxChannelValue;
	$red = int($red * $max);
	$green = int($green * $max);
	$blue = int($blue * $max);
	return $self->rgb2hex($red, $green, $blue);
}


=item B<convertRGBx>I<($string)>

Returns the hex formatted representation of a rgbX formatted string.

=cut

sub convertRGBx {
	my ($self, $string) = @_;
	my ($red, $green, $blue) = $self->convertBaseX($string, 'rgb');
	return $self->rgb2hex($red, $green, $blue);
}

sub depthselect {
	my ($self, $flag) = @_; 
	if (defined $flag) {
		if ($flag) {		
			unless (defined $self->Subwidget('DepthSelect')) {
				my $bpcframe = $self->Frame->pack(
					-before => $self->Subwidget('Pick'),
					-fill => 'x',
				);
				$bpcframe->Label(
					-anchor => 'e',
					-justify => 'right',
					-text => 'Depth:',
					-width => 7,
				)->pack(-side => 'left', -padx => 2, -pady => 2);
				for (4, 8, 12, 16) {
					my $depth = $_;
					$bpcframe->Radiobutton(
						-text => $depth,
						-value => $depth,
						-command => ['colordepth', $self, $depth],
						-variable => $self->{DEPTHVAR},
					)->pack(-side => 'left', -padx => 2, -pady => 2);
				}
				$self->Advertise('DepthSelect', $bpcframe)
			}
		} else {
			if (defined $self->Subwidget('DepthSelect')) {
				$self->Subwidget('DepthSelect')->destroy;
				$self->Advertise('DepthSelect', undef);
			}
		}
	}
	return defined $self->Subwidget('DepthSelect');
}

=item B<getCMY>

Returns a cmy formatted representation of the current color.

=cut

sub getCMY {
	my $self = shift;
	return $self->notationCMY($self->getHEX);
}

=item B<getCMYx>

Returns a cmyX formatted representation of the current color.

=cut

sub getCMYx {
	my $self = shift;
	return $self->notationCMYx($self->getHEX);
}

=item B<getHEX>

Returns a hex formatted representation of the current color.

=cut

sub getHEX {
	return $_[0]->{CURRENT};
}

=item B<getHSV>

Returns a hsv formatted representation of the current color.

=cut

sub getHSV {
	my $self = shift;
	return $self->notationHSV($self->getHEX);
}

=item B<getRGB>

Returns a rgb formatted representation of the current color.

=cut

sub getRGB {
	my $self = shift;
	return $self->notationRGB($self->getHEX);
}

=item B<getRGBx>

Returns a rgbX formatted representation of the current color.

=cut

sub getRGBx {
	my $self = shift;
	return $self->notationRGBx($self->getHEX);
}

sub hex2cmy {
	my ($self, $hex) = @_;
	my ($red, $green, $blue) = $self->hex2rgb($hex);
	my $max = $self->maxChannelValue;
	return ($max - $red, $max- $green, $max - $blue)
}

sub hex2hsv {
	my ($self, $hex) = @_;
	return $self->rgb2hsv($self->hex2rgb($hex))
}

=item B<hex2rgb>I<($hex)>

Converts $hex to Red, Green Blue values.

=cut

sub hex2rgb {
	my ($self, $hex) = @_;
	$hex =~ s/^(\#|Ox)//;
	my $length = length($hex) / 3;
	$_ = $hex;
	my ($r, $g, $b) = m/(\w{$length})(\w{$length})(\w{$length})/;
	my @rgb = ();
	$rgb[0] = CORE::hex($r);
	$rgb[1] = CORE::hex($g);
	$rgb[2] = CORE::hex($b);
	return @rgb
}

=item B<hexString>(I<$num>, ?I<$depth>?>)

Returns the hexadecimal notation of $num.
If $depth is not specified, B<-colordepth> is used

=cut

sub hexString {
	my ($self, $num, $depth) = @_;
	$depth = $self->colordepth unless defined $depth;
	my $length = $depth / 4;
	my $hex = substr(sprintf("0x%X", $num), 2);
	while (length($hex) < $length) { $hex = "0$hex" }
	return $hex
}

sub History {
	my $self = shift;
	return $self->{HISTORY};
}

=item B<historyAdd>(I<$color>)

Adds color to the History list.
Saves the list and updates the history tab.

=cut

sub historyAdd {
	my ($self, $color) = @_;
	return unless $self->validate($color);
	$self->historyLoad;
	$self->historyNew($color);
	$self->historySave;
}

=item B<historyClear>

Clears the history list.

=cut

sub historyClear {
	my $history = $_[0]->History;
	while (@$history) { pop @$history }
}

=item B<historyLoad>

Loads the history file if it is specified.

=cut

sub historyLoad {
	my $self = shift;
	my $file = $self->cget('-historyfile');
	return unless defined $file;
	return unless -e $file;
	if (open INFILE, "<", $file) {
		$self->historyClear;
		my $history = $self->History;
		while (<INFILE>) {
			my $line = $_;
			chomp($line);
			push @$history, $line;
		}
		close INFILE;
	} else {
		warn "can not load file '$file'";
	}
}

=item B<historyNew>(I<$color>)

Adds $color to the history list

=cut

sub historyNew {
	my ($self, $color) = @_;
	return unless $self->validate($color);
	my $history = $self->History;
	my ($pos) = grep { $history->[$_] eq $color } 0 .. @$history - 1;
	splice(@$history, $pos, 1) if defined $pos;
	unshift @$history, $color;
	my $size = @$history;
	pop @$history if $size > $self->cget('-maxhistory');
}

=item B<historyReset>

Clears the history list. Then saves and updates.

=cut

sub historyReset {
	my $self = shift;
	$self->historyClear;
	$self->historySave;
	$self->historyUpdate;
}

=item B<historySave>

Saves the history list.

=cut

sub historySave{
	my $self = shift;
	my $file = $self->cget('-historyfile');
	return unless defined $file;
	my $history = $self->History;
	return unless @$history;
	if (open OUTFILE, ">", $file) {
		for (@$history) {
			my $color = $_;
			print OUTFILE "$color\n";
		}
		close OUTFILE;
	} else {
		warn "can not save file '$file'";
	}
}

sub historySelect {
	my ($self, $item) = @_;
	$self->UpdateCall($item);
	$self->UpdateAll($item);
}

=item B<historyUpdate>

Updates the history tab.

=cut

sub historyUpdate {
	my $self = shift;
	$self->historyLoad;
	my $history = $self->History;
	my $column = 0;
	my $row = 0;
	my $numcolumns = $self->cget('-historycolumns');
	my $page = $self->Subwidget('History');
	for ($page->children) {
		$_->gridForget;
		$_->destroy;
	}
	for (@$history) {
		my $color = $_;
		next unless $self->validate($color);
		my $l = $page->Label(
			-cursor => 'hand1',
			-background => $color,
			-borderwidth => $self->cget('-indborderwidth'),
			-relief => $self->cget('-indrelief'),
			-width => $self->cget('-indicatorwidth'),
		)->grid(
			-column => $column,
			-row => $row,
			-padx => 2,
			-pady => 2,
		);
		$l->bind('<ButtonRelease-1>', [$self, 'historySelect', $color]);
		my $balloon = $self->cget('-balloon');
		$balloon->attach($l, -balloonmsg => $color) if defined $balloon;
		$column ++;
		if ($column eq $numcolumns) {
			$column = 0;
			$row ++;
		}
	}
}

sub hsv2rgb {

	# The procedure below converts an HSB value to RGB.  It takes hue,
	# saturation, and value components (floating-point, 0-1.0) as arguments,
	# and returns a list containing RGB components (integers, 0-65535) as
	# result.  The code here is a copy of the code on page 616 of
	# "Fundamentals of Interactive Computer Graphics" by Foley and Van Dam.

	my($self, $hue, $sat, $value) = @_;
	my($v, $i, $f, $p, $q, $t);

	my $depth = $self->colordepth;
	my $mul = (2**$depth)/65536;
	$hue = $hue / 360;

	$v = int(65535 * $value);
	my $ret = $v * $mul;
	return ($ret, $ret, $ret) if $sat == 0;
	$hue *= 6;
	$hue = 0 if $hue >= 6;
	$i = int($hue);
	$f = $hue - $i;
	$p = int(65535 * $value * (1 - $sat));
	$q = int(65535 * $value * (1 - ($sat * $f)));
	$t = int(65535 * $value * (1 - ($sat * (1 - $f))));
	my @rgb = ();
	@rgb = ($v, $t, $p) if $i == 0;
	@rgb = ($q, $v, $p) if $i == 1;
	@rgb = ($p, $v, $t) if $i == 2;
	@rgb = ($p, $q, $v) if $i == 3;
	@rgb = ($t, $p, $v) if $i == 4;
	@rgb = ($v, $p, $q) if $i == 5;

	#convert to the proper depth
	my @r = ();
	for (@rgb) {
		push @r, int($_ * $mul)
	}
	return @r
}

sub IsCMY {
	my ($self, $channel) = @_;
	my %hsv = (
		Cyan => 1,
		Magenta => 1,
		Yellow => 1,
	);
	return exists $hsv{$channel};
}

sub IsHSV {
	my ($self, $channel) = @_;
	my %hsv = (
		Hue => 1,
		Saturation => 1,
		Value => 1,
	);
	return exists $hsv{$channel};
}

sub IsRGB {
	my ($self, $channel) = @_;
	my %hsv = (
		Red => 1,
		Green => 1,
		Blue => 1,
	);
	return exists $hsv{$channel};
}

=item B<maxChannelValue>

Returns the maximum values for the Red, Green, Blue, Cyan, Magenta and Yellow channels,
based on B<-colordepth>.

=cut

sub maxChannelValue {
	my $self = shift;
	my $ref = $self->{COLORDEPTH};
	my $depth = $$ref;
	return (2**$depth) - 1 if $depth ne '';
}

sub notation {
	my $self = shift;
	my $nvar = $self->{NOTATION};
	if (@_) {
		$$nvar = shift;
		$self->UpdateCall($self->getHEX);
	}
	return $$nvar
}

=item B<notationCMY>I<($hexcolor)>

Returns a cmy formatted string of a hex color.

=cut

sub notationCMY {
	my ($self, $hex) = @_;
	my ($cyan, $magenta, $yellow) = $self->hex2cmy($hex);
	my $max = $self->maxChannelValue;
	$cyan = $self->numround($cyan / $max, 3);
	$magenta = $self->numround($magenta / $max, 3);
	$yellow = $self->numround($yellow / $max, 3);
	return "cmy($cyan, $magenta, $yellow)"
}

=item B<notationCMYx>I<($hexcolor)>

Returns a cmyX formatted string of a hex color.

=cut

sub notationCMYx {
	my ($self, $hex) = @_;
	my ($cyan, $magenta, $yellow) = $self->hex2cmy($hex);
	my $depth = $self->cget('-colordepth');
	return "cmy$depth($cyan, $magenta, $yellow)"
}

sub notationCurrent {
	my ($self, $color) = @_;
	$color = $self->{CURRENT} unless defined $color;
	return unless $self->validate($color);
	$color = $self->convert($color);
	my $notationcall = $notationcalls{$self->cget('-notation')};
	return &$notationcall($self, $color);
}

=item B<notationDetect>I<($color)>

Tries to detect the notation of I>$color> and returns
what it finds. Returns undef if it does not detect a valid notation.

=cut

sub notationDetect {
	my ($self, $color) = @_;
	my $repeat = $self->colordepth / 4;
	return 'cmy' if $color =~ /^cmy\(.+\)$/;
	return 'cmyX' if $color =~ /^cmy\d+\(.+\)$/;
	return 'hex' if $color =~ /^#(?:[0-9a-fA-F]{3}){$repeat}$/;
	return 'hsv' if $color =~ /^hsv\(.+\)$/;
	return 'rgb' if $color =~ /^rgb\(.+\)$/;
	return 'rgbX' if $color =~ /^rgb\d+\(.+\)$/;
	return undef
}

=item B<notationHEX>I<($hexcolor)>

Returns a hex formatted string of a hex color.
So basically it just returns it's input.

=cut

sub notationHEX {
	my ($self, $hex) = @_;
	return $hex;
}

=item B<notationHSV>I<($hexcolor)>

Returns a hsc formatted string of a hex color.

=cut

sub notationHSV {
	my ($self, $hex) = @_;
	my ($hue, $saturation, $value) = $self->hex2hsv($hex);
	$hue = $self->numround($hue, 1);
	$saturation = $self->numround($saturation, 3);
	$value = $self->numround($value, 3);
	return "hsv($hue, $saturation, $value)"
}

=item B<notationRGB>I<($hexcolor)>

Returns a rgb formatted string of a hex color.

=cut

sub notationRGB {
	my ($self, $hex) = @_;
	my ($red, $green, $blue) = $self->hex2rgb($hex);
	my $max = $self->maxChannelValue;
	$red = $self->numround($red / $max, 3);
	$green = $self->numround($green / $max, 3);
	$blue = $self->numround($blue / $max, 3);
	return "rgb($red, $green, $blue)"
}

=item B<notationRGBx>I<($hexcolor)>

Returns a rgbX formatted string of a hex color.

=cut

sub notationRGBx {
	my ($self, $hex) = @_;
	my ($red, $green, $blue) = $self->hex2rgb($hex);
	my $depth = $self->cget('-colordepth');
	return "rgb$depth($red, $green, $blue)"
}

sub notationselect {
	my ($self, $flag) = @_; 
	if (defined $flag) {
		if ($flag) {		
			unless (defined $self->Subwidget('NotationSelect')) {
				my $fmframe = $self->Frame->pack(
					-before => $self->Subwidget('Pick'),
					-fill => 'x',
				);
				$fmframe->Label(
					-anchor => 'e',
					-justify => 'right',
					-text => 'Format:',
					-width => 7,
				)->pack(-side => 'left', -padx => 2, -pady => 2);
				my $var = '';
				my @menuitems;
				for ('cmy', 'cmyX', 'hex', 'hsv', 'rgb', 'rgbX') {
					my $t = $_;
					push @menuitems,	['command' => $t,
						-command => sub {
							$var = $t;
							$self->configure(-notation => $t)
						},
					];

				}
				my $mb = $fmframe->Menubutton(
					-anchor => 'w',
					-textvariable => $self->{NOTATION},
				)->pack(-side => 'left', -expand => 1, -fill => 'x', -padx => 2, -pady => 2);
				$mb->configure(-menu => $mb->Menu(
						-tearoff => 0,
						-menuitems => \@menuitems,
				)); 
				
				$self->Advertise('NotationSelect', $fmframe)
			}
		} else {
			if (defined $self->Subwidget('NotationSelect')) {
				$self->Subwidget('NotationSelect')->destroy;
				$self->Advertise('NotationSelect', undef);
			}
		}
	}
	return defined $self->Subwidget('NotationSelect');
}

sub numround {
	my ($self, $number, $decimals) = @_;
	my $mult = 10 ** $decimals;
	$number = $number * $mult;
	$number = round($number);
	$number = $number / $mult;
	return $number;
}

sub pickActivate {
	my $self = shift;
	return if $self->pickInProgress;
	my $bindsave = $self->bind('<Button-1>');
	$self->{'_bindsave'} = $bindsave;
	$self->{'_cursorsave'} = $self->toplevel->cget('-cursor');
	$self->bind('<Button-1>', [$self, 'pickRelease', Ev('X'), Ev('Y')]);
	$self->{'_BE_grabinfo'} = $self->grabSave;
	$self->grabGlobal;
	$self->toplevel->configure(-cursor => 'crosshair');
}

sub pickCancel {
	my $self = shift;
	return unless $self->pickInProgress;
	my $bindsave = delete $self->{'_bindsave'};
	$self->bind('<Button-1>', $bindsave);
	my $cursor = delete $self->{'_cursorsave'};
	$self->toplevel->configure(-cursor => $cursor);
	$self->grabRelease;
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
	}
}

sub pickInProgress {
	return exists $_[0]->{'_bindsave'};
}

sub pickRelease {
	my ($self, $x, $y) = @_;
	return unless $self->pickInProgress;
	my $img = screenshot;
	my $color = $img->getpixel(x => $x, y=> $y);
	my $red = $self->hexString($color->red, 8);
	my $green = $self->hexString($color->green, 8);
	my $blue = $self->hexString($color->blue, 8);
	my $hex = $self->convertDepth("#" . $red . $green . $blue);
	$self->pickCancel;
	$self->UpdateCall($hex);
	$self->UpdateAll($hex);
}

sub PostConfig {
	my $self = shift;
	$self->historyLoad;
	$self->historyUpdate;
	$self->ConfigMode(0);
	$self->sliderheight($self->sliderheight);
	my $file = $self->cget('-historyfile');
}

=item B<put>(I<$color>)

Changes all sliders to match $color

=cut

sub put {
	my ($self, $color) = @_;
	return unless $self->validate($color);
	my $hex = $self->convert($color);
	$self->{CURRENT} = $hex;
	$self->UpdateAll($hex);
}

=item B<rgb2hex>(I<$red>, I<$green>, I<$blue>, ?I<$depth>?)

Converts the red, green and blue values to a hexstring.
If depth is not specified, B<-colordepth> is used.

=cut

sub rgb2hex {
	my ($self, $red, $green, $blue, $depth) = @_;
	$red = $self->hexString($red, $depth);
	$green = $self->hexString($green, $depth);
	$blue = $self->hexString($blue, $depth);
	return '#' . $red . $green . $blue;
}

sub rgb2hsv {

	# The procedure below converts an RGB value to HSB.  It takes red, green,
	# and blue components (0-65535) as arguments, and returns a list
	# containing HSB components (floating-point, 0-1) as result.  The code
	# here is a copy of the code on page 615 of "Fundamentals of Interactive
	# Computer Graphics" by Foley and Van Dam.

	my($self, $red, $green, $blue) = @_;
	my($max, $min, $sat, $range, $hue, $rc, $gc, $bc);

	#convert to 16 bit;
	my $depth = $self->colordepth;
	my $mul = 65535/(2**$depth);
	my @r = ();
	for ($red, $green, $blue) {
		push @r, int($_ * $mul)
	}
	($red, $green, $blue) = @r;
	
	$max = ($red > $green) ? (($blue > $red) ? $blue : $red) :
	(($blue > $green) ? $blue : $green);
	$min = ($red < $green) ? (($blue < $red) ? $blue : $red) :
	(($blue < $green) ? $blue : $green);
	$range = $max - $min;
	if ($max == 0) {
		$sat = 0;
	} else {
		$sat = $range / $max;
	}
	if ($sat == 0) {
		$hue = 0;
	} else {
		$rc = ($max - $red) / $range;
		$gc = ($max - $green) / $range;
		$bc = ($max - $blue) / $range;
		$hue = ($max == $red)?(0.166667*($bc - $gc)):
		(($max == $green)?(0.166667*(2 + $rc - $bc)):
		(0.166667*(4 + $gc - $rc)));
	}
	$hue += 1 if $hue < 0;
	return ($hue * 360, $sat, $max/65535);

}

sub sliderheight {
	my ($self, $height) = @_;
	if (defined $height) {
		$self->{SLIDERHEIGHT} = $height;
		unless ($self->ConfigMode) {
			for (qw/Red Green Blue Cyan Magenta Yellow Hue Saturation Value/) {
#			for (qw/Red Green Blue/) {
				$self->Subwidget($_)->configure('-length' => $height);
			}
		}
	}
	return $self->{SLIDERHEIGHT};
}

sub UpdateAll {
	my ($self, $value) = @_;
	return unless defined $value;
	$self->UpdateCMY($value);
	$self->UpdateHSV($value);
	$self->UpdateRGB($value);
}

sub UpdateCall {
	my ($self, $value) = @_;
	return if $self->ConfigMode;
	$self->{CURRENT} = $value;
	my $text = $self->notationCurrent($value);
	$self->Callback('-updatecall', $text) if defined $text;
}

sub UpdateCMY {
	my ($self, $value) = @_;
	my ($cyan, $magenta, $yellow) = $self->hex2cmy($value);
	my $max = $self->maxChannelValue;
	my $pool = $self->{VARPOOL};
	my $cvar = $pool->{'Cyan'};
	$$cvar = $cyan;
	my $mvar = $pool->{'Magenta'};
	$$mvar = $magenta;
	my $yvar = $pool->{'Yellow'};
	$$yvar = $yellow;
}

sub UpdateHSV {
	my ($self, $val) = @_;
	my ($red, $green, $blue) = $self->hex2rgb($val);

	my ($hue, $saturation, $value) = $self->rgb2hsv($red, $green, $blue);

	my $pool = $self->{VARPOOL};
	my $hvar = $pool->{'Hue'};
	$$hvar = $hue;
	my $svar = $pool->{'Saturation'};
	$$svar = $saturation;
	my $vvar = $pool->{'Value'};
	$$vvar = $value;
}

sub UpdateRGB {
	my ($self, $value) = @_;
	my ($red, $green, $blue) = $self->hex2rgb($value);
	my $max = $self->maxChannelValue;
	my $pool = $self->{VARPOOL};
	my $rvar = $pool->{'Red'};
	$$rvar = $red;
	my $gvar = $pool->{'Green'};
	$$gvar = $green;
	my $bvar = $pool->{'Blue'};
	$$bvar = $blue;
}

=item B<validate>(?I<$color>?)

Returns true if $color is a valid color.

=cut

sub validate {
	my ($self, $val) = @_;
	my $not = $self->notationDetect($val);
	return 0 unless defined $not;
	return 1 if $not eq 'hex';
	my $call = $validatecalls{$not};
	return &$call($self, $val)
}

sub validateCMY {
	my ($self, $val) = @_;
	return $self->validateSpace($val, 'cmy');
}

sub validateCMYx {
	my ($self, $val) = @_;
	return $self->validateSpaceX($val, 'cmy');
}

sub validateHSV {
	my ($self, $val) = @_;
	return 0 unless $val =~ /^hsv\((.+)\)$/;
	my $parstring = "$1, ";
	for (1 .. 3) {
		if ($parstring =~ s/^([^,]+),\s*//) {
			return 0 unless looks_like_number($1);
			return 0 if $1 < 0;
			if ($_ eq 1) {
				return 0 if $1 > 360
			} else {
				return 0 if $1 > 1
			}
		} else {
			return 0
		}
	}
	return 1
}

sub validateRGB {
	my ($self, $val) = @_;
	return $self->validateSpace($val, 'rgb');
}

sub validateRGBx {
	my ($self, $val) = @_;
	return $self->validateSpaceX($val, 'rgb');
}

sub validateSpace {
	my ($self, $val, $space) = @_;
	return 0 unless $val =~ /^$space\((.+)\)$/;
	my $parstring = "$1, ";
	for (1 .. 3) {
		if ($parstring =~ s/^([^,]+),\s*//) {
			my $number = $1;
			return 0 unless looks_like_number($number);
			return 0 if $1 < 0;
			return 0 if $1 > 1
		} else {
			return 0
		}
	}
	return 1
}

sub validateSpaceX {
	my ($self, $val, $space) = @_;
	return 0 unless $val =~ /^$space(\d+)\((.+)\)$/;
	my $depth = $1;
	my $parstring = "$2, ";
	return 0 unless $depth eq $self->cget('-colordepth');
	for (1 .. 3) {
		if ($parstring =~ s/^([^,]+),\s*//) {
			my $number = $1;
			return 0 unless $number =~ /^\d+$/;
			return 0 if $number > ((2**$depth) - 1)
		} else {
			return 0
		}
	}
	return 1
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=cut

=head1 BUGS

Switching color depth straight after initialization gives unwanted results.

Cancelling a pick operation only works in the context of L<Tk::ColorEntry>.

=cut

1;
__END__