package WARC::Date;						# -*- CPerl -*-

use strict;
use warnings;

use Carp;
use Time::Local;

our @ISA = qw();

require WARC; *WARC::Date::VERSION = \$WARC::VERSION;

=head1 NAME

WARC::Date - datestamp objects for WARC library

=head1 SYNOPSIS

  use WARC::Date;

  $datestamp = WARC::Date->now();		# construct from current time
  $datestamp = WARC::Date->from_epoch(time);	# likewise
  $datestamp = WARC::Date->from_string($string);# construct from string

  $time = $datestamp->as_epoch;		# as seconds since epoch
  $text = $datestamp->as_string;	# as "YYYY-MM-DDThh:mm:ssZ"

=cut

use overload '""' => \&as_string, '0+' => \&as_epoch;
use overload fallback => 1;

# This implementation needs to store only a single value, either an epoch
#  timestamp or a [W3C-NOTE-datetime] string.  The underlying
#  implementation is threrefore a blessed scalar, with the formats
#  distinguished by the presence or absence of a capital letter "T".

=head1 DESCRIPTION

C<WARC::Date> objects encapsulate the details of the required format for
timestamps in WARC headers.

These objects have overloaded string and number conversions.  As a string,
a C<WARC::Date> object produces the [W3C-NOTE-datetime] format, while
conversion to a number yields an epoch timestamp.

=head2 Methods

=over

=item $datestamp = WARC::Date-E<gt>now

Construct a C<WARC::Date> object representing the current time.

=cut

sub now { (shift)->from_epoch(time) }

=item $datestamp = WARC::Date-E<gt>from_epoch( $timestamp )

Construct a C<WARC::Date> object representing the time indicated by an
epoch timestamp.

=cut

sub from_epoch {
  my $class = shift;
  my $timestamp = shift;

  croak "alleged epoch timestamp is not a number:  $timestamp"
    unless $timestamp =~ m/^([0123456789]+)$/;

  # reconstruct value to ensure object is not tainted
  my $ob = 0 + "$1";
  bless \ $ob, $class;
}

=item $datestamp = WARC::Date-E<gt>from_string( $string )

Construct a C<WARC::Date> object representing the time indicated by a
string in the same format returned by the C<as_string> method.

=cut

sub from_string {
  my $class = shift;
  my $timestamp = shift;

  croak "input contains invalid character:  $timestamp"
    unless $timestamp =~ m/^[-T:Z0123456789]+$/;
  croak "input not in required format:  $timestamp"
    unless $timestamp =~ m/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/;
  croak "input not valid as timestamp:  $timestamp"
    unless ($2 <= 12 && $3 < 32 && $4 < 24 && $5 < 60 && $6 <= 60);

  # reconstruct string to ensure object is not tainted
  bless \ "$1-$2-$3T$4:$5:$6Z", $class;
}

=item $datestamp-E<gt>as_epoch

Return the represented time as an epoch timestamp.

=cut

sub as_epoch {
  my $self = shift;

  if ($$self =~ m/T/) {
    # convert string to epoch time
    $$self =~ m/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/;
    return timegm($6, $5, $4, $3, $2 - 1, $1);	# adjust month:  1..12 -> 0..11
  } else {
    return $$self;
  }
}

=item $datestamp-E<gt>as_string

Return a string in the format specified by [W3C-NOTE-datetime] restricted
to 14 digits and UTC time zone, which is
"I<YYYY>-I<MM>-I<DD>B<T>I<hh>:I<mm>:I<ss>B<Z>".

=cut

sub as_string {
  my $self = shift;

  if ($$self =~ m/T/) {
    return $$self;
  } else {
    # convert epoch time to string
    my ($sec, $min, $hour, $mdy, $mon, $year_o, $wdy, $ydy) = gmtime $$self;
    my $year = $year_o + 1900; my $month = $mon + 1;
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ',
		   $year, $month, $mdy, $hour, $min, $sec);
  }
}

=back

=cut

1;
__END__

=head1 CAVEATS

Conversion to epoch time is limited by the range of C<Time::Local>.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<HTTP::Date>, L<Time::Local>

[W3C-NOTE-datetime] "Date and Time Formats"
L<http://www.w3.org/TR/NOTE-datetime>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
