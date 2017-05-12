package Time::Clock;

use strict;

use Carp;

our $VERSION = '1.03';

use overload
(
  '""' => sub { shift->as_string },
   fallback => 1,
);

our $Have_HiRes_Time;

TRY:
{
  local $@;
  eval { require Time::HiRes };
  $Have_HiRes_Time = $@ ? 0 : 1;
}

# Allow an hour value of 24
our $Allow_Hour_24 = 0;

use constant NANOSECONDS_IN_A_SECOND => 1_000_000_000;
use constant SECONDS_IN_A_MINUTE     => 60;
use constant SECONDS_IN_AN_HOUR      => SECONDS_IN_A_MINUTE * 60;
use constant SECONDS_IN_A_CLOCK      => SECONDS_IN_AN_HOUR * 24;

use constant DEFAULT_FORMAT => '%H:%M:%S%n';

our %Default_Format;

__PACKAGE__->default_format(DEFAULT_FORMAT);

sub default_format
{
  my($invocant) = shift;

  # Called as object method
  if(ref $invocant)
  {
    return $invocant->{'default_format'} = shift  if(@_);
    return ref($invocant)->default_format;
  }

  # Called as class method
  return $Default_Format{$invocant} = shift  if(@_);
  return $Default_Format{$invocant} ||= DEFAULT_FORMAT;
}

sub new
{
  my($class) = shift;

  my $self = bless {}, $class;
  @_ = (parse => @_)  if(@_ == 1);
  $self->init(@_);

  return $self;
}

sub init
{
  my($self) = shift;

  while(@_)
  {
    my $method = shift;
    $self->$method(shift);
  }
}

sub hour
{
  my($self) = shift;

  if(@_)
  {
    my $hour = shift;

    if($Allow_Hour_24)
    {
      croak "hour must be between 0 and 24"  
        unless(!defined $hour || ($hour >= 0 && $hour <= 24));
    }
    else
    {
      croak "hour must be between 0 and 23"  
        unless(!defined $hour || ($hour >= 0 && $hour <= 23));
    }

    return $self->{'hour'} = $hour;
  }

  return $self->{'hour'} ||= 0;
}

sub minute
{
  my($self) = shift;

  if(@_)
  {
    my $minute = shift;

    croak "minute must be between 0 and 59"  
      unless(!defined $minute || ($minute >= 0 && $minute <= 59));

    return $self->{'minute'} = $minute;
  }

  return $self->{'minute'} ||= 0;
}

sub second
{
  my($self) = shift;

  if(@_)
  {
    my $second = shift;

    croak "second must be between 0 and 59"  
      unless(!defined $second || ($second >= 0 && $second <= 59));

    return $self->{'second'} = $second;
  }

  return $self->{'second'} ||= 0;
}

sub nanosecond
{
  my($self) = shift;

  if(@_)
  {
    my $nanosecond = shift;

    croak "nanosecond must be between 0 and ", (NANOSECONDS_IN_A_SECOND - 1)
      unless(!defined $nanosecond || ($nanosecond >= 0 && $nanosecond < NANOSECONDS_IN_A_SECOND));

    return $self->{'nanosecond'} = $nanosecond;
  }

  return $self->{'nanosecond'};
}

sub ampm
{
  my($self) = shift;

  if(@_ && defined $_[0])
  {
    my $ampm = shift;

    if($ampm =~ /^a\.?m\.?$/i)
    {
      if($self->hour > 12)
      {
        croak "Cannot set AM/PM to AM when hour is set to ", $self->hour;
      }
      elsif($self->hour == 12)
      {
        $self->hour(0);
      }

      return 'am';
    }
    elsif($ampm =~ /^p\.?m\.?$/i)
    {
      if($self->hour < 12)
      {
        $self->hour($self->hour + 12);
      }

      return 'pm';
    }
    else { croak "AM/PM value not understood: $ampm" }
  }

  return ($self->hour >= 12) ? 'PM' : 'AM';
}

