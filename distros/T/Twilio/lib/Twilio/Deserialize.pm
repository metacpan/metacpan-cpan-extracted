package Twilio::Deserialize;

use 5.016;
use warnings;

use Time::Local qw(timegm);
use Time::Piece ();

use Twilio::Base::PhoneNumberCapabilities;

our $VERSION = '2.002';

my $SECONDS_PER_MINUTE = 60;
my $MINUTES_PER_HOUR   = 60;

my %MONTH_NUMBER;
@MONTH_NUMBER{qw(jan feb mar apr may jun jul aug sep oct nov dec)} = (0 .. 11);

my $OFFSET    = qr/[+-]\d\d:?\d\d/;
my $TIME      = qr/(\d\d):(\d\d):(\d\d)/;
my $ISO_DATE  = qr/(\d{4})-(\d\d)-(\d\d)/;
my $RFC_DATE  = qr/(\d{1,2})\s+([[:alpha:]]{3})\s+(\d{4})/;
my $RFC_DAY   = qr/[[:alpha:]]{3},\s*/;
my $ZONE_NAME = qr/[[:alpha:]]+/;

my $ISO8601 = qr/\A$ISO_DATE(?:[T\x20]$TIME(?:[.]\d+)?(Z|$OFFSET)?)?\z/;
my $RFC2822 = qr/\A$RFC_DAY?$RFC_DATE\s+$TIME\s*($ZONE_NAME|$OFFSET)?\z/;

sub date_time {
  my ($value) = @_;
  return $value if !$value;

  # timegm dies on values like a 13th month, which is the same to callers as a bad format.
  my $epoch = eval { _parse_epoch($value) };

  # In list context, Time::Piece would return the date parts instead of an object.
  return defined $epoch ? scalar Time::Piece->gmtime($epoch) : $value;
}

sub phone_number_capabilities {
  my ($value) = @_;
  return $value if ref $value ne 'HASH';

  my %is_capability = map { $_ => 1 } Twilio::Base::PhoneNumberCapabilities->capabilities;
  return $value if !grep { $is_capability{ lc $_ } } keys %{$value};
  return Twilio::Base::PhoneNumberCapabilities->new($value);
}

# Not strptime, because month names there follow the locale, and %z is ignored by the
# Time::Piece that comes with older Perls.
sub _parse_epoch {
  my ($value) = @_;

  if (my ($year, $month, $day, $hour, $minute, $sec, $zone) = $value =~ $ISO8601) {
    return _epoch([$sec, $minute, $hour, $day, $month - 1, $year], $zone);
  }

  if (my ($day, $month, $year, $hour, $minute, $sec, $zone) = $value =~ $RFC2822) {
    my $month_number = $MONTH_NUMBER{ lc $month };
    return if !defined $month_number;
    return _epoch([$sec, $minute, $hour, $day, $month_number, $year], $zone);
  }

  return;
}

sub _epoch {
  my ($time_fields, $zone) = @_;
  my @fields = map { $_ // 0 } @{$time_fields};
  return timegm(@fields) - _offset_seconds($zone);
}

sub _offset_seconds {
  my ($zone) = @_;

  my ($sign, $hours, $minutes) = ($zone // q{}) =~ /\A([+-])(\d\d):?(\d\d)\z/;
  return 0 if !defined $sign;

  my $seconds = ($hours * $MINUTES_PER_HOUR + $minutes) * $SECONDS_PER_MINUTE;
  return $sign eq q{-} ? -$seconds : $seconds;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Deserialize - Convert API values to Perl values

=head1 SYNOPSIS

  my $date = Twilio::Deserialize::date_time('Thu, 30 Jul 2015 20:12:31 +0000');

  say $date->ymd;

=head1 DESCRIPTION

Functions that generated resources use to read their responses. None of them are
exported.

=head1 FUNCTIONS

=head2 date_time

Returns a L<Time::Piece> object in UTC for a date in any format Twilio uses: RFC
2822, as in C<Thu, 30 Jul 2015 20:12:31 +0000>, ISO 8601, as in
C<2015-07-30T20:12:31Z>, or C<2015-07-30>.

A value that cannot be read is returned as it is, so that an unexpected format
never breaks a response. This is why the result should be checked with
C<ref> before relying on it, if the value does not come from a documented field.

To work with a C<DateTime> object instead:

  my $date_time = DateTime->from_epoch(epoch => $date->epoch);

=head2 phone_number_capabilities

Returns a L<Twilio::Base::PhoneNumberCapabilities> object. A value that is not a
hash reference holding at least one capability is returned as it is.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
