#*** SevenSegmentDisplay.pm ***#
# Copyright (C) 2009 by Torsten Knorr
# create-soft@freenet.de
# All rights reserved!
#-------------------------------------------------
 package Tk::SevenSegmentDisplay;
#-------------------------------------------------
 use strict;
 use Tk::Frame;
#-------------------------------------------------
 use constant DIGITWIDTH	=> 33;
 use constant COLONWIDTH	=> 6;
 use constant POINTWIDTH	=> 6;
 use constant DIGITHEIGHT	=> 58;
 use constant SEGMENTSDIGIT	=> 7;
 use constant SEGMENTSCOLON	=> 2;
 use constant POINTSSEGMENT	=> 12;
 use constant POINTSCOLON	=> 8;
 use constant POINTSDOT		=> 8;
#-------------------------------------------------
 sub _PT_SEGMENTS
	{
 	[[9, 	0,	24,	0,	28,	4,	24,	8,	9,	8,	5,	4],
	[4,	5,	8,	9,	8,	24,	4,	28,	0,	24,	0,	9],
	[29,	5,	33,	9,	33,	24,	29,	28,	25,	24,	25,	9],
	[9,	25,	24,	25,	28,	29,	24,	33,	9,	33,	5,	29],
	[4,	30,	8,	34,	8,	49,	4,	53,	0,	49,	0,	34],
	[29,	30,	33,	34,	33,	49,	29,	53,	25,	49,	25,	34],
	[9,	50,	24,	50,	28,	54,	24,	58,	9,	58,	5,	54]];
 	}
#-------------------------------------------------
 sub _PT_COLON
 	{
 	[[3,	26,	6,	29,	3,	32,	0,	29],
	[3,	51,	6,	54,	3,	57,	0,	54]];
 	}
#-------------------------------------------------
 sub _PT_DOT
 	{ 
 	[0,	55,	3,	52,	6,	55,	3,	58];
 	}
#-------------------------------------------------
 my @_combinations =
 	(
# 0
	[1,	1,	1,	0,	1,	1,	1],
# 1
	[0,	0,	1,	0,	0,	1,	0],
# 2
	[1,	0,	1,	1,	1,	0,	1],
# 3
	[1,	0,	1,	1,	0,	1,	1],
# 4
	[0,	1,	1,	1,	0,	1,	0],
# 5
	[1,	1,	0,	1,	0,	1,	1],
# 6
	[1,	1,	0,	1,	1,	1,	1],
# 7
	[1,	0,	1,	0,	0,	1,	0],
# 8
	[1,	1,	1,	1,	1,	1,	1],
# 9
	[1,	1,	1,	1,	0,	1,	1],
# - = 10
	[0,	0,	0,	1,	0,	0,	0],
# E = 11
	[1,	1,	0,	1,	1,	0,	1],
# space = 12
	[0,	0,	0,	0,	0,	0,	0]
 	);
#-------------------------------------------------
 @Tk::SevenSegmentDisplay::ISA = qw(Tk::Frame);
 $Tk::SevenSegmentDisplay::VERSION = '0.01';
#-------------------------------------------------
 Construct Tk::Widget 'SevenSegmentDisplay';
#-------------------------------------------------
 sub Populate
 	{
 	require Tk::Canvas;
 	my ($self, $rh_args) = @_;
 	$self->SUPER::Populate($rh_args);
	$self->{_seven_segment_display} = $self->Canvas()->grid();
 	$self->Advertise('SevenSegmentDisplay' => $self->{_seven_segment_display});
 	$self->Delegates(DEFAULT => $self->{_seven_segment_display});
 	$self->ConfigSpecs(
 		-digitwidth	=> [qw/METHOD digitwidth DigitWidth/, DIGITWIDTH],
 		-digitheight	=> [qw/METHOD digitheight DigitHeight/, DIGITHEIGHT],
 		-space		=> [qw/METHOD space Space/, 3],
 		-format		=> [qw/METHOD format Format/, 'dd.dd'],
 		-background	=> [qw/METHOD background Background/, '#00C800'],
 		-foreground	=> [qw/METHOD foreground Foreground/, '#006400'],
 		DEFAULT => [$self->{_seven_segment_display}]
		);
 	}
#-------------------------------------------------
 sub digitwidth	{ $_[0]->{_x_scale_factor} = $_[1] / DIGITWIDTH; }
 sub digitheight	{ $_[0]->{_y_scale_factor} = $_[1] / DIGITHEIGHT; }
 sub space	{ $_[0]->{_space}	= $_[1]; }
 sub format	{ $_[0]->{_format} = $_[1]; }
 sub background	{ $_[0]->{_background} = $_[1]; }
 sub foreground	{ $_[0]->{_foreground} = $_[1]; }