sub as_string 
{
  my($self) = shift;
  return $self->format($self->default_format);
}

sub format
{
  my($self, $format) = @_;

  $format ||= ref($self)->default_format;

  my $hour  = $self->hour;
  my $ihour = $hour > 12 ? ($hour - 12) : $hour == 0 ? 12 : $hour;
  my $ns     = $self->nanosecond;

  $ihour =~ s/^0//;

  my %formats =
  (
    'H' => sprintf('%02d', $hour),
    'I' => sprintf('%02d', $ihour),
    'i' => $ihour,
    'k' => $hour,
    'M' => sprintf('%02d', $self->minute),
    'S' => sprintf('%02d', $self->second),
    'N' => sprintf('%09d', $ns || 0),
    'n' => defined $ns ? sprintf('.%09d', $ns) : '',
    'p' => $self->ampm,
    'P' => lc $self->ampm,
    's' => $self->as_integer_seconds,
  );

  $formats{'n'} =~ s/\.?0+$//;

  for($format)
  {
    s{ ((?:%%|[^%]+)*) %T }{$1%H:%M:%S}gx;

    s/%([HIikMSsNnpP])/$formats{$1}/g;

    no warnings 'uninitialized';
    s{ ((?:%%|[^%]+)*) % ([1-9]) N }{ $1 . substr(sprintf("%09d", $ns || 0), 0, $2) }gex;

    if(defined $ns)
    {
      s{ ((?:%%|[^%]+)*) % ([1-9]) n }{ "$1." . substr(sprintf("%09d", $ns || 0), 0, $2) }gex;
    }
    else
    {
      s{ ((?:%%|[^%]+)*) % ([1-9]) n }{$1}gx;
    }

    s/%%/%/g;
  }

  return $format;
}

sub parse
{
  my($self, $time) = @_;

  if(my($hour, $min, $sec, $fsec, $ampm) = ($time =~ 
  m{^
      (\d\d?) # hour
      (?::(\d\d)(?::(\d\d))?)?(?:\.(\d{0,9})\d*)? # min? sec? nanosec?
      (?:\s*([aApP]\.?[mM]\.?))? # am/pm
    $
  }x))
  {
    # Special case to allow times of 24:00:00, which the Postgres
    # database considers valid (presumably in order to account for
    # leap seconds)
    if($hour == 24)
    {
      no warnings 'uninitialized';
      if($min == 0 && $sec == 0 && $fsec == 0)
      {
        local $Allow_Hour_24 = 1;
        $self->hour($hour);
      }
      else
      {
        croak "Could not parse time '$time' - an hour value of 24 is only ",
              "allowed if minutes, seconds, and nanoseconds are all zero"  
      }
    }
    else { $self->hour($hour) }

    $self->minute($min);
    $self->second($sec);
    $self->ampm($ampm);

    if(defined $fsec)
    {
      my $len = length $fsec;

      if($len < 9)
      {
        $fsec .= ('0' x (9 - $len));
      }
      elsif($len > 9)
      {
        $fsec = substr($fsec, 0, 9);
      }
    }

    $self->nanosecond($fsec);
  }
  elsif($time eq 'now')
  {
    if($Have_HiRes_Time)
    {
      (my $fsecs = Time::HiRes::time()) =~ s/^.*\.//;
      return $self->parse(sprintf("%d:%02d:%02d.$fsecs", (localtime(time))[2,1,0]));
    }
    else
    {
      return $self->parse(sprintf('%d:%02d:%02d', (localtime(time))[2,1,0]));
    }
  }
  else
  {
    croak "Could not parse time '$time'";
  }

  return $self;
}

sub as_integer_seconds
{
  my($self) = shift;

  return ($self->hour * SECONDS_IN_AN_HOUR) +
         ($self->minute * SECONDS_IN_A_MINUTE) +
         $self->second;
}

