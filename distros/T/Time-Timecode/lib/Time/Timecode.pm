package Time::Timecode;

use strict;
use warnings;
use overload
    '+'   => '_add',
    '-'   => '_subtract',
    '*'   => '_multiply',
    '/'   => '_divide',
    'cmp' => '_compare',
    '<=>' => '_compare',
    '""'  => 'to_string';

use POSIX ();
use Carp ();

our $VERSION = '0.30';

our $DEFAULT_FPS = 29.97;
our $DEFAULT_DROPFRAME = 0;
our $DEFAULT_DELIMITER = ':';
our $DEFAULT_FRAME_DELIMITER = $DEFAULT_DELIMITER;
our $DEFAULT_TO_STRING_FORMAT = ''; # If not set $TO_STRING_FORMAT is used

my $SECONDS_PER_MINUTE = 60;
my $SECONDS_PER_HOUR   = $SECONDS_PER_MINUTE * 60;
my $TO_STRING_FORMAT = '%02s%s%02s%s%02s%s%02s'; #HH:MM:SS:FF

my $TIME_PART = qr|[0-5]\d|;
my $DROP_FRAME_DELIMITERS = '.;'; #, too?
my $FRAME_PART_DELIMITERS = "${DEFAULT_DELIMITER}${DROP_FRAME_DELIMITERS}";

{
  no strict 'refs';

  my @methods = qw|hours minutes seconds frames fps is_dropframe total_frames|;
  my %method_aliases = (
      hours   => ['hh', 'hrs'],
      minutes => ['mm', 'mins'],
      seconds => ['ss', 'secs'],
      frames  => ['ff']
  );

  for my $accessor (@methods) {
      *$accessor = sub { (shift)->{$accessor} };
      *$_ = \&$accessor for @{$method_aliases{$accessor}};
  }
}

sub new
{
    Carp::croak 'usage: Time::Timecode->new( TIMECODE [, OPTIONS ] )' if @_ < 2 || !defined($_[1]);

    my $class   = shift;
    my $options = ref($_[-1]) eq 'HASH' ? pop : {};
    my $self    = bless { is_dropframe    => $options->{dropframe},
                          frame_delimiter => $options->{frame_delimiter},
                          delimiter       => $options->{delimiter} || $DEFAULT_DELIMITER,
                          fps             => $options->{fps}       || $DEFAULT_FPS }, $class;

    Carp::croak "Invalid fps '$self->{fps}': fps must be >= 0" unless $self->{fps} =~ /\A\d+(?:\.\d+)?\z/;

    if(@_ == 1 && $_[0] !~ /^\d+$/) {
        $self->_timecode_from_string( shift );
    }
    else {
        # For string timecodes these can be derrived by their format
        $self->{is_dropframe} = $DEFAULT_DROPFRAME unless defined $self->{is_dropframe};
        $self->{frame_delimiter} ||= $DEFAULT_FRAME_DELIMITER;

        if(@_ == 1) {
	    $self->_timecode_from_total_frames( shift );
        }
        else {
	    # Add frames if necessary
	    push @_, 0 unless @_ == 4;
	    $self->_set_and_validate_time(@_);
	}
    }

    if ($self->_is_deprecated_dropframe_rate) {
      warn<<DEPRECATION;
Time::Timecode warning: versions > 0.3X will not treat drop frame 30 and 60 like 29.97 and 59.94. Use an fps of 29.97 or 59.94 instead.
DEPRECATION
    }

    $self;
}

sub to_string
{
    my $self   = shift;
    my $format = shift || $DEFAULT_TO_STRING_FORMAT;
    my $tc     = sprintf $TO_STRING_FORMAT, $self->hours,
                                            $self->{delimiter},
                                            $self->minutes,
                                            $self->{delimiter},
                                            $self->seconds,
                                            $self->{frame_delimiter},
                                            $self->frames;

    if($format) {
        my @args;
        # TODO: Add %X too?
        my %formats = (H => $self->hours,
                       M => $self->minutes,
                       S => $self->seconds,
                       f => $self->frames,
                       r => $self->fps,
		       i => $self->total_frames,
		       s => sprintf("%02d", $self->frames/$self->fps*100),
                       T => $tc,
                       '%'=> '%');

        # Match printf style formats with optional width and alignment.
        ($tc = $format) =~ s/(%-?\d*)([HMSfrisT%])/sprintf "${1}s", $formats{$2}/ge
    }

    $tc;
}

