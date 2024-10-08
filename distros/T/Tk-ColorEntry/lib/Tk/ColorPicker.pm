package Tk::ColorPicker;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.09';
use Tk;

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'ColorPicker';

require Tk::NoteBook;
require Tk::Pane;
use Imager::Screenshot 'screenshot';

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
	my $rvar = '';
	$self->{COLORDEPTH} = \$dvar;
	$self->{CONFIG} = 1;
	$self->{DEPTHVAR} = \$rvar; #used for the radiobuttons in depthselect
	$self->{HISTORY} = [];
	$self->{SLIDERHEIGHT} = 200;

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

sub depthselect {
	my ($self, $flag) = @_; 
	if (defined $flag) {
		if ($flag) {		
			unless (defined $self->Subwidget('DepthSelect')) {
				my $bpcframe = $self->Frame->pack(
					-before => $self->Subwidget('Pick'),
					-fill => 'x',
				);
				$bpcframe->Label(-text => 'Depth:')->pack(-side => 'left', -padx => 2, -pady => 2);
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
}

=item B<put>(I<$color>)

Changes all sliders to match $color

=cut

sub put {
	my ($self, $color) = @_;
	$self->UpdateAll($color) if ($self->validate($color));
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
	$self->UpdateCMY($value);
	$self->UpdateHSV($value);
	$self->UpdateRGB($value);
}

sub UpdateCall {
	my ($self, $value) = @_;
	return if $self->ConfigMode;
	$self->Callback('-updatecall', $value);
}

sub UpdateCMY {
	my ($self, $value) = @_;
	my ($red, $green, $blue) = $self->hex2rgb($value);
	my $max = $self->maxChannelValue;
	my $pool = $self->{VARPOOL};
	my $cvar = $pool->{'Cyan'};
	$$cvar = $max - $red;
	my $mvar = $pool->{'Magenta'};
	$$mvar = $max- $green;
	my $yvar = $pool->{'Yellow'};
	$$yvar = $max - $blue;
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

Returns true if $color is a valid hexcolor.

=cut

sub validate {
	my ($self, $val) = @_;
	my $repeat = $self->colordepth / 4;
	return $val =~ /^#(?:[0-9a-fA-F]{3}){$repeat}$/
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