sub delta_as_integer_seconds
{
  my($self, %args) = @_;
  return (($args{'hours'} || 0) * SECONDS_IN_AN_HOUR) +
         (($args{'minutes'} || 0) * SECONDS_IN_A_MINUTE) +
         ($args{'seconds'} || 0);
}

sub parse_delta
{
  my($self) = shift;

  if(@_ == 1)
  {
    my $delta = shift;

    if(my($hour, $min, $sec, $fsec) = ($delta =~ 
    m{^
        (\d+)               # hours
        (?::(\d+))?         # minutes
        (?::(\d+))?         # seconds
        (?:\.(\d{0,9})\d*)? # nanoseconds
      $
    }x))
    {
      if(defined $fsec)
      {
        my $len = length $fsec;

        if($len < 9)
        {
          $fsec .= ('0' x (9 - $len));
        }

        $fsec = $fsec + 0;
      }

      return
      (
        hours       => $hour,
        minutes     => $min,
        seconds     => $sec,
        nanoseconds => $fsec,
      );
    }
    else { croak "Time delta not understood: $delta" }
  }

  return @_;
}

sub add
{
  my($self) = shift;

  my %args = $self->parse_delta(@_);
  my $secs = $self->as_integer_seconds + $self->delta_as_integer_seconds(%args);

  if(defined $args{'nanoseconds'})
  {
    my $ns_arg = $args{'nanoseconds'};
    my $nsec   = $self->nanosecond || 0;

    if($ns_arg + $nsec < NANOSECONDS_IN_A_SECOND)
    {
      $self->nanosecond($ns_arg + $nsec);
    }
    else
    {
      $secs += int(($ns_arg + $nsec) / NANOSECONDS_IN_A_SECOND);
      $self->nanosecond(($ns_arg + $nsec) % NANOSECONDS_IN_A_SECOND);
    }
  }

  $self->init_with_seconds($secs);

  return;
}

sub subtract
{
  my($self) = shift;

  my %args = $self->parse_delta(@_);
  my $secs = $self->as_integer_seconds - $self->delta_as_integer_seconds(%args);

  if(defined $args{'nanoseconds'})
  {
    my $ns_arg = $args{'nanoseconds'};
    my $nsec   = $self->nanosecond || 0;

    if($nsec - $ns_arg >= 0)
    {
      $self->nanosecond($nsec - $ns_arg);
    }
    else
    {
      if(abs($nsec - $ns_arg) >= NANOSECONDS_IN_A_SECOND)
      {
        $secs -= int($ns_arg / NANOSECONDS_IN_A_SECOND);
      }
      else
      {
        $secs--;
      }

      $self->nanosecond(($nsec - $ns_arg) % NANOSECONDS_IN_A_SECOND);
    }
  }

  if($secs < 0)
  {
    $secs = $secs % SECONDS_IN_A_CLOCK;
  }

  $self->init_with_seconds($secs);

  return;
}

sub init_with_seconds
{
  my($self, $secs) = @_;

  if($secs >= SECONDS_IN_A_CLOCK)
  {
    $secs = $secs % SECONDS_IN_A_CLOCK;
  }

  if($secs >= SECONDS_IN_AN_HOUR)
  {
    $self->hour(int($secs / SECONDS_IN_AN_HOUR));
    $secs -= $self->hour * SECONDS_IN_AN_HOUR;
  }
  else { $self->hour(0) }

  if($secs >= SECONDS_IN_A_MINUTE)
  {
    $self->minute(int($secs / SECONDS_IN_A_MINUTE));
    $secs -= $self->minute * SECONDS_IN_A_MINUTE;
  }
  else { $self->minute(0) }

  $self->second($secs);

  return;
}

1;

__END__

=head1 NAME

Time::Clock - Twenty-four hour clock object with nanosecond precision.