sub convert
{
    my ($self, $fps, $options) = @_;

    $options ||= {};
    $options->{fps} = $fps;
    $options->{dropframe} ||= 0;
    $options->{delimiter} ||= $self->{delimiter};
    $options->{frame_delimiter} ||= $self->{frame_delimiter};

    Time::Timecode->new($self->to_non_dropframe->total_frames, $options);
}

sub to_dropframe
{
    my $self = shift;
    return $self if $self->is_dropframe;

    my $options = $self->_dup_options;
    $options->{dropframe} = 1;

    Time::Timecode->new($self->total_frames, $options);
}

sub to_non_dropframe
{
    my $self = shift;
    return $self unless $self->is_dropframe;

    my $options = $self->_dup_options;
    $options->{dropframe} = 0;

    Time::Timecode->new($self->total_frames, $options);
}

sub _add
{
    _handle_binary_overload(@_, sub {
        $_[0] + $_[1];
    });
}

sub _subtract
{
    _handle_binary_overload(@_, sub {
        $_[0] - $_[1];
    });
}

sub _multiply
{
    _handle_binary_overload(@_, sub {
        $_[0] * $_[1];
    });
}

sub _divide
{
    _handle_binary_overload(@_, sub {
        int($_[0] / $_[1]);
    });
}

sub _compare
{
    my ($lhs, $rhs) = _overload_order(@_);
    $lhs->total_frames <=> $rhs->total_frames;
}

sub _overload_order
{
    my ($lhs, $rhs, $reversed) = @_;
    $rhs = Time::Timecode->new($rhs) if !ref($rhs) or !$rhs->isa('Time::Timecode');
    ($lhs, $rhs) = ($rhs, $lhs) if $reversed;
    ($lhs, $rhs);
}

sub _handle_binary_overload
{
    my $fx = pop @_;
    my ($lhs, $rhs) = _overload_order(@_);
    Time::Timecode->new($fx->($lhs->total_frames, $rhs->total_frames), $lhs->_dup_options);
}

sub _dup_options
{
    my $self = shift;
    { fps       => $self->fps,
      dropframe => $self->is_dropframe,
      delimiter => $self->{delimiter},
      frame_delimiter => $self->{frame_delimiter} };
}

sub _frames_per_hour
{
    shift->_rounded_fps * $SECONDS_PER_HOUR;
}

sub _frames_per_minute
{
    shift->_rounded_fps * $SECONDS_PER_MINUTE;
}

sub _frames
{
    my ($self, $frames) = @_;
    $frames % $self->_rounded_fps;
}

sub _rounded_fps
{
    my $self = shift;
    $self->{rounded_fps} ||= POSIX::ceil($self->fps);
}

sub _hours_from_frames
{
    my ($self, $frames) = @_;
    int($frames / $self->_frames_per_hour);
}

sub _minutes_from_frames
{
    my ($self, $frames) = @_;
    int($frames % $self->_frames_per_hour / $self->_frames_per_minute);
}

sub _seconds_from_frames
{
    my ($self, $frames) = @_;
    int($frames % $self->_frames_per_minute / $self->_rounded_fps);
}

sub _valid_frames
{
    my ($part, $frames, $max) = @_;
    Carp::croak "Invalid frames '$frames': frames must be between 0 and ${ \int($max) }" unless $frames =~ /^\d+$/ && $frames >= 0 && $frames <= $max;
}

sub _valid_time_part
{
    my ($part, $value) = @_;
    Carp::croak "Invalid $part '$value': $part must be between 0 and 59" if !defined($value) || $value < 0 || $value > 59;
}

sub _set_and_validate_time_part
{
    my ($self, $part, $value, $validator) = @_;
    $validator->($part, $value, $self->fps);
    $self->{$part} = int($value); # Can be a string with a 0 prefix: 01, 02, etc...
}

