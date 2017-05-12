package XML::Loy::Date::RFC3339;
use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

our $VERSION = '0.03';

require Time::Local;

# rfc3339 timestamp
my $RFC3339_RE = qr/^(\d{4})          # year
                     (?:-(\d?\d)      # year and month
                      (?:-(\d?\d)     # complete date
                       (?:[^\d](\d?\d) # + hour and minutes
                         :(\d?\d)
                        (?::(\d?\d)   # + hour, minutes and seconds
                         (?:\.\d*)?   # + hour, minutes, seconds and a
                        )?            #   decimal fraction of a second
                        ([zZ]|[\-\+]\d?\d(?::?\d?\d)?) # Offset
                       )?
                      )?
                     )?$/x;

# Timestamp offset
my $OFFSET_RE = qr/^([-\+])(\d?\d)(?::(\d?\d))?$/;

# Constructor
sub new {
  my $self = bless {}, (ref $_[0] ? ref shift : shift);

  # Set granularity
  $self->granularity(0);

  # Parse string
  $self->parse(@_);
  return $self;
};


# Parse date value
sub parse {
  my ($self, $date) = @_;

  # No date defined
  return $self unless defined $date;

  # Epoch date
  if ($date =~ /^[\d_]+$/ && $date > 5000) {
    $self->epoch($date);
    $self->granularity(0);
  }

  # String date
  elsif (my ($year, $month, $mday,
	     $hour, $min, $sec,
	     $offset) = ($date =~ $RFC3339_RE)) {
    my $epoch;

    # Check for granularity
    my $gran = 0;

    # No seconds defined
    unless (defined $sec) {
      $gran = 1, $sec = 0;

      # No hours defined
      unless (defined $hour) {
	$gran++, $hour = $min = 0;

	# No monthday defined
	unless (defined $mday) {
	  $gran++, $mday = 1;

	  # No month defined
	  unless (defined $month) {
	    $gran++, $month = 1;
	  };
	};
      };
      $offset ||= 'Z';
    };

    # Begin counting with 0
    $month--;

    # Set granularity
    $self->granularity($gran);

    eval {
      $epoch = Time::Local::timegm(
	$sec, $min, $hour, $mday, $month, $year
      );
    };

    return if $@;

    # Calculate offsets
    if (uc $offset ne 'Z' && (
      my ($os_dir, $os_hour, $os_min) = ($offset =~ $OFFSET_RE))
      ) {

      # Negative offset
      if ($os_dir eq '-') {
	$epoch += ($os_hour * 60 * 60) if $os_hour;
	$epoch += ($os_min * 60)       if $os_min;
      }

      # Positive offset
      else {
	$epoch -= ($os_hour * 60 * 60) if $os_hour;
	$epoch -= ($os_min * 60)       if $os_min;
      };
    };

    # Positive epoch
    if ($epoch > 0) {
      $self->epoch($epoch) and return $epoch;
    };
  }

  # No valid datetime
  else {
    return;
  };

  return $self;
};


# return string
sub to_string {
  my $self  = shift;
  my $level = $_[0] // $self->granularity;

  # Take the current time if no time given
  my $epoch = $self->epoch // time;

  # Get gmtime
  my ($sec, $min, $hour, $mday, $month, $year) = gmtime $epoch;

  # Format
  my $s = '%04d';
  my @a = ($year + 1900);
  $s .= '-%02d'      and push(@a, $month + 1)  if $level < 4;
  $s .= '-%02d'      and push(@a, $mday)       if $level < 3;
  $s .= 'T%02d:%02d' and push(@a, $hour, $min) if $level < 2;
  $s .= ':%02d'      and push(@a, $sec)        if $level < 1;
  $s .= 'Z' if $level < 2;

  return sprintf($s, @a);
};


# Epoch datetime
sub epoch {
  my $self = shift;

  # Get epoch
  return $self->{epoch} unless @_;

  # Set epoch if valid
  if ($_[0] && $_[0] =~ /^[_\d]+$/) {

    # Fine to set
    $self->{epoch} = shift;
    return 1;
  };

  # Fail to set
  return;
};


# Granularity
sub granularity {
  my $self = shift;

  # Get granularity
  return $self->{granularity} unless @_;

  # Set granularity if valid
  if (defined $_[0] && grep { $_[0] == $_ } 0 .. 4) {

    # Fine to set
    $self->{granularity} = shift;
    return 1;
  };

  # Fail to set
  return;
};


1;


__END__

=pod

=head1 NAME

XML::Loy::Date::RFC3339 - Date strings according to RFC3339

=head1 SYNOPSIS

  use XML::Loy::Date::RFC3339;

  my $date = XML::Loy::Date::RFC3339->new(784111777);
  my $date_str = $date->to_string;
  $date->parse('1993-01-01t18:50:00-04:00');
  my $epoch = $date->epoch;


=head1 DESCRIPTION

L<XML::Loy::Date::RFC3339> implements date and time functions
according to L<RFC3339|http://tools.ietf.org/html/rfc3339>.
In addition to that it supports granularity as described in
L<W3C date and time formats|http://www.w3.org/TR/NOTE-datetime>.

This module is meant to be compatible with the L<Mojo::Date>-API
but has no Mojo dependencies.

B<This module is EXPERIMENTAL and may be changed, replaced or
renamed without warnings.>

=head1 ATTRIBUTES

L<XML::Loy::Date::RFC3339> implements the following attributes.

=head2 epoch

  my $epoch = $date->epoch;
  $date     = $date->epoch(784111777);

Epoch seconds.


=head2 granularity

  my $granularity = $date->granularity;
  $date->granulariy(3);

Level of granularity.

=over 2

=item

0: Complete date plus hours, minutes and seconds

=item

1: Complete date plus hours and minutes

=item

2: Complete date

=item

3: Year and month

=item

4: Year

=back


=head1 METHODS

L<XML::Loy::Date::RFC3339> implements the following methods.


=head2 new

  my $date = XML::Loy::Date::RFC3339->new;
  my $date = XML::Loy::Date::RFC3339->new($string);

Constructs a new L<XML::Loy::Date::RFC3339> object.
Accepts a date string to be parsed.

=head2 parse

  $date = $date->parse('1993-01-01t18:50:00-04:00');
  $date = $date->parse('1993-01-01');
  $date = $date->parse(1312043400);

Parses L<RFC3339|http://tools.ietf.org/html/rfc3339>
and granularity compliant date strings.
Also accepts epoch seconds.


=head2 to_string

  my $string = $date->to_string;
  my $string = $date->to_string(3);

Renders date suitable to
L<RFC3339|http://tools.ietf.org/html/rfc3339>
without offset information.
Takes an optional parameter for granularity.
Uses the objects granularity level by default.


=head1 DEPENDENCIES

L<Time::Local>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016, L<Nils Diewald|http://nils-diewald.de/>.

The code is heavily based on L<Mojo::Date>,
written by Sebastian Riedel. See L<Mojo::Date>
for additional copyright and license information.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