=head1 SYNOPSIS

  $t = Time::Clock->new(hour => 12, minute => 34, second => 56);
  print $t->as_string; # 12:34:56

  $t->parse('8pm');
  print "$t"; # 20:00:00

  print $t->format('%I:%M %p'); # 08:00 PM

  $t->add(minutes => 15, nanoseconds => 123000000);
  print $t->as_string; # 20:15:00.123

  $t->subtract(hours => 30);
  print $t->as_string; # 14:15:00.123

  ...

=head1 DESCRIPTION

A L<Time::Clock> object is a twenty-four hour clock with nanosecond precision and wrap-around.  It is a clock only; it has absolutely no concept of dates.  Vagaries of date/time such as leap seconds and daylight savings time are unsupported.

When a L<Time::Clock> object hits 23:59:59.999999999 and at least one more nanosecond is added, it will wrap around to 00:00:00.000000000.  This works in reverse when time is subtracted.

L<Time::Clock> objects automatically stringify to a user-definable format.

=head1 CLASS METHODS

=over 4

=item B<default_format FORMAT>

Set the default format used by the L<as_string|/as_string> method for all objects of this class.  Defaults to "%H:%M:%S%n".  See the documentation for the L<format|/format> method for a complete list of format specifiers.

Note that this method may also be called as an object method, in which case it sets the default format for the individual object only.

=back

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Time::Clock> object based on PARAMS, where PARAMS are
name/value pairs.  Any object method is a valid parameter name.  Example:

    $t = Time::Clock->new(hour => 12, minute => 34, second => 56);

If a single argument is passed to L<new|/new>, it is equivalent to calling the L<parse|/parse> method.  That is, this:

    $t = Time::Clock->new('12:34:56');

is equivalent to this:

    $t = Time::Clock->new;
    $t->parse('12:34:56');

Returns the newly constructed L<Time::Clock> object.

=back

=head1 OBJECT METHODS

=over 4

=item B<add PARAMS>

Add the time specified by PARAMS to the clock.  Valid PARAMS are:

=over 4

=item C<hours INT>

An integer number of hours.

=item C<minutes INT>

An integer number of minutes.

=item C<seconds INT>

An integer number of seconds.

=item C<nanoseconds INT>

An integer number of nanoseconds.

=back

If the amount of time added is large enough, the clock will wrap around from 23:59:59.999999999 to 00:00:00.000000000 as needed.

=item B<ampm AM/PM>

Get or set the AM/PM attribute of the clock.  Valid values of AM/PM must contain the letters "AM" or "PM" (case-insensitive), optionally followed by periods.

A clock whose L<hour|/hour> is greater than 12 cannot be set to AM.  Any attempt to do so will cause a fatal error.

Setting a clock whose L<hour|/hour> is less than 12 to PM will cause its  L<hour|/hour> to be increased by 12.  Example:

    $t = Time::Clock->new('8:00');
    print $t->as_string; # 08:00:00

    $t->ampm('PM');
    print $t->as_string; # 20:00:00

Return the string "AM" if the L<hour|/hour> is less than 12, "PM" otherwise.

=item B<as_integer_seconds>

Returns the integer number of seconds since 00:00:00.

=item B<as_string>

Returns a string representation of the clock, formatted according to the clock object's L<default_format|/default_format>.

=item B<default_format FORMAT>

Set the default format used by the L<as_string|/as_string> method for this object.  Defaults to "%H:%M:%S%n".  See the documentation for the L<format|/format> method for a complete list of format specifiers.

Note that this method may also be called as a class method, in which case it sets the default format all objects of this class.

=item B<format FORMAT>

Returns the clock value formatted according to the FORMAT string containing "%"-prefixed format specifiers.  Valid format specifiers are:

=over 4

=item C<%H>

The hour as a two-digit, zero-padded integer using a 24-hour clock (range 00 to 23).

=item C<%I>

The hour as a two-digit, zero-padded integer using a 12-hour clock (range 01 to 12).

=item C<%i>

The hour as an integer using a 12-hour clock (range 1 to 12).

=item C<%k>

The hour as an integer using a 24-hour clock (range 0 to 23).

=item C<%M>