sub _frames_to_drop {
  my $self = shift;

  if (!defined $self->{frames_to_drop}) {
    $self->{frames_to_drop} = $self->is_dropframe ? POSIX::ceil($self->{fps}*0.066666) : 0;
  }

  $self->{frames_to_drop};
}

sub _set_and_validate_time
{
    my ($self, $hh, $mm, $ss, $ff) = @_;
    $self->_set_and_validate_time_part('frames', $ff, \&_valid_frames);
    $self->_set_and_validate_time_part('seconds', $ss, \&_valid_time_part);
    $self->_set_and_validate_time_part('minutes', $mm, \&_valid_time_part);
    $self->_set_and_validate_time_part('hours', $hh, \&_valid_time_part);

    my $total = $self->frames;
    $total += $self->_rounded_fps * $ss;
    $total += $self->_frames_per_minute * $mm;
    $total += $self->_frames_per_hour * $hh;

    my $total_minutes = $SECONDS_PER_MINUTE * $hh + $mm;
    $total -= $self->_frames_to_drop * ( $total_minutes - int($total_minutes / 10) );

    Carp::croak "Invalid dropframe timecode: '$self'" unless $self->_valid_dropframe_timecode;
    $self->{total_frames} = $total;
}

sub _valid_dropframe_timecode
{
    my $self = shift;
    !($self->is_dropframe
      && $self->seconds == 0
      && ($self->frames == 0 || $self->frames == 1)
      && ($self->minutes % 10 != 0));
}

sub _set_timecode_from_frames
{
    my ($self, $frames) = @_;

    # We need the true frame rate here, not the rounded
    my $fps = $self->{fps};

    # Support drop frame calculations for known frame rates that don't support them :(
    # This is in place temporarily for backwards compatibility with $VERSION < 0.30 and will be removed in 0.40
    if ($self->_is_deprecated_dropframe_rate) {
        $fps = $self->{fps} == 30 ? 29.97 : 59.94;
    }

    #####
    # Algorithm from: http://www.davidheidelberger.com/blog/?p=29
    my $drop = $self->_frames_to_drop;

    my $frames_per_ten_minutes = $fps * $SECONDS_PER_MINUTE * 10;
    my $frames_per_minute = $self->_frames_per_minute - $drop;

    my $d = int($frames / $frames_per_ten_minutes);
    my $m = $frames % $frames_per_ten_minutes;

    if($m > $drop) {
        $frames += ($drop * 9 * $d) + $drop * int(($m - $drop) / $frames_per_minute);
    }
    else {
        $frames += $drop * 9 * $d;
    }
    #####

    $self->_set_and_validate_time_part('frames', $self->_frames($frames), \&_valid_frames);
    $self->_set_and_validate_time_part('seconds', $self->_seconds_from_frames($frames), \&_valid_time_part);
    $self->_set_and_validate_time_part('minutes', $self->_minutes_from_frames($frames), \&_valid_time_part);
    $self->_set_and_validate_time_part('hours', $self->_hours_from_frames($frames), \&_valid_time_part);
}

sub _is_deprecated_dropframe_rate
{
  my $self = shift;
  $self->is_dropframe && ($self->{fps} == 30 || $self->{fps} == 60);
}

sub _timecode_from_total_frames
{
    my ($self, $frames) = @_;
    $self->{total_frames} = $frames;
    $self->_set_timecode_from_frames($frames);
}

