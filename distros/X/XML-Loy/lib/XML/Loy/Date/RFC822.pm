package XML::Loy::Date::RFC822;
use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

require Time::Local;

# Days
my @DAYS = qw/Sun Mon Tue Wed Thu Fri Sat/;
my $DAYS   = qr/(?:(?:Su|Mo)n|Wed|T(?:hu|ue)|Fri|Sat)/;

# Months
my %MONTHS;
my @MONTHS = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
@MONTHS{@MONTHS} = (0 .. 11);

# Zones
my %ZONE;
my $ZONE   = qr/(?:(?:GM|U)|(?:([ECMP])([SD])))T/;
@ZONE{qw/E C M P/} = (4..7);

my $RFC822_RE = qr/^\s*(?:$DAYS[a-z]*,)?\s*(\d+)\s+(\w+)\s+
                    (\d+)\s+(\d+):(\d+):(\d+)\s*(?:$ZONE|([-+]\d{4}))?\s*$/x;

# Constructor
sub new {
  my $self = bless {}, (ref $_[0] ? ref shift : shift);

  # Parse string
  $self->parse(@_);

  return $self;
};

# Parse date value
sub parse {
  my ($self, $date) = @_;

  return $self unless defined $date;

  if ($date =~ /^\d+$/) {
    $self->epoch($date);
  }

  elsif (my ($mday, $month, $year,
	     $hour, $min, $sec,
	     $zone_1, $zone_2, $zone_o) = ($date =~ $RFC822_RE)) {

    my $epoch;
    $month = $MONTHS{$month};

    # Set timezone offset
    my $offset = 0;
    my $offset_min = 0;

    if ($zone_1) {
      $offset = $ZONE{$zone_1};
      $offset++ if $zone_2 eq 'S';
    }
    elsif ($zone_o && $zone_o =~ /^([-+])\s*(\d\d)(\d\d)$/) {
      if ($1 eq '-') {
	$offset += $2;
	$offset_min += $3;
      }
      else {
	$offset -= $2;
	$offset_min -= $3;
      };
    };

    eval {
      $epoch = Time::Local::timegm($sec, $min, $hour,
				   $mday, $month, $year);
    };

    $epoch += ($offset * 60 * 60) if $offset;
    $epoch += ($offset_min * 60)  if $offset_min;

    if (!$@ && $epoch > 0) {
      $self->epoch($epoch);
    };
  };

  return $self;
};

# return string
sub to_string {
  my $self = shift;

  my $epoch = $self->epoch;
  $epoch = time unless defined $epoch;
  my ($sec, $min, $hour,
      $mday, $month, $year, $wday) = gmtime $epoch;

  # Format
  return sprintf(
    "%s, %02d %s %04d %02d:%02d:%02d GMT",
    $DAYS[$wday],
    $mday,
    $MONTHS[$month],
    $year + 1900,
    $hour,
    $min,
    $sec
  );
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


1;


__END__

=pod

=head1 NAME

XML::Loy::Date::RFC822 - Date strings according to RFC822

=head1 SYNOPSIS

  use XML::Loy::Date::RFC822;

  my $date = XML::Loy::Date::RFC822->new(1317832113);
  my $date_str = $date->to_string;
  $date->parse('Wed, 05 Oct 2011 09:28:33 PDT');
  my $epoch = $date->epoch;

=head1 DESCRIPTION

L<XML::Loy::Date::RFC822> implements date and time functions
according to L<RFC822|http://tools.ietf.org/html/rfc822>.
Other than L<Mojo::Date> it supports different timezones.

This module is meant to be compatible with the L<Mojo::Date>-API
but has no Mojo dependencies.

B<This module is EXPERIMENTAL and may be changed, replaced or
renamed without warnings.>

=head1 ATTRIBUTES

L<XML::Loy::Date::RFC822> implements the following attributes.

=head2 epoch

  my $epoch = $date->epoch;
  $date     = $date->epoch(1317832113);

Epoch seconds.

=head1 METHODS

=head2 new

  my $date = XML::Loy::Date::RFC822->new;
  my $date = XML::Loy::Date::RFC822->new($string);

Constructs a new L<XML::Loy::Date::822> object.
Accepts a date string to be parsed.

=head2 parse

  $date = $date->parse('Wed, 05 Oct 2011 09:28:33 PDT');
  $date = $date->parse(1317832113);

Parses L<RFC822|http://tools.ietf.org/html/rfc822> compliant date strings.
Also accepts epoch seconds.


=head2 to_string

  my $string = $date->to_string;

Renders date suitable to L<RFC822|http://tools.ietf.org/html/rfc822>
without offset information.


=head1 DEPENDENCIES

L<Time::Local>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

The code is heavily based on L<Mojo::Date>,
written by Sebastian Riedel. See L<Mojo::Date>
for additional copyright and license information.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
