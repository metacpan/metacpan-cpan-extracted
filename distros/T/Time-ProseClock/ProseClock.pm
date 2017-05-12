require 5.004;
package Time::ProseClock;

use strict;
use vars qw($VERSION);
$VERSION = 1.02;

use Carp();

sub new
{
  my $self = shift;

  $self = bless {}, ref($self) || $self;

  $self->_set_phrases();

  return $self;
}

sub display
{
  my $self = shift;
  my $time_arg = shift || time;

  Carp::croak(qq[invalid time format [$time_arg]])
      if $time_arg !~ /^\d+$/;

  $self->_get_time($time_arg);
  $self->_set_minute();
  $self->_set_hour();

  my $txt = qq[$self->{'min_phrase'} $self->{'mul_phrase'} $self->{'hour_phrase'}];
  $txt =~ s| {2,}| |; # there may not be a mul_phrase
  return $txt;
}


#------------------------------------------------------------------------------#
# private methods                                                              #
#------------------------------------------------------------------------------#
sub _set_hour
{
  my $self = shift;

  my $hours = $self->{'time'}->{'hours'};

  if ($self->{'mul'} >= 35)
  {
    ($hours == 23) ? $hours = 0 : $hours++;
  }

  $self->{'hour_phrase'} = $self->{'HourPhrases'}->[$hours];

  if (($hours == 0) && ($self->{'time'}->{'minutes'} < 3))
  {
    $self->{'mul_phrase'} = '';
  }

  return;
}

sub _set_minute
{
  my $self = shift;

  my $minutes = $self->{'time'}->{'minutes'};

  my $remainder = $minutes % 5;

  $self->{'mul'} = $minutes - $remainder;

  # switch frame of reference
  $self->{'mul'} += 5 if $remainder >= 3;

  $self->{'min_phrase'} = $self->{'MinutePhrases'}->[$remainder];

  if (exists($self->{'Multiples'}->{$self->{'mul'}}))
  {
    $self->{'mul_phrase'} = $self->{'Multiples'}->{$self->{'mul'}};
  }
  else
  {
    $self->{'mul_phrase'} = '';
  }

  return;
}

# We only need hours and minutes; finer granularity would be unprosaic.
sub _get_time
{
  my $self = shift;
  my $time_arg = shift;
  @{$self->{'time'}}{qw(minutes hours)} = (localtime($time_arg))[1, 2];
  return;
}

sub _set_phrases
{
  my $self = shift;

  $self->{'MinutePhrases'} =
    [
     'exactly',
     'just after',
     'a little after',
     'coming up to',
     'almost',
    ];

  $self->{'Multiples'} =
    {
      0 => '',
      5 => 'five past',
     10 => 'ten past',
     15 => 'quarter past',
     20 => 'twenty past',
     25 => 'twenty-five past',
     30 => 'half past',
     35 => 'twenty-five to',
     40 => 'twenty to',
     45 => 'quarter to',
     50 => 'ten to',
     55 => 'five to',
    };

  $self->{'HourPhrases'} =
    [
     'midnight',
     'one in the morning',
     'two in the morning',
     'three in the morning',
     'four in the morning',
     'five in the morning',
     'six in the morning',
     'seven in the morning',
     'eight in the morning',
     'nine in the morning',
     'ten in the morning',
     'eleven in the morning',
     'noon',
     'one in the afternoon',
     'two in the afternoon',
     'three in the afternoon',
     'four in the afternoon',
     'five in the afternoon',
     'six at night',
     'seven at night',
     'eight at night',
     'nine at night',
     'ten at night',
     'eleven at night',
    ];

  return;
}

1;

__END__

=head1 NAME

Time::ProseClock - an alternative to digital and analog formats

=head1 SYNOPSIS

  use Time::ProseClock;

  my $time = Time::ProseClock->new();
  print $time->display();

  If the time were between 09:06:01 - 09:06:59 it would display:

      just after five past nine in the morning

  Granularity is a minute.  It would undermine the philosophy of
  ProseClock to display, for example, "just after five past nine in
  the morning and twenty-four seconds."

  An optional parameter to the display() method can show a
  user-defined time instead of the system time:

      print $time->display(time - 3600);

  to display the time one hour ago. 'time' is the number of non-leap
  seconds since whatever time the system considers to be the epoch.

=head1 DESCRIPTION

Time::ProseClock displays the time in the manner of a spoken English
colloquial expression.  It's aware of the notions of morning,
afternoon, and night, thus always in 24 hour mode.  Localization
integration hooks for other languages may be forthcoming.

=head1 AUTHOR

Gerald Gold <gold@channelping.com>

=head1 COPYRIGHT

Copyright (c) 2003-Eternity Gerald Gold and channelping.  All rights
reserved.  This class is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