# Close your eyes, it's about to get ugly...
sub _timecode_from_string
{
    my ($self, $timecode) = @_;
    #[\Q$self->{delimiter}$DEFAULT_DELIMITER\E]
    my $delim = '[' . quotemeta("$self->{delimiter}$DEFAULT_DELIMITER") . ']';
    my $frame_delim = $FRAME_PART_DELIMITERS;

    $frame_delim .= $self->{frame_delimiter} if defined $self->{frame_delimiter};
    $frame_delim = '[' . quotemeta("$frame_delim") . ']';

    if($timecode =~ /^\s*($TIME_PART)$delim($TIME_PART)$delim($TIME_PART)($frame_delim)([0-5]\d)\s*([NDPF])?\s*$/) {
        #TODO: Use suffix after frames to determine drop/non-drop -and possibly other things
        if(!defined $self->{is_dropframe}) {
            $self->{is_dropframe} = index($DROP_FRAME_DELIMITERS, $4) != -1 ? 1 : $DEFAULT_DROPFRAME;
        }

        $self->{frame_delimiter} = $4 unless defined $self->{frame_delimiter};
        $self->_set_and_validate_time($1, $2, $3, $5);
    }
    else {
        Carp::croak "Can't create timecode from '$timecode'";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Timecode - Video timecode class

=head1 SYNOPSIS

 use Time::Timecode;

 my $tc1 = Time::Timecode->new(2, 0, 0, 12); # hh, mm, ss, ff
 print $tc1->fps;                            # $DEFAULT_FPS
 print $tc1;                                 # 02:00:00:12
 print $tc1->hours;                          # 2
 print $tc1->hh;                             # shorthanded version
 print $tc1->to_string('%Hh%Mm%Ss%ff')       # 2h0m0s12f

 my $tc2 = Time::Timecode->new('00:10:30:00', { fps => 25 } );
 print $tc2->total_frames;                   # 15750
 print $tc2->fps;                            # 25

 $tc2 = Time::Timecode->new(1800);           # Total frames
 print $tc1 + $tc2;                          # 02:01:00:12

 $tc1 = Time::Timecode->new('00:01:00;04');  # Dropframe (see the ";")
 print $tc1->is_dropframe;                   # 1

 my $diff = $tc1 - 1800;                     # Subtract 1800 frames
 print $tc1->is_dropframe;                   # 1, maintains LHS' options
 print $diff;                                # 00:00:02;00

 # Conversions
 my $pal  = $tc->convert(25);
 my $ntsc = $pal->convert(30), { dropframe => 1 });
 my $ndf  = $ntsc->to_non_dropframe;

 my $opts = { delimiter => ',', frame_delimiter => '+' };
 $Time::Timecode::DEFAULT_FPS = 23.976;
 $tc2 = Time::Timecode->new('00,10,30+00', $opts);
 print $tc2->fps                             # 23.976
 print $tc2->minutes;                        # 10
 print $tc2->seconds;                        # 30

=head1 DESCRIPTION

C<Time::Timecode> supports any frame rate, drop/non-drop frame counts, basic arithmetic,
and conversion between frame rates and drop/non-drop frame counts. The only
requirements are that the timecode be between 00:00:00:00 and 99:99:99:99,
inclusive, and frames per second (fps) are greater than zero. This means that
you can create nonstandard timecodes (feature or bug? :^). Dropframe rules will still
apply.

C<Time::Timecode> instances can be created from a a variety of representations,
see L</CONSTRUCTOR>.

C<Time::Timecode> instances are immutable.

=head1 CONSTRUCTOR

=over 2

=item C<new( TIMECODE [, OPTIONS ] )>

Creates an immutable instance for C<TIMECODE> with the given set of C<OPTIONS>.
If no C<OPTIONS> are given L<the package defaults|/DEFAULTS> are used.

=back

=head2 TIMECODE

C<TIMECODE> can be one of the following:

=over 4

=item * A list denoting hours, minutes, seconds, and/or frames:

 $tc1 = Time::Timecode->new(1, 2, 3)
 $tc1 = Time::Timecode->new(1, 2, 3, 0)   #same as above

=item * Frame count:

 $tc1 = Time::Timecode->new(1800)   # 00:01:00:00 @ 30 fps

=item * Timecode string:

 $tc1 = Time::Timecode->new('00:02:00:25')

B<Timecode strings with dropframe frame delimiters>

In the video encoding world timecodes with a frame delimiter of "." or ";" are considered
dropframe. If either of these characters are used in the timecode string passed to C<new>
the resulting instance will dropframe.

This can be overridden by setting L<the dropframe argument|/* dropframe> to false.

=back

=head2 OPTIONS

C<OPTIONS> must be a hash reference and can contain any of the following:

=over 4

=item * fps:

Frames per second, must be greater than 0. Defaults to C<$Time::Timecode::DEFAULT_FPS>

=item * dropframe:

A boolean value denoting wheather or not the timecode
is dropframe. Defaults to C<$Time::Timecode::DEFAULT_DROPFRAME>.

=item * delimiter:

The character used to delimit the timecode's hours, minutes,
and seconds. Use L<the frame_delimiter option|/* frame_delimiter> for delimiting the frames.
Defaults to C<$Time::Timecode::DEFAULT_DELIMITER>.

=item * frame_delimiter:

The character used to delimit the timecode's frames.
Use L<the delimiter option|/* delimiter> for delimiting the rest of the timecode.
Defaults to C<$Time::Timecode::DEFAULT_FRAME_DELIMITER>.

=back

=head1 METHODS

All time part accessors return an integer except C<frames> which, depending on the
frame rate, can return a float.

=over 2

=item C<hours>

=item C<hrs>

=item C<hh>

Returns the hour part of the timecode

=item C<minutes>

=item C<mins>

=item C<mm>

Returns the mintue part of the timecode

=item C<seconds>

=item C<secs>

=item C<ss>

Returns the second part of the timecode

=item C<frames>

=item C<ff>

Returns the frame part of the timecode

=item C<fps>

Returns the frames per second

=item C<total_frames>

Returns the timecode in frames

=item C<to_string([FORMAT])>

Returns the timecode as string described by C<FORMAT>. If C<FORMAT> is not provided the
string will be constructed according to the L<instance's defaults|/DEFAULTS>.

  $tc = Time::Timecode->new(2,0,10,24);
  $tc->to_string			# 02:00:10:24
  "$tc"					# Same as above
  $tc->to_string('%02H%02M%S.%03f DF')	# 020010.024 DF

C<FORMAT> is string of characters synonymous (mostly, in some way) with
those used by C<< strftime(3) >>, with the exception that no leading zero will be added
to single digit values. If you want leading zeros you must specify a field width like
you would with C<< printf(3) >>.

The following formats are supported:

%H B<H>ours

%M B<M>inutes

%S B<S>econds

%f B<f>rames

%i B<i>n frames (i.e., C<< $tc->total_frames >>)

%r Frame B<r>ate

%s Frames as a fraction of a second

%T B<T>imecode in the L<instance's default format|/DEFAULTS>.

%% Literal percent character

When applicable, formats assume the width of the number they represent.

If a C<FORMAT> is not provided the delimiter used to separate each portion of the timecode can vary.
If the C<delimiter> or C<frame_delimiter> options were provided they will be used here.
If the timecode was created from a timecode string that representation will be reconstructed.

This method is overloaded and will be called when an instance is quoted. I.e., C<< "$tc" eq $tc->to_string >>

=item C<is_dropframe>

Returns a boolean value denoting whether or not the timecode is dropframe.

=item C<to_non_dropframe>

Converts the timecode to non-dropframe and returns a new C<Time::Timecode> instance.
The framerate is not changed.

If the current timecode is non-dropframe C<$self> is returned.

=item C<to_dropframe>

Converts the timecode to dropframe and returns a new C<Time::Timecode> instance.
The framerate is not changed.

If the current timecode is dropframe C<$self> is returned.

=item C<convert( FPS [, OPTIONS ] )>

Converts the timecode to C<FPS> and returns a new instance.

C<OPTIONS> are the same as L<those allowed by the CONSTRUCTOR|/OPTIONS>. Any unspecified options
will be taken from the calling instance.

The converted timecode will be non-dropframe.

=back

=head1 ARITHMETIC & COMPARISON

Arithmatic and comparison are provided via operator overloading. When applicable results get
L<their options|/OPTIONS> from the left hand side (LHS) of the expression. If the LHS is a
literal the options will be taken from the right hand side.

=head2 Supported Operations

=head3 Addition

  $tc1 = Time::Timecode->new(1800);
  $tc2 = Time::Timecode->new(1);
  print $tc1 + $tc2;
  print $tc1 + 1800;
  print 1800 + $tc1;
  print $tc1 + '00:10:00:00';

=head3 Subtraction

  $tc1 = Time::Timecode->new(3600);
  $tc2 = Time::Timecode->new(1);
  print $tc1 - $tc2;
  print $tc1 - 1800;
  print 1800 - $tc1;
  print $tc1 - '00:00:02:00';

=head3 Multiplication

  $tc1 = Time::Timecode->new(1800);
  print $tc1 * 2;
  print 2 * $tc1;

=head3 Division

  $tc1 = Time::Timecode->new(1800);
  print $tc1 / 2;

=head3 Pre/postincrement with/without assignment

  $tc1 = Time::Timecode->new(1800);
  $tc1 += 10;		# Add 10 frames
  print ++$tc1;		# Add 1 frame
  print $tc1--;		# Subtract it after printing

=head3 All comparison operators

  $tc1 = Time::Timecode->new(1800);
  $tc2 = Time::Timecode->new(1800);
  print 'equal!' if $tc1 == $tc2;
  print 'less than' if $tc1 < '02:00:12;22';
  print 'greater than' if $tc1 >= '02:00:12;22';
  # ....

=head1 TIMECODE CONVERSION UTILITY PROGRAM

C<Time::Timecode> includes an executable called C<timecode> that allows one to perform timecode conversions
from the command line:

  usage: timecode [-h] [-c spec] [-f format] [-i spec] [timecode]
      -h --help		   option help
      -c --convert spec      convert timecode according to `spec'
			     `spec' can be a number of FPS proceeded by an optional `N' or `ND' or, a comma
			     separated list of key=value. key can be fps, dropframe, delimiter, frame_delimiter
      -f --format  format    output timecode according to `format' e.g., '%H:%M:%S at %r FPS'.
			     %H=hours, %M=mins, %S=secs, %f=frames %i=total frames, %r=frame rate, %s=frames in secs
      -i --input   spec      process incoming timecodes according to `spec'; see -c for more info
      -q --quiet             ignore invalid timecodes
      -v --version           print version information

  If no timecode is given timecodes will be read from stdin.

=head2 Examples

=head3 Convert a 29.97 non drop frame count to a timecode

  timecode -i 29.97nd -f %T 1800
  00:01:00:00

=head3 Convert 24 to 29.97 drop and output the result as frames

  timecode -i 24 -c 29.97d -f %i 00:12:33:19
  18091

=head3 Convert a list of timecodes from a file to a custom format, ignoring invalid timecodes

  cat > /tmp/times.txt
  02:01:00:12
  foo!
  02:02:21:00
  02:01:00:02

  timecode -qi 24 -f '%Hh %Mm %Ss and %f frames' < /tmp/times.txt
  02:01:00:12 2h 1m 0s and 12 frames
  02:02:21:00 2h 2m 21s and 0 frames
  02:01:00:02 2h 1m 0s and 2 frames

=head1 DEFAULTS

All defaults except C<$DEFAULT_TO_STRING_FORMAT> can be overridden when L<creating a new instance|/CONSTRUCTOR>.
C<$DEFAULT_TO_STRING_FORMAT> can be overridden by passing a format to C<< L<to_string|/to_string([FORMAT])> >>.

C<$DEFAULT_FPS = 29.97>

C<$DEFAULT_DROPFRAME = 0>

C<$DEFAULT_DELIMITER = ':'>

C<$DEFAULT_FRAME_DELIMITER = ':'>

C<$DEFAULT_TO_STRING_FORMAT = 'HHxMMxSSxFF'>  where C<x> represents the instance's frame and time separators.

=head1 AUTHOR

Skye Shaw (skye.shaw [AT] gmail)

=head1 CREDITS

Jinha Kim for schooling me on dropframe timecodes.

L<Andrew Duncan|http://andrewduncan.net/> (and L<David Heidelberger|http://www.davidheidelberger.com/>)
for the L<nice drop frame algorithm|http://www.davidheidelberger.com/blog/?p=29>.

=head1 REFERENCES

For information about dropframe timecodes see:
L<http://andrewduncan.net/timecodes/>, L<http://dropframetimecode.org/>, L<http://en.wikipedia.org/wiki/SMPTE_time_code#Drop_frame_timecode>

=head1 COPYRIGHT

Copyright (c) 2009-2016 Skye Shaw. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