The minute as a two-digit, zero-padded integer (range 00 to 59).

=item C<%n>

If the clock has a non-zero L<nanosecond|/nanosecond> value, then this format produces a decimal point followed by the fractional seconds up to and including the last non-zero digit.  If no L<nanosecond|/nanosecond> value is defined, or if it is zero, then this format produces an empty string.  Examples:

    $t = Time::Clock->new('12:34:56');
    print $t->format('%H:%M:%S%n'); # 12:34:56

    $t->nanosecond(0);
    print $t->format('%H:%M:%S%n'); # 12:34:56

    $t->nanosecond(123000000);
    print $t->format('%H:%M:%S%n'); # 12:34:56.123

=item C<%[1-9]n>

If the clock has a defined L<nanosecond|/nanosecond> value, then this format produces a decimal point followed by the specified number of digits of fractional seconds (1-9).  Examples:

    $t = Time::Clock->new('12:34:56');
    print $t->format('%H:%M:%S%4n'); # 12:34:56

    $t->nanosecond(0);
    print $t->format('%H:%M:%S%4n'); # 12:34:56.0000

    $t->nanosecond(123000000);
    print $t->format('%H:%M:%S%4n'); # 12:34:56.1230

=item C<%N>

Nanoseconds as a nine-digit, zero-padded integer (range 000000000 to 999999999)

=item C<%[1-9]N>

Fractional seconds as a one- to nine-digit, zero-padded integer.  Examples:

    $t = Time::Clock->new('12:34:56');
    print $t->format('%H:%M:%S.%4N'); # 12:34:56.0000

    $t->nanosecond(123000000);
    print $t->format('%H:%M:%S.%6N'); # 12:34:56.123000

    $t->nanosecond(123000000);
    print $t->format('%H:%M:%S.%2N'); # 12:34:56.12

=item C<%p>

Either "AM" or "PM" according to the value return by the L<ampm|/ampm> method.

=item C<%P>

Like %p but lowercase: "am" or "pm"

=item C<%S>

The second as a two-digit, zero-padded integer (range 00 to 61).

=item C<%s>

The integer number of seconds since 00:00:00.

=item C<%T>

The time in 24-hour notation (%H:%M:%S).

=item C<%%>

A literal "%" character.

=back

=item B<hour INT>

Get or set the hour of the clock.  INT must be an integer from 0 to 23.

=item B<minute INT>

Get or set the minute of the clock.  INT must be an integer from 0 to 59.

=item B<nanosecond INT>

Get or set the nanosecond of the clock.  INT must be an integer from 0 to 999999999.

=item B<parse STRING>

Set the clock time by parsing STRING.  The invoking object is returned.

Valid string values contain an hour with optional minutes, seconds, fractional seconds, and AM/PM string.  There should be a colon (":") between hours, minutes, and seconds, and a decimal point (".") between the seconds and fractional seconds.  Fractional seconds may contain up to 9 digits.  The AM/PM string is case-insensitive and may have periods after each letter.

The string "now" will initialize the clock object with the current (local) time.  If the L<Time::HiRes> module is installed, this time will have fractional seconds.

A time value with an hour of 24 and zero minutes, seconds, and nanoseconds is also accepted by this method.

Here are some examples of valid time strings:

    12:34:56.123456789
    12:34:56.123 PM
    24:00
    8:30pm
    6 A.m.
    now

=item B<second INT>

Get or set the second of the clock.  INT must be an integer from 0 to 59.

=item B<subtract PARAMS>

Subtract the time specified by PARAMS from the clock.  Valid PARAMS are:

=over 4

=item C<hours INT>

An integer number of hours.

=item C<minutes INT>

An integer number of minutes.

=item C<seconds INT>

An integer number of seconds.

=item C<nanoseconds INT>

An integer number of nanoseconds.

=back

If the amount of time subtracted is large enough, the clock will wrap around from 00:00:00.000000000 to 23:59:59.999999999 as needed.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