#-------------------------------------------------
 sub CalculateDisplay
 	{
 	my ($self, %args) = @_;
 	my ($segment, $point);
 	$self->{_digits_count}	= 0;
 	$self->{_colons_count}	= 0;
 	$self->{_signs_count}	= 0;
 	$self->{_dots_count}	= 0;
 	my $x_offset = $self->{_space} + 2;
 	$self->{_digits}	= [];
 	$self->{_colons}	= [];
 	$self->{_signs}	= [];
 	$self->{_dots}	= [];
 	if($self->{_format} =~ m/^-/)
 		{
 		$self->{_signed} = 1;
 		}
 	else
 		{
 		$self->{_signed} = undef;
 		}
	for(split(//, $self->{_format}))
 		{
 		SWITCH:
 			{
#-------------------------------------------------
 /d|D/	&& do
 	{
	for($segment = 0; $segment < SEGMENTSDIGIT; $segment++)
 		{
		for($point = 0; $point < POINTSSEGMENT; $point++)
			{
 			$self->{_digits}[$self->{_digits_count}][$segment][$point] =
 				int(_PT_SEGMENTS->[$segment][$point] * $self->{_x_scale_factor}) + $x_offset;
 			$point++;
 			$self->{_digits}[$self->{_digits_count}][$segment][$point] =
 				int(_PT_SEGMENTS->[$segment][$point] * $self->{_y_scale_factor}) + $self->{_space} + 2; 
			}
 		}
	$self->{_digits_count}++;
 	$x_offset += int(DIGITWIDTH * $self->{_x_scale_factor}) + $self->{_space} + 1;
 	last SWITCH;
 	};
#-------------------------------------------------
 /-/	&& do
 	{
 	for($point = 0; $point < POINTSSEGMENT; $point++)
 		{
 		$self->{_signs}[$self->{_signs_count}][$point] =
 			int(_PT_SEGMENTS->[3][$point] * $self->{_x_scale_factor}) + $x_offset;
 		$point++;
 		$self->{_signs}[$self->{_signs_count}][$point] =
 			int(_PT_SEGMENTS->[3][$point] * $self->{_y_scale_factor}) + $self->{_space} + 2;
 		}
 	$self->{_signs_count}++;
 	$x_offset += int(DIGITWIDTH * $self->{_x_scale_factor}) + $self->{_space} + 1;
 	last SWITCH;
 	};
#-------------------------------------------------
 /:/	&& do
 	{
 	for($segment = 0; $segment < SEGMENTSCOLON; $segment++)
 		{
 		for($point = 0; $point < POINTSCOLON; $point++)
 			{
 			$self->{_colons}[$self->{_colons_count}][$segment][$point] =
 				int(_PT_COLON->[$segment][$point] * $self->{_x_scale_factor}) + $x_offset;
 			$point++;
 			$self->{_colons}[$self->{_colons_count}][$segment][$point] =
 				int(_PT_COLON->[$segment][$point] * $self->{_y_scale_factor}) + $self->{_space} + 2;
 			}
		}
 	$self->{_colons_count}++;
 	$x_offset += int(COLONWIDTH * $self->{_x_scale_factor}) + $self->{_space} + 1;
 	last SWITCH;
 	};
#-------------------------------------------------
 /\./	&& do
 	{
 	for($point = 0; $point < POINTSDOT; $point++)
 		{
 		$self->{_dots}[$self->{_dots_count}][$point] =
 			int(_PT_DOT->[$point] * $self->{_x_scale_factor}) + $x_offset;
 		$point++;
 		$self->{_dots}[$self->{_dots_count}][$point] =
 			int(_PT_DOT->[$point] * $self->{_y_scale_factor}) + $self->{_space} + 2;
 		}
 	$self->{_dots_count}++;
 	$x_offset += int(POINTWIDTH * $self->{_x_scale_factor}) + $self->{_space} + 1;
 	last SWITCH;
 	};
#-------------------------------------------------
 			}
 		}
 	$self->{_values}[$_] = 8 for(0..$#{$self->{_digits}}); 
 	$self->{_rect_bottom} = int(DIGITHEIGHT * $self->{_y_scale_factor}) + 2 * $self->{_space} + 1;
 	$self->{_rect_right} = $x_offset - 2;
 	$self->{_seven_segment_display}->configure(
		-width	=> $self->{_rect_right},
 		-height	=> $self->{_rect_bottom},
 		-background	=> $self->{_background}
 		);
	return $self->DrawNew();
 	}
#-------------------------------------------------
 sub DrawNew
 	{
 	my ($self) = @_;
 	my $segment = 0;
 	$self->{_seven_segment_display}->delete('all');
#-------------------------------------------------
#draw background
 	$self->{_seven_segment_display}->createRectangle(
 		0,
 		0,
 		$self->{_rect_right},
 		$self->{_rect_bottom},
 		-fill	=> $self->{_background},
 		-outline	=> $self->{_background},
 		-tags	=> 'background'
 		);
#-------------------------------------------------
# draw digits
 	for(my $digit = 0; $digit < $self->{_digits_count}; $digit++)
 		{
 		for($segment = 0; $segment < SEGMENTSDIGIT; $segment++)
 			{
 			if($_combinations[$self->{_values}[$digit]][$segment])
 				{
 				$self->{_seven_segment_display}->createPolygon(
 					@{$self->{_digits}[$digit][$segment]},
 					-fill	=> $self->{_foreground},
 					-outline	=> $self->{_foreground},
 					-tags	=> "segment$digit$segment"
 					);
 				}
 			}
 		}
#-------------------------------------------------
# draw colons
 	for(my $colon = 0; $colon < $self->{_colons_count}; $colon++)
 		{
 		for($segment = 0; $segment < SEGMENTSCOLON; $segment++)
 			{
 			$self->{_seven_segment_display}->createPolygon(
 				@{$self->{_colons}[$colon][$segment]},
 				-fill	=> $self->{_foreground},
 				-outline	=> $self->{_foreground},
 				-tags	=> 'colon'
 				);
 			}
 		}
#-------------------------------------------------
# draw signs and hyphens
 	my $sign = 0;
 	if($self->{_signed})
 		{
		$self->{_seven_segment_display}->createPolygon(
 			@{$self->{_signs}[$sign]},
 			-fill	=> $self->{_foreground},
 			-outline	=> $self->{_foreground},
 			-tags	=> 'sign'
 			);
 		$sign++;
 		}
 	for(; $sign < $self->{_signs_count}; $sign++)
 		{
 		$self->{_seven_segment_display}->createPolygon(
 			@{$self->{_signs}[$sign]},
 			-fill	=> $self->{_foreground},
 			-outline	=> $self->{_foreground},
 			-tags	=> 'hyphen'
 			);
 		}
#-------------------------------------------------
# draw dot
 	for(my $dot = 0; $dot < $self->{_dots_count}; $dot++)
 		{
 		$self->{_seven_segment_display}->createPolygon(
 			@{$self->{_dots}[$dot]},
 			-fill	=> $self->{_foreground},
 			-outline	=> $self->{_foreground},
 			-tags	=> 'dot'
 			);
 		}
#-------------------------------------------------
 	return 1;
 	}
#-------------------------------------------------
 sub ChangeColor
 	{
 	my ($self) = @_;
 	my $segment;
#-------------------------------------------------
# change the colors of the digits
 	for(my $digit = 0; $digit < $self->{_digits_count}; $digit++)
 		{
 		for($segment = 0; $segment < SEGMENTSDIGIT; $segment++)
 			{
 			if($_combinations[$self->{_values}[$digit]][$segment])
 				{
 				$self->{_seven_segment_display}->itemconfigure(
 					"segment$digit$segment",
 					-fill	=> $self->{_foreground},
 					-outline	=> $self->{_foreground}
 					);
 				}
 			else
 				{
 				$self->{_seven_segment_display}->itemconfigure(
 					"segment$digit$segment",
 					-fill	=> $self->{_background},
 					-outline	=> $self->{_background}
 					);
 				}
 			}
 		}
#-------------------------------------------------
# change the color of the sign
 	if($self->{_signed})
 		{
 		if($self->{_negative})
 			{
 			$self->{_seven_segment_display}->itemconfigure(
 				'sign',
 				-fill	=> $self->{_foreground},
 				-outline	=> $self->{_foreground}
 				);
 			}
 		else
 			{
 			$self->{_seven_segment_display}->itemconfigure(
 				'sign',
 				-fill	=> $self->{_background},
 				-outline	=> $self->{_background}
 				);
 			}
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub ChangeSequence
 	{
 	my ($self) = @_;
 	my $segment;
#-------------------------------------------------
# change the display sequence of the digits
 	for(my $digit = 0; $digit < $self->{_digits_count}; $digit++)
 		{
 		for($segment = 0; $segment < SEGMENTSDIGIT; $segment++)
 			{
 			if($_combinations[$self->{_values}[$digit]][$segment])
 				{
 				$self->{_seven_segment_display}->raise(
 					"segment$digit$segment",
 					'background'
 					);
 				}
 			else
 				{
 				$self->{_seven_segment_display}->lower(
 					"segment$digit$segment",
 					'background'
 					);
 				}
 			}
 		}
#-------------------------------------------------
# change the display sequence of the sign
 	my $sign = 0;
 	if($self->{_signed})
 		{
 		if($self->{_negative})
 			{
 			$self->{_seven_segment_display}->raise(
 				'sign',
 				'background'
 				);
 			}
 		else
 			{
 			$self->{_seven_segment_display}->lower(
 				'sign',
 				'background'
 				);
 			}
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub SetValue
 	{
 	my ($self, $digit, $value) = @_;
 	return if(1 > $digit || $self->{_digits_count} < $digit);
 	return if(0 > $value || 9 < $value);
 	$digit--;
 	$self->{_values}[$digit] = int($value);
 	return 1;
 	}
#-------------------------------------------------
 sub SetInt
 	{
 	my ($self, $int) = @_;
 	if(0 > $int && $self->{_signed})
 		{
 		$self->{_negative} = 1;
 		$int = abs($int);
 		}
 	else
 		{
 		$self->{_negative} = undef;
 		}
 	for(my $i = $#{$self->{_values}}, my $d = 1; $i >= 0; $i--, $d *= 10)
 		{ 
 		$self->{_values}[$i] = int($int / $d) % 10;
 		}
 	return 1;
 	}
#-------------------------------------------------
1;
#-------------------------------------------------
__END__

=head1 NAME

Tk::SevenSegmentDisplay - Perl extension for simulating a seven-segment display

=for category Derived Widgets

=head1 SYNOPSIS

 use Tk::SevenSegmentDisplay;
 my $mw = MainWindow->new();
 my $ssd = $mw->SevenSegmentDisplay(
 	-digitwidth	=> 100,
 	-digitheight	=> 200,
 	-space		=> 5,
 	-format		=> 'dd:dd:dd',
 	-background	=> '#00FF00',
 	-foreground	=> '#0000FF'
 	)->pack();
 
 my $ssd = $mw->SevenSegmentDisplay()->pack();
 $ssd->configure(
 	-digitwidth	=> 80,
 	-digitheight	=> 160,
 	-space		=> 8,
 	-format		=> 'ddd.ddd.ddd.ddd',
 	-background	=> '#0000FF',
 	-foreground	=> '#FF0000'
 	);
  $ssd->CalculateDisplay();
  $ssd->repeat(1000, sub
 	{
 	$ssd->SetValue($value);
	# $ssd->SetInt($value);

 	$ssd->DrawNew();
 	# $ssd->ChangeColor();
 	# $ssd->ChangeSequence();
 	});

=head1 DESCRIPTION

Perl extension for simulating a seven-segment display.
The display can be changed in size and color.
Furthermore can points, colons and hyphens being added.

=head1 CONSTRUCTOR AND INITIALIZATION

 use Tk::SevenSegmentDisplay;
 my $mw = MainWindow->new();
 my $clock = $mw->SevenSegmentDisplay(
 	-digitwidth	=> 60,
 	-digitheight	=> 100,
 	-space		=> 10,
 	-format		=> 'dd:dd:dd',
 	-background	=> '#C0C0C0',
 	-foreground	=> '#FF0000'
 	);
 $clock->CalculateDisplay();
 $clock->pack();

=head1 METHODS

=item CalculateDisplay(void)

Calculates and draws the display new.
This function must be called after every initialization or configuration.

=item DrawNew(void)

Draws the whole display new.
Should be called after SetValue() or SetInt is called, to draw the changes of the values.

=item ChangeColor(void)

Exchanges the foreground- and background color.
Should be called after SetValue() or SetInt() is called, to show the changes of the values.

=item ChangeSequence(void)

Changed the sequence of the segments in the display.
Should be called after SetValue() or SetInt() is called, to show the changes of the values.

=item SetValue(unsigned int, unsigned int)

The first argumet is the number of the digit in the display which is to be changed.
The left digit = 1.
 	ddd.ddd
 	123.456
 The second argumet is the value which is to be shown.
 	0..9

=item SetInt(int)

Takes a signed number which is to be shown in the display.
To be able to show the sign, the format of the display must begin with a hyphen.
 	'-dddddd'

=head1 WIDGET SPECIFIC OPTIONS

=item -digitwidth
 
The width of one digit in pixel.
default = 33

=item -digitheight

The height of one digit in pixel.
default = 58

=item -space

The space between two digits in pixel.
default = 3

=item -format

A string containing:
 	'd' or 'D' = digit
 	[dD.-:]
 Examples:
 	'dd:dd:dd'
 	'ddd.ddd.ddd.ddd'
 	'dd-dd-dddd'
 	'-dddddd'
default = 'dd.dd'

=item -background

default = '#00C800'

=item -foreground

default = '#006400'
 
=head1 INSERTED WIDGETS

=item <SevenSegmentDisplay>

It is a canvas widget which shows the digits.

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://freenet-homepage.de/torstenknorr

=head1 KEYWORDS

seven-segment display

=head1 	BUGS

Maybe you'll find some. Please let me know.

=head1 AUTHOR

Torsten Knorr, E<lt>create-soft@freenet.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Torsten Knorrr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

