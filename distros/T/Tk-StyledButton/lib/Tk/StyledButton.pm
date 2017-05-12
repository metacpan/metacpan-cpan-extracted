package Tk::StyledButton;

require 5.008;

use strict;
use warnings;
use Tk;
use Tk::Balloon;
use Tk::Canvas;
use Tk::Font;
use Tk::Trace;
use Tk::PNG;
use Tk::JPEG;
use Tk::Photo;
use MIME::Base64;
use Carp;

use base qw(Tk::Derived Tk::Canvas);

use constant PI => 3.1415926;
use constant PI_OVER_2 => 1.5707963;
use constant SQUARE_EDGE_FACTOR => 1.5;

our $VERSION = '0.10';

our $hasgd;			# has GD & GD::Text
our $hasw32n2f;		# has Win32::Font::NameToFile

our $SIN_PI_OVER_4 = sin(0.78539815);

our %valid_compound = qw(
	center 1
	left 1
	right 1
	top 1
	bottom 1
	none 1
);

our %valid_anchor = qw(
	n 1
	s 1
	e 1
	w 1
	center 1
	ne 1
	nw 1
	se 1
	sw 1
);

our %valid_orient = qw(
	n ne
	s se
	e en
	w wn
	ne ne
	nw nw
	se se
	sw sw
	en en
	es es
	wn wn
	ws ws
);

our %valid_shapes = qw(
	rectangle 1
	oval 1
	round 1
	bevel 1
	folio 1
);

our %valid_styles = qw(
	flat 1
	round 1
	shiny 1
	gel 1
	image 1
);

our %notkeymouse_event = qw(
Activate 1
Circulate 1
CirculateRequest 1
Colormap 1
Configure 1
ConfigureRequest 1
Create 1
Deactivate 1
Destroy 1
Expose 1
FocusIn 1
FocusOut 1
Gravity 1
Map 1
MapRequest 1
Property 1
Reparent 1
ResizeRequest 1
Unmap 1
Visibility 1
);

our $balloon;	# set only if we get a -tooltip

#
#	needed to compute a polygon to fit a circle
#	for image-rendered buttons, since createOval
#	doesn't work with transparent stipple on
#	Win32
#
our @polyfactors = (
1, 0,
0.866025408250255, 0.5,
0.5, 0.866025394852806,
0, 1,
-0.5, 0.866025421647702,
-0.866025381455357, 0.5,
-1, 0,
-0.86602543504515, -0.5,
-0.5, -0.866025368057908,
0, -1,
0.5, -0.866025448442596,
0.866025354660458, -0.5
);

BEGIN {
	eval {
		require GD;
		require GD::Text::Wrap;
	};

	$hasgd = 1 unless $@;

	if ($hasgd && ($^O eq 'MSWin32')) {
		eval {
			require Win32::Font::NameToFile;
		};
		$hasw32n2f = 1 unless $@;
	}
	if ($hasw32n2f) {
		use Win32::Font::NameToFile qw(get_ttf_abs_path);
	}
}

Construct Tk::Widget 'StyledButton';

sub ClassInit {
    my ($class,$mw) = @_;

    $class->SUPER::ClassInit($mw);
#
#	in order to defer redraws, we queue up requests
#	and wait until we're idle
#
    $mw->bind($class,'<Configure>', ['_layoutRequest',1]);
}

sub Populate
{
	my ($self, $args) = @_;

    $self->SUPER::Populate($args);
#
#	we use methods for everything, so we immediately redraw
#	when an option changes
#
	$self->ConfigSpecs(
		-activeimage => [ 'METHOD' ],
		-anchor		=> [qw/METHOD anchor Anchor/, 'center'],
		-angle		=> [qw/METHOD angle Angle/, 0.1],
		-background => [qw/METHOD background Background/],
		-bitmap		=> [qw/METHOD bitmap Bitmap/],
		-command	=> [qw/CALLBACK command Command/, sub { return 1; }],
		-compound	=> [qw/METHOD compound Compound/, 'center'],
		-dispersion => [qw/METHOD dispersion Dispersion/, 0.8],
		-font		=> [qw/METHOD font Font/],
		-foreground => [qw/METHOD foreground Foreground/, 'black'],
		-height		=> [qw/METHOD height Height/],
		-idleimage  => [ 'METHOD' ],
		-image		=> [qw/METHOD image Image/],
		-justify	=> [qw/METHOD justify Justify/, 'center'],
		-orient		=> [qw/METHOD orient Orient/, 'ne'],
		-padx		=> [qw/METHOD padx Padx/, 4],
		-pady		=> [qw/METHOD pady Pady/, 4],
		-shape		=> [qw/METHOD shape Shape/, 'rectangle'],
		-style		=> [qw/METHOD style Style/, 'shiny'],
		-state		=> [qw/METHOD state State/, 'normal'],
		-text		=> [qw/METHOD text Text/],
		-textvariable => [qw/METHOD textvariable Textvariable/],
		-tooltip    => [qw/METHOD tooltip ToolTip/],
		-underline	=> [qw/METHOD underline Underline/],
		-usegd      => [qw/METHOD usegd UseGD/],
		-verticaltext  => [qw/METHOD verticaltext VerticalText/],
		-width		=> [qw/METHOD width Width/],
		-wraplength => [qw/METHOD wraplength Wraplength/, 0],
	);
#
#	force a default font
#
    my $font_name = $self->optionGet('font', '*');
    my $font;
    if (!defined $font_name) {
		my $l = $self->Label;
		$font = $self->fontCreate($self->fontActual($l->cget('-font')));
		$l->destroy;
    }
    else {
		$font = $self->fontCreate($self->fontActual($font_name));
    }
	$self->{_font} = $font;
#
#	force our background to be transparent
#
	$self->SUPER::configure(-background => '');
    $self->_layoutRequest(1);
}

sub textvariable {
	my ($self, $vref) = @_;

	return $self->{_textvariable}
		unless defined($vref);

	use Tie::Watch;

	my $st = [ sub {
		my ($watch, $new_val) = @_;
		my $argv = $watch->Args(-store);
		$argv->[0]->{_text} = $new_val;
		$watch->Store($new_val);
		$argv->[0]->_layoutRequest(2);
		}, $self ];

	$self->{_watch} = Tie::Watch->new(-variable => $vref, -store => $st);
	$self->OnDestroy( [sub { $_[0]->{_watch}->Unwatch; }, $self] );
	$self->{_textvariable} = $vref;
}

sub activeimage {
	my ($self, $arg) = @_;
	return $self->{_activeimage} unless defined($arg);
	$self->{_activeimage} = $arg;
	$self->_layoutRequest(1)
		if ($self->{_style} eq 'image');
	return $arg;
}

sub anchor {
	my ($self, $arg) = @_;
	return $self->{_anchor} unless defined($arg);
	$self->{_anchor} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub angle {
	my ($self, $arg) = @_;
	return $self->{_angle} unless defined($arg);
	$self->{_angle} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub background {
	my ($self, $arg) = @_;
	return $self->{_background} unless defined($arg);
	$self->{_background} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub bitmap {
	my ($self, $arg) = @_;
	return $self->{_bitmap} unless defined($arg);
	$self->{_bitmap} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub compound {
	my ($self, $arg) = @_;
	return $self->{_compound} unless defined($arg);
	$self->{_compound} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub dispersion {
	my ($self, $arg) = @_;
	return $self->{_dispersion} unless defined($arg);
	$self->{_dispersion} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub font {
	my ($self, $arg) = @_;
	return $self->{_font} unless defined($arg);
	$self->{_font} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub foreground {
	my ($self, $arg) = @_;
	return $self->{_foreground} unless defined($arg);
	$self->{_foreground} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub height {
	my ($self, $arg) = @_;
	return $self->SUPER::cget('-height') unless defined($arg);
	$self->{_height} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub idleimage {
	my ($self, $arg) = @_;
	return $self->{_idleimage} unless defined($arg);
	$self->{_idleimage} = $arg;
	$self->_layoutRequest(1)
		if ($self->{_style} eq 'image');
	return $arg;
}

sub image {
	my ($self, $arg) = @_;
	return $self->{_image} unless defined($arg);
	$self->{_image} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub justify {
	my ($self, $arg) = @_;
	return $self->{_justify} unless defined($arg);
	$self->{_justify} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub orient {
	my ($self, $arg) = @_;
	return $self->{_orient} unless defined($arg);
	$self->{_orient} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub padx {
	my ($self, $arg) = @_;
	return $self->{_padx} unless defined($arg);
	$self->{_padx} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub pady {
	my ($self, $arg) = @_;
	return $self->{_pady} unless defined($arg);
	$self->{_pady} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub shape {
	my ($self, $arg) = @_;
	return $self->{_shape} unless defined($arg);
	$self->{_shape} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub style {
	my ($self, $arg) = @_;
	return $self->{_style} unless defined($arg);
	$self->{_style} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub state {
	my ($self, $arg) = @_;
	return $self->{_state} unless defined($arg);
	$self->{_state} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub text {
	my ($self, $arg) = @_;
	return $self->{_text} unless defined($arg);
	$self->{_text} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub tooltip {
	my ($self, $arg) = @_;
	return $self->{_tooltip} unless defined($arg);
	$self->{_tooltip} =
		(ref $arg && (ref $arg eq 'ARRAY')) ? $arg :
		[ $arg, 300 ];	# use 300 msec default delay
#
#	see if we've got a ballon yet
#	NOTE: we use a package variable for this, in order
#	to minimize the number of balloons created
#
    $balloon = $self->Balloon(-background => 'white')
		unless $balloon;

	$self->_layoutRequest(1);
	return $arg;
}

sub underline {
	my ($self, $arg) = @_;
	return $self->{_underline} unless defined($arg);
	$self->{_underline} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub usegd {
	my ($self, $arg) = @_;
	return $self->{_usegd} unless defined($arg);
	return undef if ($arg && (!$hasgd));
	$self->{_usegd} = $arg;
#	$self->_layoutRequest(1);
	return $arg;
}
#
#	indicates whether vertical text in sideways
#	buttons should be rendered in GD or not;
#	valid values are 'GD', 'Tk', or undef, default 'Tk'
#	Note that 'Tk' causes text to be rendered
#	vertically top to bottom, whereas GD causes
#	text to be rendered as an image and then rotate 90 degs.
#	undef causes the text to be laid out in Tk, but in
#	the usual horizontal rendering.
#
sub verticaltext {
	my ($self, $arg) = @_;
	return $self->{_verticaltext} unless defined($arg);
	return undef if ($arg && ($arg eq 'GD') && (!$hasgd));
	$self->{_verticaltext} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub width {
	my ($self, $arg) = @_;
	return $self->SUPER::cget('-width') unless defined($arg);
	$self->{_width} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

sub wraplength {
	my ($self, $arg) = @_;
	return $self->{_wraplength} unless defined($arg);
	$self->{_wraplength} = $arg;
	$self->_layoutRequest(1);
	return $arg;
}

#######################################################
#
#	widget methods
#
#######################################################
#
#	return button image as scalar data rendered via GD
#	(if GD available)
#
sub capture {
	$@ = 'GD or GD::Text not available.',
	return undef
		unless $hasgd;

	my $self = shift;
	my %args = @_;
	$args{-format} = defined($args{-format}) ? 'png' : lc $args{-format};

	croak 'Invalid -format ' . $args{-format}
		unless ($args{-format} eq 'png') ||
			($args{-format} eq 'gif') ||
			($args{-format} eq 'jpeg');

	my ($activeimg, $activecoords, $idleimg, $idlecoords) =
		$self->_renderButton(1, $args{-gdfont}, $args{-omittext}, $args{-omitimage});

	return undef unless $activeimg && $idleimg;
	my $method = $args{-format};
	return ($activeimg->$method(), $activecoords, $idleimg->$method(), $idlecoords);
}
#
#	alternate bright/dark versions at a specified interval;
#	if interval is not defined, use Button behavior
#	(3 quick flashes), else flash at interval until
#	flash(0)
#
sub flash {
	my ($self, $intvl) = @_;

	return 1
		if ($self->cget('-state') eq 'disabled');
#
#	reset any existing flash; should make sure
#	the raised image is the right one!!!
#
	$self->{_flash}[0]->cancel,
	delete $self->{_flash}
		if exists($self->{_flash});
#
#	if no defined interval, then do Button version
#
	$self->{_flash} = [ $self->repeat(100, [ '_flash', $self ]), 3, 0 ]
		unless defined($intvl);

	return $self
		unless $intvl;

	$self->{_flash} = [ $self->repeat($intvl, [ '_flash', $self ]), -1, 0 ];
	return $self;
}
#
#	emulate button press
#
sub invoke {
	my $self = shift;

	return 1
		if ($self->cget('-state') eq 'disabled');

	$self->_OnEnter;
	$self->idletasks;
	$self->after(100);
	$self->_OnLeave;
	$self->Callback(-command => $self);
}
#
#	some widget method overrides to make sure things
#	get associated with the image, not the canvas
#
sub focus {
#	$_[0]->focus($_[0]->{_bind_group});
#	$_[0]->{_bind_group}->focus();
}

sub bind {
	my $self = shift;
	my $event = shift;
	return $notkeymouse_event{$event} ?
		$self->CanvasBind($event, @_) :
		$self->SUPER::bind($self->{_bind_group}, $event, @_);
}
#
#	accessor for the bind_group, so e.g.,
#	balloons can be attached
#
sub get_bindtag {
	return $_[0]->{_bind_group};
}

#######################################################
#
#	private methods
#
#######################################################
sub _flash {
	my $self = shift;

#print "flash Exists!!!\n" if exists $self->{_flash};
#print "Not Exists!!!\n" unless exists $self->{_flash};

	return 1 unless exists($self->{_flash});

	$self->{_flash}->[0]->cancel,
	$self->lower($self->{_active_group}, $self->{_idle_group}),
	delete $self->{_flash},
	return 1
		unless $self->{_flash}[1];

	$self->{_flash}[1]-- if ($self->{_flash}[1] > 0);

	if ($self->{_flash}[2]) {
		$self->lower($self->{_active_group}, $self->{_idle_group});
		$self->{_flash}[2] = 0;
	}
	else {
		$self->lower($self->{_idle_group}, $self->{_active_group});
		$self->{_flash}[2] = 1;
	}

	return 1;
}

sub _OnEnter
{
	my $self = shift;

print "Entered\n"
	if $self->{_debug};

#
#	ButtonPress is invoking Enter as well, so flag and ignore it
#
	delete $self->{_pressed},
	return 1
		if $self->{_pressed};

	return 1
		if ($self->cget('-state') eq 'disabled');
#
#	cancel any flash
#
	$self->flash(0);

	$self->lower($self->{_idle_group}, $self->{_active_group});
	return 1;
}

sub _OnLeave
{
	my $self = shift;

print "Left\n"
	if $self->{_debug};
#
#	ButtonRelease is invoking Leave as well, so flag and ignore it
#
	delete $self->{_released},
	return 1
		if $self->{_released};
#
#	cancel any flash
#
	$self->flash(0);

	$self->lower($self->{_active_group}, $self->{_idle_group});
	return 1;
}

sub _OnPress
{
	my $self = shift;

print "Pressed\n"
	if $self->{_debug};

	return 1
		if ($self->cget('-state') eq 'disabled');
#
#	cancel any flash
#
	$self->flash(0);

	$self->lower($self->{_active_group}, $self->{_idle_group});
#	$self->{_pressed} = 1;
	return 1;
}

sub _OnRelease
{
	my $self = shift;

print "Released\n"
	if $self->{_debug};

	return 1
		if ($self->cget('-state') eq 'disabled');
#
#	cancel any flash
#
	$self->flash(0);

	$self->lower($self->{_idle_group}, $self->{_active_group});
	$self->Callback(-command => $self->cget('-command'));
#	$self->{_released} = 1;
#	delete $self->{_pressed};
}
#
#	queue up a redraw
#
sub _layoutRequest {
    my $self = shift;
    $self->afterIdle(['_renderButton', $self])
    	unless $self->{_pending};
    $self->{_pending} |= $_[0] if $_[0];
}
#
#	(re)draw the button
#
sub _renderButton {
	my ($self, $usegd, $gdfont, $notext, $noimage) = @_;

	$self->{_pending} = 0;
	my ($angle, $disperse, $compound, $shape, $style, $orient) = (
		$self->cget('-angle'),
		$self->cget('-dispersion'),
		$self->cget('-compound'),
		$self->cget('-shape'),
		$self->cget('-style'),
		$self->cget('-orient'),
	);

	print join("\n", $angle, $disperse, $shape, $style), "\n"
		if $self->{_debug};
#
#	validate our widget specific options
#
	croak "Invalid -angle option $angle; must be between 0 and 1"
		if ($angle < 0) || ($angle > 1);

	croak "Invalid -dispersion option $disperse; must be between 0 and 1"
		if ($disperse < 0) || ($disperse > 1);

	croak "Invalid -compound option $compound"
		unless $valid_compound{$compound};

	croak "Invalid -shape option $shape"
		unless $valid_shapes{$shape};

	croak "Invalid -style option $style"
		unless $valid_styles{$style};

	croak "Invalid -orient option $orient"
		if (($shape eq 'bevel') || ($shape eq 'folio')) &&
			(! $valid_orient{$orient});
#
#	cancel any flash
#
	$self->flash(0);
#
#	create 3 versions: active(bright), idle(dark), and binding(transparent)
#
	$self->delete('all'),
	delete $self->{_active_group},
	delete $self->{_idle_group},
	delete $self->{_bind_group}
		if $self->{_active_group};
#
#	force our background to be transparent
#
#	$self->SUPER::configure(-background => '');
	my $bg = $self->cget('-background') || $self->Parent->cget('-background');

	my $rgb = $self->rgb($bg)
		|| croak "Invalid background color value";
	my @active = @$rgb;

	foreach (0..2) {
		$active[$_] = $active[$_] + int((65535 - $active[$_]) * 0.4);
		$active[$_] = 0xFFFF if ($active[$_] > 0xFFFF);
	}
#
#	if we have some text, compute bbox for it
#
	$self->{_text} = ${$self->{_textvariable}}
		if $self->{_textvariable};

	my ($w, $h, $xl, $yl, $xh, $yh, $textw, $texth) = (0,0,0, 0, 100, 100, 0, 0);

	my ($bitmap, $image, $text) =
		($self->cget('-bitmap'), $self->cget('-image'), $self->cget('-text'));
	($w, $h) = $self->_computeBBox(),
	$xh = $w + ($self->cget('-padx') << 1),
	$yh = $h + ($self->cget('-pady') << 1)
		if ($bitmap || $image || defined($text));

#	$usegd = 0 unless $usegd;
#	print "usegd $usegd $w $h\n";

#
#	for round buttons, compute diameter based on hypoteneuse of bbox
#
	$xh = $yh = _round(sqrt(($yh ** 2) + ($xh ** 2)))
		if ($shape eq 'round');
#
#	if rendering an image button, compute any scaling
#
	my ($xscale, $yscale) = (1,1);
	($xscale, $yscale, $xh, $yh) = $self->_getImageScales($xh, $yh)
		if ($style eq 'image');
#
#	if rendering for capture just get the images
#	NOTE: in future we may want to render the images *and*
#	display in Tk
#	NOTE2: we don't create a binding group for this
#		but we do return the binding coordinates
#
	return ($style eq 'image') ?
		($self->_drawGdButton($xh, $yh, $xscale, $yscale,
			$self->cget('-activeimage'), $gdfont, $notext, $noimage),
		$self->_drawGdButton($xh, $yh, $xscale, $yscale,
			$self->cget('-idleimage'), $gdfont, $notext, $noimage)) :

		($self->_drawGdButton($xh, $yh, @active, $gdfont, $notext, $noimage),
		$self->_drawGdButton($xh, $yh, @$rgb, $gdfont, $notext, $noimage))
		if $usegd;
#
#	update geometry: force to any -width or -height
#
	my $ew = $self->{_width} || $xh + 4;
	my $eh = $self->{_height} || $yh + 4;
	$orient = $self->cget('-orient');
	if ((($shape eq 'bevel') || ($shape eq 'folio') || ($shape eq 'rectangle')) &&
		((index($orient, 'w') == 0) || (index($orient, 'e') == 0))) {
#		print "geometry is $eh, $ew\n";
		$self->GeometryRequest($eh,$ew);
	}
	else {
		$self->GeometryRequest($ew,$eh);
	}

	($self->{_active_group}, $self->{_idle_group}) = ($style eq 'image') ?
		($self->_drawTkButton($xh, $yh, $xscale, $yscale, $self->cget('-activeimage'), $notext, $noimage),
		$self->_drawTkButton($xh, $yh, $xscale, $yscale, $self->cget('-idleimage'), $notext, $noimage)) :
		($self->_drawTkButton($xh, $yh, @active, $notext, $noimage),
	 	$self->_drawTkButton($xh, $yh, @$rgb, $notext, $noimage));
#
#	create binding area for the button
#
	$self->_bindFromImage($xh, $yh, $xscale, $yscale);

	$self->_scaleButtons($xh, $yh)
		if ($self->{_width} || $self->{_height});

    $balloon->attach($self,
    	-initwait        => $self->{_tooltip}[1],
       	-balloonposition => 'mouse',
       	-msg             => { $self->{_bind_group} => $self->{_tooltip}[0] }
    )
    	if $self->{_tooltip};
}

sub _scaleButtons {
	my ($self, $xh, $yh) = @_;
#
#	scale the image if we have explicit dimensions
#
	my $ew = $self->{_width} || $xh;
	my $eh = $self->{_height} || $yh;
	my ($scalex, $scaley) = ($ew/$xh, $eh/$yh);
#
#	do we need to impose the final dimensions ?
#
#	$self->SUPER::configure(-width => $ew, -height => $eh);

	$self->scale($_, 0, 0, $scalex, $scaley)
		foreach ($self->{_active_group}, $self->{_idle_group}, $self->{_bind_group});
	return $self;
}
#
#	compute image scales
#
sub _getImageScales {
	my ($self, $xh, $yh) = @_;

	my ($activeimg, $idleimg) =
		($self->cget('-activeimage'), $self->cget('-idleimage'));

	croak "Missing -activeimage for -style => 'image' option"
		unless $activeimg;

	croak "Missing -idleimage for -style => 'image' option"
		unless $idleimg;

	my ($aw, $ah, $iw, $ih) =
		($activeimg->width(), $activeimg->height(),
		$idleimg->width(), $idleimg->height());

	my ($minw, $minh, $maxw, $maxh) =
		((($aw > $iw) ? $iw : $aw), (($ah > $ih) ? $ih : $ah),
		(($aw > $iw) ? $aw : $iw), (($ah > $ih) ? $ah : $ih));
#
#	if images smaller than the text/image bbox,
#	scale them up
#
	my ($xscale, $yscale) = (
		(($minw < $xh) ? $xh/$minw : 1),
		(($minh < $yh) ? $yh/$minh : 1));

	return ($xscale, $yscale, $maxw * $xscale, $maxh * $yscale);
}

sub _drawRectangle {
	my ($xh, $yh, $curve) = @_;
	return (0, 0, $xh, 0, $xh, $yh, 0, $yh);
}

sub _drawBevel {
	my ($xh, $yh, $curve, $orient) = @_;

	my $top = ((index($orient, 'n') == 0) || (index($orient, 'w') == 0));
	my $d = _round(0.2 * $xh);
#
#	returns array of endpoints
#
	my $side = ((index($orient, 's') == 1) || (index($orient, 'w') == 1));
	return $top ?
		($side ?
			(0, 0, $xh - $d, 0, $xh, $yh, 0, $yh) :
			($d, 0, $xh, 0, $xh, $yh, 0, $yh)) :
		($side ?
			(0, 0, $xh, 0, $xh - $d, $yh, 0, $yh) :
			(0, 0, $xh, 0, $xh, $yh, $d, $yh));
}

sub _drawFolio {
	my ($xh, $yh, $curve, $orient) = @_;

	my $top = ((index($orient, 'n') == 0) || (index($orient, 'w') == 0));
	my $d = _round(0.1 * $xh);
#
#	returns array of endpoints
#
	return $top ?
			($d, 0, $xh - $d, 0, $xh, $yh, 0, $yh) :
			(0, 0, $xh, 0, $xh - $d, $yh, $d, $yh);
}

sub _getGDImage {
	my $image = shift;

	my $imgdata = $image->data(-format => 'png');
	$imgdata = decode_base64($imgdata);
	my $gdimg = GD::Image->new($imgdata);
	$@ = "Unable to convert image",
	return undef
		unless $gdimg;

	return $gdimg;
}

sub _setGDImage {
	my ($self, $image) = @_;

	return $self->Photo(-data => encode_base64($image->png()), -format => 'png');
}

sub _getTkCoords {
	my ($self, $xh, $yh, $bitmap, $image, $text, $compound) = @_;

	my ($imgw, $imgh) =
		$image ? ($image->width, $image->height) :
		$bitmap ? $self->_getBitmapSize($bitmap) :
		(0,0);

	my ($padx, $pady, $imgx, $imgy, $textx, $texty, $textw, $texth) = (
		$self->{_padx}, $self->{_pady},
		($xh >> 1), ($yh >> 1),
		($xh >> 1), ($yh >> 1),
		0, 0);

	unless (($compound eq 'none') || ($compound eq 'center')) {
		$imgy = ($compound eq 'top') ? $pady + ($imgh >> 1):
			($compound eq 'bottom') ? $yh - 4 - $pady - ($imgh >> 1) : $imgy,
		$imgx = ($compound eq 'left') ? $padx + ($imgw >> 1) :
			($compound eq 'right') ? $xh - 4 - $padx - ($imgw >> 1) : $imgx;

		if (defined($text) &&
			(($self->{_shape} ne 'round') ||
				($compound eq 'left') || ($compound eq 'right'))) {
			($textw, $texth) = $self->_computeTextBBox();
			$texty = ($compound eq 'top')  ? $imgy + 4 + ($texth >> 1) :
				($compound eq 'bottom') ? ($texth >> 1) + $pady : $texty;
			$textx = ($compound eq 'left') ? $imgx +($imgw >> 1) + 4 + ($textw >> 1) :
				($compound eq 'right') ? $padx + ($textw >> 1) : $textx;
		}
#
# realign the image to cuddle the text
#
		$imgy = ($compound eq 'top') ? $yh >> 2 : ($yh >> 2) + ($yh >> 1)
			if (($self->{_shape} eq 'round') &&
				(($compound eq 'top') || ($compound eq 'bottom')));
	}
	return ($imgx, $imgy, $textx, $texty, $textw, $texth);
}
#
#	NOTE: we don't support bitmaps w/ GD...
#
sub _getGdCoords {
	my ($self, $xh, $yh, $image, $text, $compound) = @_;
	my ($imgw, $imgh) = $image ? ($image->width, $image->height) : (0,0);
	my ($padx, $pady, $imgx, $imgy, $textx, $texty, $textw, $texth) = (
		$self->{_padx}, $self->{_pady},
		($xh - $imgw) >> 1, ($yh - $imgh) >> 1,
		$xh >> 1, $yh >> 1,
		0,0);

	unless (($compound eq 'none') || ($compound eq 'center')) {
		$imgy = ($compound eq 'top') ? $pady :
			($compound eq 'bottom') ? $yh + 4 - $pady - $imgh : $imgy,
		$imgx = ($compound eq 'left') ? $padx :
			($compound eq 'right') ? $xh + 4 - $padx - $imgw : $imgx;

		if (defined($text) &&
			(($self->{_shape} ne 'round') ||
				($compound eq 'left') || ($compound eq 'right'))) {
			($textw, $texth) = $self->_computeTextBBox();
			$texty = ($compound eq 'top')  ? $imgy + 4 + ($texth >> 1) :
				($compound eq 'bottom') ? ($texth >> 1) + $pady : $texty;
			$textx = ($compound eq 'left') ? $imgx +($imgw >> 1) + 4 + ($textw >> 1) :
				($compound eq 'right') ? $padx + ($textw >> 1) : $textx;
		}
#
# realign the image to cuddle the text
#
		$imgy = ($compound eq 'top') ? ($yh >> 2 - ($imgh >> 1)) :
			($yh >> 2) + ($yh >> 1) - ($imgh >> 1)
			if (($self->{_shape} eq 'round') &&
				(($compound eq 'top') || ($compound eq 'bottom')));
	}
	return ($imgx, $imgy, $textx, $texty, $textw, $texth);
}

sub _drawTkButton {
	my ($self, $xh, $yh, $r, $g, $b, $notext, $noimage) = @_;

	my ($xl, $yl, $shape, $style, $angle, $disperse, $slots, $text, $bitmap, $image, $orient) = (
		0, 0, $self->cget('-shape'), $self->cget('-style'), $self->cget('-angle'),
		$self->cget('-dispersion'), 15, $self->cget('-text'), $self->cget('-bitmap'),
		$self->cget('-image'), $self->cget('-orient'));

	my $compound = ($image || $bitmap) ? $self->cget('-compound') : 'center';
#
#	compute locations of image and/or text
#	we're in luck, GD and Tk use same methodnames for image bounds
#
	my ($imgw, $imgh) = $image ? ($image->width, $image->height) :
		$bitmap ? $self->_getBitmapSize($bitmap) :
		(0,0);

	my ($imgx, $imgy, $textx, $texty, $textw, $texth) =
		$self->_getTkCoords($xh, $yh, $bitmap, $image, $text, $compound);

	my $group;
	my @clines = ();
	my ($colors, $lcolors, $offsets, $top, $bottom, $white, $black, $basecolor, $vert, $textfactor);
	my @endpts = ();
	unless ($style eq 'image') {
#
#	for GD compatibility, use middle color as base
#
		($colors, $lcolors, $offsets, $top, $bottom, $white, $black) =
			$self->_getColorMap($xh, $yh, $r, $g, $b);

		my $midpt = (scalar @$colors) >> 1;
		$basecolor = sprintf("#%04X%04X%04X", @{$colors->[$midpt]});

		my $curve = 6;
		$vert = (($shape eq 'bevel') || ($shape eq 'folio') || ($shape eq 'rectangle')) &&
			((substr($orient, 0, 1) eq 'w') || (substr($orient, 0, 1) eq 'e'));
		$textfactor = ((substr($orient, 1, 1) eq 'e') || (substr($orient, 1, 1) eq 's')) ? 1.2 : 0.8
			if ($shape eq 'bevel');
		@endpts =
			($shape eq 'rectangle') ? _drawRectangle($xh, $yh, $curve) :
			($shape eq 'bevel') ? _drawBevel($xh, $yh, $curve, $orient) :
			($shape eq 'folio') ? _drawFolio($xh, $yh, $curve, $orient) :
			();
	}

	if ($style eq 'image') {
#
#	create from an image; r, g, b are xscale, yscale, and the image,
#	respectively
#
		my $bgimg = $self->createImage($xh>>1, $yh>>1, -image => $b);
		$self->scale($bgimg, 0, 0, $r, $g)
			unless ($r == 1) && ($g == 1);
		push @clines, $bgimg;
	}
	elsif ($shape eq 'round') {
		my $extent = 180;
		my $start = 0;

		push @clines, $self->createOval(
			0, 0, $xh, $yh,
			-outline => $basecolor,
			-fill => $basecolor);

		unless ($self->{_style} eq 'flat') {
			push @clines, $self->createOval(
				1, 1, $xh - 1, $yh - 1,
				-outline => 'grey');

			push @clines, $self->createOval(
				2, 2, $xh - 2, $yh - 2,
				-outline => 'black');

			push @clines, $self->createOval(
				3, 3, $xh - 3, $yh - 3,
				-outline => 'grey');

			push @clines, $self->createOval(
				4, 4, $xh - 4, $yh - 4,
				-outline => 'grey');

			$yl = 3;
			$yh -= 3;
			$xl = 3;
			$xh -= 3;
			my ($byl, $byh)  = ($yl, $yh);
			my $i = 0;
			while (($i < scalar @$lcolors) && ($yh - $yl > 0)) {
				push @clines, $self->createArc(
					$xl, $yl, $xh, $yh,
					-start => int($start),
					-extent => $extent,
					-outline => $$lcolors[4+$i++],
					-style => 'arc');
				$yl++; $yh--;

				$i++, next
					unless ($i%6 == 1);

				push @clines, $self->createArc(
					$xl, $byl, $xh, $byh,
					-start => 200+int($start),
					-extent => $extent-40,
					-outline => $$lcolors[$i++],
					-style => 'arc');
				$byl++; $byh--;
			}
		}
	}
	elsif ($shape eq 'oval') {
		push @clines,
			$self->createLine(
				$offsets->[$_ - $bottom],
				$_,
				$xh - $offsets->[$_ - $bottom],
				$_,
				-fill => shift @$lcolors),
			$self->createLine(
				$offsets->[$_ - $bottom],
				$_,
				$offsets->[$_ - $bottom] + 2,
				$_,
				-fill => $basecolor),
			$self->createLine(
				$xh - $offsets->[$_ - $bottom] - 2,
				$_,
				$xh - $offsets->[$_ - $bottom],
				$_,
				-fill => $basecolor)
			foreach ($bottom..$top);

		push @clines,
			$self->createLine(
				$offsets->[$_ - $bottom],
				$_,
				$xh - $offsets->[$_ - $bottom],
				$_,
				-fill => $basecolor)
			foreach ($top+1..$yh);
	}
	else {
		if ($vert) {
#
#	rotate endpts
#
			my @rotpts = $self->_rotateShape($xh, @endpts);

			push @clines, $self->createPolygon(@rotpts, -fill => $basecolor);

			my $lfactor = ($endpts[7] - $endpts[1])/$xh;
			my $rfactor = ($endpts[5] - $endpts[3])/$xh;
			my ($low, $hi) = ($rotpts[1], $rotpts[7]);

#			print "bottom: $bottom top: $top lines: ", scalar @$offsets, "\n";

			$low -= $lfactor,
			$hi += $rfactor,
			push @clines,
				$self->createLine(
					$_, _round($low + $offsets->[$_ - $bottom]),
					$_, _round($hi - $offsets->[$_ - $bottom]),
					-fill => shift @$lcolors)
 				foreach ($bottom..$top);
		}
		else {
			push @clines, $self->createPolygon(@endpts, -fill => $basecolor);

			my $lfactor = ($endpts[0] - $endpts[6])/$yh;
			my $rfactor = ($endpts[4] - $endpts[2])/$yh;
			my ($low, $hi) = ($endpts[0], $endpts[2]);

			$low -= $lfactor,
			$hi += $rfactor,
			push @clines,
				$self->createLine(
					_round($low + $offsets->[$_ - $bottom]), $_,
					_round($hi - $offsets->[$_ - $bottom]), $_,
					-fill => shift @$lcolors)
				foreach ($bottom..$top);
		}
	}
#
#	add image and/or text: compute the locations based on -compound
#
	my ($imgid, $textid, $ulid);
	my @addons = ();
	unless ($notext) {
		if (defined($text) && ($text ne '') &&
			((!$bitmap && !$image) ||
			($self->{_compound} ne 'none'))) {
#
#	for bevel, move text away from bevel edge
#
			if ($shape eq 'bevel') {
				$texty = int($texty * $textfactor)
					if $vert;
				$textx = int($textx * $textfactor)
					unless $vert;
			}
			if ($self->cget('-underline')) {
				$ulid = $self->_underlineText($textx, $texty, $text);
				unshift @addons, $ulid
					if $ulid;
			}
			if ($vert) {
				my $type = $self->cget('-verticaltext');
				if ($type && (uc $type eq 'GD') && $hasgd) {
					$textid = $self->createImage(
#						$texty, $xh - $textx,
						4, $xh - $textx,
						-image => $self->_setGDImage($self->_renderVerticalGdText($text)));
				}
				else {
					$textid = $type ?
						$self->createText($textx, $texty,
							-anchor => 'center',
							-text => $text,
							-fill => $self->cget('-foreground'),
#							-width => $self->cget('-wraplength'),
#							-justify => $self->cget('-justify'),
							-font => $self->cget('-font')) :

						$self->createText($textx, $texty,
							-anchor => 'center',
							-text => $text,
							-fill => $self->cget('-foreground'),
							-width => $self->cget('-wraplength'),
							-justify => $self->cget('-justify'),
							-font => $self->cget('-font'));
				}
			}
			else {
				$textid = $self->createText($textx, $texty,
					-anchor => 'center',
					-text => $text,
					-fill => $self->cget('-foreground'),
					-width => $self->cget('-wraplength'),
					-justify => $self->cget('-justify'),
					-font => $self->cget('-font'));
			}
			unshift @addons, $textid;
		}
	}

	unless ($noimage) {
		if ($shape eq 'bevel') {
			$imgy = int($imgy * $textfactor)
				if $vert;
			$imgx = int($imgx * $textfactor)
				unless $vert;
		}
		$imgid = $image ? $self->createImage($imgx, $imgy, -image => $image) :
			$self->createBitmap($imgx, $imgy, -bitmap => $bitmap),
		$self->lower($textid, $imgid),
		unshift @addons, $imgid
			if ($image || $bitmap);
	}

	return $self->createGroup(0,0, -members => [ @clines, @addons ]);
}
#
#	renders the button via GD; returns bot the button image and
#	the image binding coordinates
#
sub _drawGdButton {
	my ($self, $xh, $yh, $r, $g, $b, $gdfont, $notext, $noimage) = @_;

	my ($xl, $yl, $shape, $style, $angle, $disperse, $slots, $text, $image, $orient) = (
		0, 0, $self->cget('-shape'), $self->cget('-style'), $self->cget('-angle'),
		$self->cget('-dispersion'), 15, $self->cget('-text'), $self->cget('-image'),
		$self->cget('-orient'));

	my $compound = $image ? $self->cget('-compound') : 'center';
#
#	compute locations of image and/or text
#
	my ($padx, $pady) = ($self->cget('-padx'), $self->cget('-pady'));
#
#	if there's an image, and we're using GD, get its data into a GD image
#
	if ($image) {
		$image = _getGDImage($image);
		return undef unless $image;
	}
#
#	we're in luck, GD and Tk use same methodnames for image bounds
#
	my ($imgw, $imgh) = $image ? ($image->width, $image->height) : (0,0);

	my ($imgx, $imgy, $textx, $texty, $textw, $texth) =
		$self->_getGdCoords($xh, $yh, $image, $text, $compound);

	my $vert = (($shape eq 'bevel') || ($shape eq 'folio') || ($shape eq 'rectangle')) &&
		((index($orient, 'w') == 0) || (index($orient, 'e') == 0));

	my $btnimg = $vert ? GD::Image->new($yh, $xh) : GD::Image->new($xh, $yh);

	my $curve = 6;
	my @endpts = ();

	my ($colors, $lcolors, $offsets, $top, $bottom, $white, $black, $midpt, $basecolor, $textfactor);
	my %gdcolors = ();
#
#	alloc transparent color
#
	my $transparent = $btnimg->colorAllocate(1, 1, 1);
	$btnimg->transparent($transparent);

	$vert ?
		$btnimg->filledRectangle(0,0,$yh - 1,$xh - 1, $transparent) :
		$btnimg->filledRectangle(0,0,$xh - 1,$yh - 1, $transparent);

	unless ($style eq 'image') {
#
#	must explicitly allocate colors for GD,
#	so we'll create a map of the slotted color strings
#	to their GD index...and add the transparent color
#	must have a GD image object to allocate
#	NOTE: may need to alloc for text ??
#
		($colors, $lcolors, $offsets, $top, $bottom, $white, $black) =
			$self->_getColorMap($xh - 2, $yh - 2, $r, $g, $b);

		foreach (@$colors) {
#
#	make sure we don't collide transparent with existing
#
			$gdcolors{sprintf('#%04X%04X%04X', @$_)} =
				$btnimg->colorAllocate(
					($_->[0] >> 8) & 0xFF,
					($_->[1] >> 8) & 0xFF,
					($_->[2] >> 8) & 0xFF),
			next
				unless (($_->[0] == 256) && ($_->[1] == 256) && ($_->[2] == 256));
#
#	preserve original key since we've alreayd computed
#	the line colors based on the original
#
			$gdcolors{'#010001000100'} = $btnimg->colorAllocate(1, 1, 2),
		}
#
#	use midpt as base color
#
		$midpt = (scalar @$colors) >> 1;
		$basecolor = $gdcolors{sprintf('#%04X%04X%04X', @{$colors->[$midpt]})};
#
#	now xlate any line colors to the indexes
#
		$lcolors->[$_] = $gdcolors{$lcolors->[$_]}
			foreach (0..$#$lcolors);

		$textfactor = ((substr($orient, 1, 1) eq 'e') || (substr($orient, 1, 1) eq 's')) ? 1.2 : 0.8
			if ($shape eq 'bevel');
		@endpts =
			($shape eq 'rectangle') ? _drawRectangle($xh - 2, $yh - 2, $curve) :
			($shape eq 'bevel') ? _drawBevel($xh, $yh, $curve, $orient) :
			($shape eq 'folio') ? _drawFolio($xh, $yh, $curve, $orient) :
			();
	}

	if ($style eq 'image') {
#
#	create from an image; r, g, b are xscale, yscale, and the image,
#	respectively
#
		my $format = $b->cget('-format');
		my $data = $b->data(-format => $format);
		my $bgimg = ($format eq 'GIF') ? GD::Image->newFromGif($data) :
			($format eq 'PNG') ? GD::Image->newFromPng($data) :
			GD::Image->newFromJpeg($data); # ($format eq 'JPEG')

		if (($r == 1) && ($g == 1)) {
			$btnimg->copy($bgimg, 2, 2, 0, 0, $bgimg->width, $bgimg->height);
		}
		else {
			$btnimg->copyResampled($bgimg, 2, 2, 0, 0,
				$btnimg->width - 2, $btnimg->height - 2,
				$bgimg->width, $bgimg->height);
		}
	}
	elsif ($shape eq 'round') {
		my $extent = 180;
		my $start = 270;
#
#	get the closest to black and grey
#
		$black = $btnimg->colorClosest(0,0,0);
		my $grey = $btnimg->colorClosest(64, 64, 64);

		$btnimg->filledEllipse($xh>>1, $yh>>1, $xh, $yh, $basecolor);

		unless ($style eq 'flat') {
			$btnimg->ellipse($xh>>1, $yh>>1, $xh - 1, $yh - 2, $grey);
			$btnimg->ellipse($xh>>1, $yh>>1, $xh - 3, $yh - 4, $black);
#			$btnimg->ellipse($xh>>1, $yh>>1, $xh - 5, $yh - 6, $grey);
#			$btnimg->ellipse($xh>>1, $yh>>1, $xh - 7, $yh - 8, $grey);

			my ($cx, $cy) = (($xh - $xl)>>1, ($yh - $yl)>>1);
			$yl += 3;
			$yh -= 3;
			$xl += 3;
			$xh -= 3;
			my ($byl, $byh)  = ($yl, $yh);
			my $i = 0;
			while (($i < scalar @$lcolors) && ($yh - $yl > 0)) {
				$btnimg->arc($cx, $cy, $xh, $yh, 180, 360, $$lcolors[4+$i++]);
				$yl++; $yh--;

				$i++, next
					unless ($i%6 == 1);

				$btnimg->arc($cx, $cy, $xh, $byh, 20, 160, $$lcolors[$i++]);
				$byl++; $byh--;
			}
		}
	}
	elsif ($shape eq 'oval') {
#
#	this should be optimized to use a brush...
#
		$btnimg->line(
			$offsets->[$_ - $bottom], $_,
			$xh - $offsets->[$_ - $bottom], $_,
			shift @$lcolors),
		$btnimg->line(
			$offsets->[$_ - $bottom], $_,
			$offsets->[$_ - $bottom] + 2, $_,
			$basecolor),
		$btnimg->line(
			$xh - $offsets->[$_ - $bottom] - 2, $_,
			$xh - $offsets->[$_ - $bottom], $_,
			$basecolor)
			foreach ($bottom..$top);

		foreach ($top+1..$yh) {
			$btnimg->line(
				$offsets->[$_ - $bottom], $_,
				$xh - $offsets->[$_ - $bottom], $_,
				$basecolor)
				if defined $offsets->[$_ - $bottom];
		}
	}
	else {
#
#	need vert v horiz versions
#
		my $poly = GD::Polygon->new();
		my $i = 0;
		my $pad = 2;
		if ($vert) {
#
#	rotate endpts
#
			my @rotpts = $self->_rotateShape($xh, @endpts);

			$poly->addPt($rotpts[$i++], $rotpts[$i++])
				while ($i < scalar @rotpts);
			$btnimg->filledPolygon($poly, $basecolor);

			my $lfactor = ($endpts[7] - $endpts[1])/$xh;
			my $rfactor = ($endpts[5] - $endpts[3])/$xh;
			my ($low, $hi) = ($rotpts[1], $rotpts[7]);

			$low -= $lfactor,
			$hi += $rfactor,
			$btnimg->line(
				$_, _round($low) + $offsets->[$_ - $bottom] + $pad,
				$_, _round($hi) - $offsets->[$_ - $bottom] - ($pad - 1),
				shift @$lcolors)
				foreach ($bottom..$top);
		}
		else {
			$poly->addPt($endpts[$i++], $endpts[$i++])
				while ($i < scalar @endpts);
			$btnimg->filledPolygon($poly, $basecolor);

			my $lfactor = ($endpts[0] - $endpts[6])/$yh;
			my $rfactor = ($endpts[4] - $endpts[2])/$yh;
			my ($low, $hi) = ($endpts[0], $endpts[2]);

			$low -= $lfactor,
			$hi += $rfactor,
			$btnimg->line(
				_round($low + $offsets->[$_ - $bottom]) + $pad, $_,
				_round($hi - $offsets->[$_ - $bottom]) - ($pad - 1), $_,
				shift @$lcolors)
				foreach ($bottom..$top);
		}
	}
#
#	add image and/or text
#	copy in any embedded image first so text is on top
#
	if ($image && (!$noimage)) {
		if ($shape eq 'bevel') {
			$imgy = int($imgy * $textfactor)
				if $vert;
			$imgx = int($imgx * $textfactor)
				unless $vert;
		}
		$btnimg->copy($image, $imgx, $imgy, 0,0, $image->width, $image->height);
	}

	unless ($notext) {
		if (defined($text) && ($text ne '') &&
			(!$image || ($compound ne 'none'))) {

#
#	for bevel, move text away from bevel edge
#
			if ($shape eq 'bevel') {
				$texty = int($texty * $textfactor)
					if $vert;
				$textx = int($textx * $textfactor)
					unless $vert;
			}
#			if ($self->cget('-underline')) {
#				$ulid = $self->_underlineText($textx, $texty, $text);
#				unshift @addons, $ulid
#					if $ulid;
#			}

			$vert ?
				$self->_renderVerticalGdText($btnimg, $text, $textx, $texty, $textw, $gdfont) :
				$self->_renderGdText($btnimg, $text, $textx, $texty, $textw, $gdfont);

		}
	}
#
#	scale the image if we have explicit dimensions
#
	my $ew = $self->{_width} || $btnimg->width;
	my $eh = $self->{_height} || $btnimg->height;

	return ($btnimg, $self->_getBindCoords($ew, $eh))
		unless ($self->{_width} || $self->{_height});

	my $scaledimg = GD::image->new($ew, $eh);
#
#	we'll try resampling for now, maybe use resize later
#
	$scaledimg->copyResampled($btnimg, 0, 0, 0, 0, $ew, $eh,
		$btnimg->width, $btnimg->height);
	return ($scaledimg, $self->_getBindCoords($ew, $eh));
}

sub _getColorMap {
	my ($self, $xh, $yh, $r, $g, $b) = @_;
#
#	if horizontal, compute white pixel row position
#	in height
#
	my ($style, $shape, $angle, $slots) =
		($self->{_style}, $self->{_shape}, $self->{_angle}, 15);

	my $disperse = ($style eq 'gel') ? 1 : $self->{_dispersion} ;

	my ($maxr, $maxg, $maxb) = ($style eq 'flat') ?
		(0, 0, 0) : (65535 - $r, 65535 - $g, 65535 - $b);

	my $minfactor = ($shape eq 'oval') ? 0.50 :
		($style eq 'flat') ? 1 : 0.3;

	my ($minr, $ming, $minb) =
		(int($minfactor * $r), int($minfactor * $g), int($minfactor * $b));

	my ($pct, $white, $black);

	my $offsets = ($shape eq 'oval') ? _makeOval($yh) :
		(($shape eq 'rectangle') || ($shape eq 'folio') || ($shape eq 'bevel')) ?
			_makeIndents($yh) : undef;
#
#	compute the position of max brightness within the area
#
	($white, $black) = ($style eq 'gel') ?
		(($shape eq 'oval')  ?
			(int(0.25 * $yh), int(0.40 * $yh)) :
			(int(0.25 * $yh), int(0.3 * $yh))) :
		(int($angle * $yh), int($angle * $yh));
#
#	and the area of dispersion around the angle:
#	take max of (top, bottom) from white, then
#	set the limit based on disperse
#
	my ($bottom, $top) = (int($white - ($white * $disperse)),
		int($white + (($yh - $white) * $disperse)));
#
#	setup methods for color and drawing based on API
#
	my @colors = ();
#
#	split colors between fade to white and fade to black
#	to support gel
#
	$pct = ($_/$slots),
	push(@colors,
		[
			$minr + int($pct * ($r - $minr)),
			$ming + int($pct * ($g - $ming)),
			$minb + int($pct * ($b - $minb))
		])
		foreach (1..$slots);
	$pct = ($_/$slots),
	push(@colors,
		[
			int($r + $maxr * $pct),
			int($g + $maxg * $pct),
			int($b + $maxb * $pct)
		])
		foreach (1..$slots);
#
#	compute color increment per line from bottom to white, and white to top
#
	my @lcolors = ();

	if ($shape eq 'round') {
		unless ($style eq 'flat') {
			push @lcolors, _computeRGBComp->($style,
				$_ - $bottom,
				$white - $bottom,
				$r, $g, $b,
				$maxr, $maxg, $maxb,
				\@colors)
				foreach ($bottom..$white);

			push @lcolors, _computeRGBComp->($style,
				$top - $_,
				$top - $black,
				$r, $g, $b,
				$maxr, $maxg, $maxb,
				\@colors)
				foreach ($black+1..$top);
		}
	}
	elsif ($black != $white) {
		push @lcolors, _computeRGB->('round',
			$white - $_,
			$white - $bottom,
			$r, $g, $b,
			$maxr, $maxg, $maxb,
			\@colors)
			foreach ($bottom..$white);

		push @lcolors, _computeRGB->('round',
			$_ - $white,
			$black - $white,
			$r, $g, $b,
			-$r, -$g, -$b,
			\@colors)
			foreach ($white+1..$black);

		push @lcolors, _computeRGB->('round',
			$_ - $black,
			$top - $black,
			$minr, $ming, $minb,
			$r, $g, $b,
			\@colors)
			foreach ($black+1..$top);
	}
	else {
		push @lcolors, _computeRGB->($style,
			$_ - $bottom,
			$white - $bottom,
			$r, $g, $b,
			$maxr, $maxg, $maxb,
			\@colors)
			foreach ($bottom..$white);

		push @lcolors, _computeRGB->($style,
			$top - $_,
			$top - $black,
			$r, $g, $b,
			$maxr, $maxg, $maxb,
			\@colors)
			foreach ($black+1..$top);
	}

	return (\@colors, \@lcolors, $offsets, $top, $bottom, $white, $black);
}

sub _round { return (($_[0] - int($_[0])) > 0.5) ? int($_[0]) + 1 : int($_[0]); }

#################################################################
#
#	Color computations
#
#################################################################
sub _computeRGB {
	my ($style, $pos, $max, $r, $g, $b, $maxr, $maxg, $maxb, $slots) = @_;
	my $factor =
		($style eq 'shiny') ? (1 - abs(sin(PI + (PI_OVER_2 * ($max - $pos)/$max)))) :
		($style eq 'round') ? sin(PI_OVER_2 * $pos/$max) :
			(1 - abs(sin(PI + (PI_OVER_2 * ($max - $pos)/$max)))) ;

	return _computeNearestColor(
		$slots,
		int($r + ($maxr * $factor)),
		int($g + ($maxg * $factor)),
		int($b + ($maxb * $factor)));
}

sub _computeNearestColor {
	my $slots = shift;

	my $closest = 0;
	my $closeval = 100000000;
	my $val = 0;

	foreach my $slot (0..$#$slots) {
		$val = 0;

		map $val += abs($_[$_] - $slots->[$slot][$_]), (0..2);

		$closest = $slot,
		$closeval = $val
			if ($val < $closeval);
	}

	return sprintf('#%04X%04X%04X', @{$slots->[$closest]});
}
#
#	compute color and its brightness complement
#
sub _computeRGBComp {
	my ($style, $pos, $max, $r, $g, $b, $maxr, $maxg, $maxb, $slots) = @_;
	my $factor =
		($style eq 'shiny') ? (1 - abs(sin(PI + (PI_OVER_2 * ($max - $pos)/$max)))) :
		($style eq 'round') ? sin(PI_OVER_2 * $pos/$max) :
			(1 - abs(sin(PI + (PI_OVER_2 * ($max - $pos)/$max)))) ;

	return _computeNearestColorComp(
		$slots,
		int($r + ($maxr * $factor)),
		int($g + ($maxg * $factor)),
		int($b + ($maxb * $factor)));
}

sub _computeNearestColorComp {
	my $slots = shift;

	my $closest = 0;
	my $closeval = 100000000;
	my $val = 0;

	foreach my $slot (0..$#$slots) {
		$val = 0;

		map $val += abs($_[$_] - $slots->[$slot][$_]), (0..2);

		$closest = $slot,
		$closeval = $val
			if ($val < $closeval);
	}
#
#	return the closest slot and its opposite
#
	return (sprintf('#%04X%04X%04X', @{$slots->[$closest]}),
		sprintf('#%04X%04X%04X', @{$slots->[scalar @$slots - $closest]}));
}
#################################################################
#
#	Shape rendering
#
#################################################################
#
#	compute endpt delta for an oval within the width/height
#
sub _makeOval {
	my $h = shift;
#
#	$h is diameter; hence the endpt delta ranges
#	between 0 and $h/2
#
	$h-- if ($h & 1);
	my $c = $h>>1;
	my $k = $c**2;
	my @offsets = ();
	push @offsets, $c - int(sqrt($k - (($c - $_) ** 2)))
		foreach (0..$h);

	return \@offsets;
}
#
#	compute offsets for rectangle buttons w/ round shade
#
sub _makeIndents {
	my $h = shift;
#
#	use a scale factor to compute circle diameter as some multiple
#	of button height
#
	my $r = ($h * SQUARE_EDGE_FACTOR)/2;
	my $delta = cos(PI/6) * $r;
	my @offsets = ();
	my $theta = 0;
	my $theta_inc = (PI/6)/($h>>1);

	push(@offsets, (cos($theta) * $r) - $delta),
	unshift(@offsets, $offsets[-1]),
	$theta += $theta_inc
		foreach (0..$h>>1);
	return \@offsets;
}
#
#	we must create a temp. Bitmap object to
#	get its bbox
#
sub _getBitmapSize {
	my ($self, $bitmap) = @_;
	my $bm = $self->createBitmap(0,0, '-bitmap' => $bitmap, -anchor => 'nw')
		or croak "Unable to create bitmap from $bitmap";

	my ($ox, $oy, $w, $h) = $self->bbox($bm);
	$self->delete($bm);
	return ($w, $h);
}

sub _computeBBox {
#
#	for a given string and font, and/or image, compute area required to hold it;
#	assumes the text is single line: NOTE!! Need to accomodate
#	wraplength!!!
#
	my $self = shift;
	my ($compound, $bitmap, $image, $text, $shape, $orient) = (
		$self->cget('-compound'),
		$self->cget('-bitmap'),
		$self->cget('-image'),
		$self->cget('-text'),
		$self->cget('-shape'),
		$self->cget('-orient'),
	);
#
#	check for image and compound setting
#
	my ($w, $h) = $image ? ($image->width(), $image->height()) :
		$bitmap ? $self->_getBitmapSize($bitmap) :
		(0,0);

	my ($hstrsz, $vstrsz) = (defined($text) && ($compound ne 'none')) ?
		$self->_computeTextBBox() : (0,0);

	($w, $h) =
		($compound eq 'center') ?
#
#	use larger of image or text
#
			((($hstrsz > $w) ? $hstrsz : $w), (($vstrsz > $h) ? $vstrsz : $h)) :

		(($compound eq 'top') || ($compound eq 'bottom')) ?
#
#	use larger of image or text width, and sum of heights
#
			((($hstrsz > $w) ? $hstrsz : $w), $h + $vstrsz + 4) :

		(($compound eq 'left') || ($compound eq 'right')) ?
#
#	use larger of image or text height, and sum of widths
#
			($w + $hstrsz + 4, (($vstrsz > $h) ? $vstrsz : $h)) :
#
#	use image if compound eq none
#
			($w, $h);	# compound eq 'none'

	return (($shape eq 'bevel') || ($shape eq 'folio')) ?
		(int(1.2 * $w), $h) : ($w, $h);
}

sub _computeTextBBox {
#
#	for a given string and font, and/or image, compute area required to hold it;
#	assumes the text is single line
#
	my $self = shift;

	my $shape = $self->cget('-shape');
	my $orient = $self->cget('-orient');
	my $vert = (($shape eq 'bevel') || ($shape eq 'folio') || ($shape eq 'rectangle')) &&
		((index($orient, 'w') == 0) || (index($orient, 'e') == 0));
#
#	we compute for vertical, but then rotate back to horizontal for
#	our computations
#
	if ($vert && $hasgd) {
		my $img = $self->_renderVerticalGdText($self->cget('-text'));
		return reverse $img->getBounds();
	}
#
#	compute the bbox by rendering in the canvas, then deleting
#
	my $textid = $vert ?
#
#	rearrange text to be vertically aligned
#
		$self->createText(0, 0,
			-text => _rotateText($self->cget('-text')),
			-fill => $self->cget('-foreground'),
#			-width => $self->cget('-wraplength'),
#			-justify => $self->cget('-justify'),
			-anchor => 'sw',
			-font => $self->cget('-font')) :

		$self->createText(0, 0,
			-text => $self->cget('-text'),
			-fill => $self->cget('-foreground'),
			-width => $self->cget('-wraplength'),
			-justify => $self->cget('-justify'),
			-anchor => 'sw',
			-font => $self->cget('-font'));

	my ($xl, $yl, $w, $h) = $self->bbox($textid);

#print join(', ', $self->cget('-text'), $xl, $yl, $w, $h), "\n";
	$w -= $xl;
	$h -= $yl;
	$self->delete($textid);

print "Text bbox: $xl, $yl, $w, $h\n"
	if $self->{_debug};

	return $vert ? ($h, $w) : ($w, $h);
}
#
#	compute start/end position of underline
#	NOTE: we have no way to do this since justify
#	could position us; ideally we could switch to
#	underlined font for 1 character, but canvas
#	text doesn't support that very well either
#
sub _underlineText {
	my $self = shift;
	my $ulch = $self->cget('-underline');

	croak "Invalid -underline option $ulch"
		unless (length($ulch) == 1);

	my $pos = index($self->cget('-text'), $ulch);
	return undef
		unless ($pos >= 0);

	return undef;
}
#
#	get binding coordinates
#
sub _getBindCoords {
	my ($self, $w, $h) = @_;
	my $shape = $self->cget('-shape');

	if ($shape eq 'oval') {
		my @lhtags = _computePolyPoints(0, 0, $h, $h);
		my @rhtags = _computePolyPoints($w - $h, 0, $w, $h);
		return [ @lhtags[6..19], @rhtags[18..23], @rhtags[0..7] ];
	}

	my $orient = $self->cget('-orient');
	my $vert = (($shape eq 'bevel') || ($shape eq 'folio')) &&
		((substr($orient, 0, 1) eq 'w') || (substr($orient, 0, 1) eq 'e'));

	return [
		($shape eq 'round')		? _computePolyPoints(0, 0, $w, $h) :
		($shape eq 'rectangle') ? _drawRectangle($w,$h) :
		($shape eq 'bevel')		? _drawBevel($w,$h, 6, $orient) :
#		($shape eq 'folio')
								  _drawFolio($w,$h, 6, $orient) ];
}

sub _bindFromImage {
	my ($self, $w, $h, $xscale, $yscale) = @_;
#
#	embed image in center of canvas, then draw transparent overlay
#	to tag for binding
#
	my @tags = ();
	my $shape = $self->cget('-shape');
	if (($self->cget('-style') eq 'image') && (ref $shape) && (ref $shape eq 'ARRAY')) {
#
#	binding coords are provided
#
		@tags = @$shape;
	}
	elsif ($shape eq 'round') {
		push @tags, $self->createPolygon(_computePolyPoints(0, 0, $w, $h),
			-fill => 'white',
			-stipple => 'transparent');
	}
	elsif (($shape eq 'rectangle') || ($shape eq 'bevel') || ($shape eq 'folio')) {
		my $orient = $self->cget('-orient');
		my $vert = ((index($orient, 'w') == 0) || (index($orient, 'e') == 0));

		my @endpts =
			($shape eq 'rectangle')	? _drawRectangle($w,$h) :
			($shape eq 'bevel')		? _drawBevel($w, $h, 6, $orient) :
									_drawFolio($w, $h, 6, $orient);

		@endpts = $self->_rotateShape($w, @endpts)
			if $vert;

		push @tags, $self->createPolygon(@endpts,
			-fill => 'white',
			-stipple => 'transparent');
	}
	else { # ($shape eq 'oval')
#
#	compute offsets to the rectangle, and arc info for the ends
#	arcs overlap the rectangle; its more than needed, but gets the job done
#
		push @tags,
			$self->createRectangle($h, 0, $w - $h, $h,
				-outline => '',
				-fill => 'white',
				-stipple => 'transparent'),
			$self->createPolygon(_computePolyPoints(0, 0, $h, $h),
				-fill => 'white',
				-stipple => 'transparent'),
			$self->createPolygon(_computePolyPoints($w - $h, 0, $w, $h),
				-fill => 'white',
				-stipple => 'transparent');
	}
#
#	returns a transparent group bound to our events
#
	$self->{_bind_group} = $self->createGroup(0,0, -members => \@tags);
#
#	move everybody a tad
#
	$self->move($self->{_idle_group}, 2, 2);
	$self->move($self->{_active_group}, 2, 2);
	$self->move($self->{_bind_group}, 2, 2);
#
#	bind to bind group only
#
	$self->SUPER::bind($self->{_bind_group}, '<Enter>', sub { $self->_OnEnter; });
	$self->SUPER::bind($self->{_bind_group}, '<Leave>', sub { $self->_OnLeave; });
	$self->SUPER::bind($self->{_bind_group}, '<ButtonPress-1>', sub { $self->_OnPress; });
	$self->SUPER::bind($self->{_bind_group}, '<ButtonRelease-1>', sub { $self->_OnRelease; });
	$self->SUPER::bind($self->{_bind_group}, '<ButtonRelease-1>', sub { $self->_OnRelease; });
#
#	keyboard invokes when we've got focus;
#	also need to check for any add'l key binds ?
#
	$self->SUPER::bind($self->{_bind_group},'<space>', 'invoke');
	$self->SUPER::bind($self->{_bind_group},'<Return>', 'invoke');
#
#	make sure bind group is always on top, and start
#	with idle on top of active
#
	$self->lower($self->{_active_group}, $self->{_bind_group});
	$self->lower($self->{_idle_group}, $self->{_bind_group});
	$self->lower($self->{_active_group}, $self->{_idle_group});

	return $self;
}
#
#	since transparent can't be used with createOval/createArc
#	on Win32, we'll dummy up a polygon that nearly fits
#
sub _computePolyPoints {
	my ($xl,$yl, $xh, $yh) = @_;
	my $r = ($xh - $xl) >> 1;
	my $i = 0;
	my @pts = ();
	push @pts, $xl + $r + int($r * $polyfactors[$i++]),
		$yl + $r + int($r * $polyfactors[$i++])
		while ($i < scalar @polyfactors);
	return @pts;
}

#
#	render text for GD capture image
#
sub _renderGdText {
	my ($self, $image, $text, $x, $y, $textw, $gdfont) = @_;

	my $font = ($self->{_font}->Family eq 'MS Sans Serif') ?
		'Microsoft Sans Serif' : $self->{_font}->Family ;
	my $size = $self->{_font}->Size();

	if ($gdfont) {
		($font, $size) = (ref $gdfont eq 'CODE') ?
			$gdfont->($self->{_font}->actual()) :
			($gdfont, $size);
	}
	elsif ($hasw32n2f) {
		$font = get_ttf_abs_path($font);
	}

	$size = -$size if ($size < 0);
#
#	compute a GD std. font based on weight/slant/size
#	NOTE: since Tk returns pixel size, *not* point size,
#	we have to approximate the right pt size for GD
#
	my ($w, $texth, $spacew);
	if ($font) {
		($size, $w, $texth, $spacew) = $self->_computeGdFontSize($font, $text);
#		print join(', ', $text, $w, $textw, $texth, $size), "\n";
	}
	else {
		$font = ($size <= 8) ? GD::Font->Small :
			($size <= 16) ? GD::Font->Large :
			GD::Font->Giant;

		$size = undef;
	}
#
#	allocate text color
#
	my $rgb = $self->rgb($self->{_foreground});
	my $textcolor = $image->colorAllocate(@$rgb);
#
#	For some reason, stringTTF can't render whitespace, so
#	we have to pull apart the string and render each
#	piece one at a time
#	we should also keep track of any leading/trailing spaces
#	used to adjust the padding
#
	my @p = split (/\s+/, $text);
	my $offs = $x - ($w >> 1);
	$offs += (length($1) * $spacew)
		if ($text=~/^(\s+)/);
	foreach (@p) {
		my @bb = $image->stringTTF($textcolor, $font, $size, 0, $offs, $y + ($texth >> 1), $_);
		my $tw = $bb[2] - $bb[0];
		$offs += $tw + $spacew;	# computed space width
	}
	return $self;
}

#
#	render vertical text via GD
#
sub _renderVerticalGdText {
	my $self = shift;
	my ($image, $text, $x, $y, $textw, $gdfont) = @_;
	($text, $image) = ($image, $text)
		unless defined $text;

	my $font = ($self->{_font}->Family eq 'MS Sans Serif') ?
		'Microsoft Sans Serif' : $self->{_font}->Family ;
	my $size = $self->{_font}->Size();

	if ($gdfont) {
		($font, $size) = (ref $gdfont eq 'CODE') ?
			$gdfont->($self->{_font}->actual()) :
			($gdfont, $size);
	}
	elsif ($hasw32n2f) {
		$font = get_ttf_abs_path($font);
	}

	$size = -$size if ($size < 0);
#
#	compute a GD std. font based on weight/slant/size
#	NOTE: since Tk returns pixel size, *not* point size,
#	we have to approximate the right pt size for GD
#
	my ($w, $texth);
	$font = ($size <= 8) ? GD::Font->Small :
		($size <= 16) ? GD::Font->Large :
		GD::Font->Giant
		unless $font;

	($size, $w, $texth) = $self->_computeGdFontSize($font, $text);

	$size = undef
		unless $font;
#
#	create image to write the text into
#
	my $txtimage = GD::Image->new($w, $texth);
	my $transparent = $txtimage->colorAllocate(1, 1, 1);
	$txtimage->transparent($transparent);

	$txtimage->filledRectangle(0,0,$w - 1,$texth - 1, $transparent);

	my $rgb = $self->rgb($self->{_foreground});
	my $textcolor = $txtimage->colorAllocate(@$rgb);

	my $gdtext = GD::Text::Wrap->new($txtimage,
		color => $textcolor,
		text => $text,
		width => $w + 100000,
		preserve_nl => 1, # ($self->{_wraplength} == 0),
		align => $self->{_justify},
	);
	$gdtext->set(width => $self->{_wraplength})
		if $self->{_wraplength};
	$gdtext->set_font($font, $size);
#
#	need to compute height to properly align the text
#
	my $orient = $self->cget('-orient');
	$gdtext->draw(0, 0);

	$txtimage = (index($orient, 'e') == 0) ?
		$txtimage->copyRotate90() :
		$txtimage->copyRotate270();

	return $txtimage
		unless defined $image;

	$image->copy($txtimage, $y, 14, 0,0, $txtimage->getBounds());
	return $self;
}

sub _computeGdFontSize {
	my ($self, $font, $text) = @_;
	my $needs = $self->{_font}->measure($text);
#
#	just use brute force; we don't really have any
#	slick binary search solutions here
#
	my ($size, $lastsize) = (12, 12);	# assume 12 pt to start
	my $delta = 1000000;
	my ($w, $texth);
	my $p = $text;
	$p=~s/\s+//g;
	my $tlen = length($p);
	my $spacew = 0;
	while (1) {

		my @bb = GD::Image->stringTTF(0, $font, $size, 0, 0, 0, $p);
		$w = ($bb[2] - $bb[0]);
		$texth = $bb[1] - $bb[7];
#
#	add add'l width for spaces, using a computed space width
#
		$spacew = int($w/$tlen);
		$w += ((length($text) - $tlen) * $spacew);

		return ($size, $w, $texth, $spacew) if ($w == $needs);

		if ($w > $needs) {
#
#	if we've gotten bigger, then return prior
#
			return ($lastsize, $w, $texth, $spacew)
				if ($w - $needs >= $delta);

			$lastsize = $size;
			$size--;
			$delta = $w - $needs;
		}
		else {
			return ($lastsize, $w, $texth, $spacew)
				if ($needs - $w >= $delta);

			$lastsize = $size;
			$size++;
			$delta = $needs - $w;
		}
	}
	return ($size, $w, $texth, $spacew);
}

#
#	for vertical orientation wo/ GD support, we must convert text into
#	vertical format
#
sub _rotateText {
	my $text = shift;
	my @segments = split /\n/, $text;
	my $maxchars = 0;
	foreach (@segments) {
		$maxchars = length($_)
			if ($maxchars < length($_));
	}

	$segments[$_] .= (' ' x ($maxchars - length($segments[$_])))
		foreach (0..$#segments);

	my @lines = ('') x $maxchars;
	my @chars;
	foreach my $segment (@segments) {
		@chars = split('', $segment);
		$lines[$_] .= $chars[$_] . '  '
			foreach (0..$#chars);
	}
	return join("\n", @lines);
}
#
#	rotate the input shape +/- 90 degs, or flip it
#
sub _rotateShape {
	my ($self, $w, @endpts) = @_;
	my $orient = $self->cget('-orient');
	$orient = substr($orient, 0, 1);
	return ($orient eq 'w') ?
		($endpts[3], $w - $endpts[2],
		$endpts[5], $w - $endpts[4],
		$endpts[7], $w - $endpts[6],
		$endpts[1], $w - $endpts[0]) :

		($orient eq 'e') ?
		($endpts[5], $w - $endpts[4],
		$endpts[3], $w - $endpts[2],
		$endpts[1], $w - $endpts[0],
		$endpts[7], $w - $endpts[6]) :

		($orient eq 's') ?
		($endpts[6], $endpts[7],
		$endpts[4], $endpts[5],
		$endpts[2], $endpts[3],
		$endpts[0], $endpts[1]) :
#
#	the original
#
		@endpts;
}

1;