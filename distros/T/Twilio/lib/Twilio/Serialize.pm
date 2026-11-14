package Twilio::Serialize;

use 5.016;
use warnings;

use Carp         qw(croak);
use POSIX        ();
use Scalar::Util qw(blessed);

use Twilio::Json;

our $VERSION = '2.002';

sub boolean_to_string {
  my ($value) = @_;
  return $value if !defined $value;

  # The text "false" is true to Perl, and it is what a caller copying from a Twilio example
  # is likely to write.
  return $value if $value eq 'true' || $value eq 'false';
  return $value ? 'true' : 'false';
}

sub iso8601_date_time {
  my ($value) = @_;

  return _utc_format($value, '%Y-%m-%dT%H:%M:%SZ');
}

sub iso8601_date {
  my ($value) = @_;
  return _utc_format($value, '%Y-%m-%d');
}

# Time::Piece and DateTime both have epoch, so neither has to be a dependency here.
sub _utc_format {
  my ($value, $format) = @_;
  if (blessed($value) && $value->can('epoch')) {
    return POSIX::strftime($format, gmtime $value->epoch);
  }
  return $value;
}

sub json_object {
  my ($value) = @_;

  # An object could encode to anything, so only plain data is turned into JSON here.
  my $type = ref $value;
  return $type eq 'HASH' || $type eq 'ARRAY' ? Twilio::Json::encode($value) : $value;
}

my %JSON_RULE = (
  boolean           => \&_json_boolean,
  iso8601_date      => \&iso8601_date,
  iso8601_date_time => \&iso8601_date_time,
);

sub json_body {
  my ($body, $rules) = @_;
  return {}                                    if !defined $body;
  croak 'A JSON body must be a hash reference' if ref $body ne 'HASH';

  my %sent;
  for my $name (keys %{$body}) {
    my $rule = $JSON_RULE{ ($rules // {})->{$name} // q{} };
    $sent{$name} = $rule ? $rule->($body->{$name}) : _json_value($body->{$name});
  }
  return \%sent;
}

# A copy, so that the caller's data stays as it was, with every date object written as text.
sub _json_value {
  my ($value) = @_;

  my $type = ref $value;
  return { map { $_ => _json_value($value->{$_}) } keys %{$value} } if $type eq 'HASH';
  return [map { _json_value($_) } @{$value}]                        if $type eq 'ARRAY';
  return iso8601_date_time($value) if blessed($value) && $value->can('epoch');
  return $value;
}

# JSON has booleans of its own, and Twilio does not take 1 or "true" for them.
sub _json_boolean {
  my ($value) = @_;
  return $value if !defined $value || ref $value;
  return \0     if $value eq 'false';
  return $value ? \1 : \0;
}

sub map_values {
  my ($values, $writer) = @_;
  return $values if ref $values ne 'ARRAY';
  return [map { $writer->($_) } @{$values}];
}

sub prefixed_collapsible_map {
  my ($map, $prefix) = @_;
  return {}                                                  if !defined $map;
  croak "A value sent as $prefix.* must be a hash reference" if ref $map ne 'HASH';

  my %flat;
  _flatten(\%flat, $prefix, $map);
  return \%flat;
}

# Arrays are walked by index, as twilio-php walks PHP's arrays, so no reference is ever sent as
# its address.
sub _flatten {
  my ($flat, $name, $value) = @_;

  my $type = ref $value;
  if ($type eq 'HASH') {
    _flatten($flat, "$name.$_", $value->{$_}) for sort keys %{$value};
  }
  elsif ($type eq 'ARRAY') {
    _flatten($flat, "$name.$_", $value->[$_]) for 0 .. $#{$value};
  }
  else {
    $flat->{$name} = $value;
  }
  return;
}

sub path_segment {
  my ($value) = @_;

  # An empty part would point the request at another resource, such as /Accounts//Messages.json
  # for a client with OAuth and no account SID.
  if (!defined $value || !length $value) {
    croak 'A URL needs an id that is missing. For account resources with a credential provider, '
      . q{set the client's account_sid};
  }
  my $encoded = "$value";
  utf8::encode($encoded) if utf8::is_utf8($encoded);
  $encoded =~ s/([^A-Za-z0-9._~-])/sprintf('%%%02X', ord $1)/ge;
  return $encoded;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Serialize - Convert Perl values to what the Twilio API expects

=head1 SYNOPSIS

  my $flag = Twilio::Serialize::boolean_to_string(1);    # 'true'

  my $now  = Time::Piece->gmtime;
  my $date = Twilio::Serialize::iso8601_date_time($now);

=head1 DESCRIPTION

Functions that generated resources use to build their requests. None of them are
exported.

=head1 FUNCTIONS

=head2 boolean_to_string

Returns C<true> or C<false> for a Perl boolean. The strings C<true> and C<false>,
and C<undef>, are returned as they are.

=head2 iso8601_date_time

Returns any object with an C<epoch> method, such as L<Time::Piece> or C<DateTime>,
as a UTC date in ISO 8601 format. Anything else is returned as it is, so a date
can also be given as a string.

Inside a hash, C<< Time::Piece->gmtime >> returns a list of date parts instead of
an object, and that breaks the options. Keep the date in a variable first, or
use C<scalar>:

  my $send_at = gmtime(time + 3600);    # with "use Time::Piece"

  $client->messages->create($to, { schedule_type => 'fixed', send_at => $send_at });

=head2 iso8601_date

Returns any object with an C<epoch> method as a UTC date in the form
C<2026-11-06>, for values that have no time. Anything else is returned as it is.

=head2 json_object

Returns a hash or array reference as JSON. Anything else is returned as it is, so
a value can also be given as text that is already JSON.

=head2 json_body

  my $sent = Twilio::Serialize::json_body($body, { sendAt => 'iso8601_date_time' });

Returns a copy of a JSON body, ready to be encoded. The rules name the top-level
fields that need a conversion: C<iso8601_date>, C<iso8601_date_time>, or C<boolean>,
which turns a Perl boolean, or the text C<true> or C<false>, into a JSON boolean.
Below the top level, any object with an C<epoch> method is written as an ISO 8601
date and time, and everything else is sent as it is, so use C<\1> and C<\0> for
booleans there. C<undef> is an empty body, and anything else that is not a hash
reference dies.

=head2 map_values

  my $sent = Twilio::Serialize::map_values($types, \&Twilio::Serialize::json_object);

Returns a new array reference with the function applied to each element. Anything
that is not an array reference is returned as it is.

=head2 prefixed_collapsible_map

  my $params = Twilio::Serialize::prefixed_collapsible_map(
    { payfone_tcpa_compliance => { RightPartyContactedDate => '20160101' } }, 'AddOns');

  # { 'AddOns.payfone_tcpa_compliance.RightPartyContactedDate' => '20160101' }

Returns a hash reference with one entry for each value in a nested hash, named by
the prefix and the keys that lead to it, joined with dots. Arrays inside are
walked by index, as twilio-php does. C<undef> returns an empty hash, and anything
else that is not a hash reference dies.

=head2 path_segment

Returns a value encoded for use as one part of a URL path. It croaks when the
value is undefined or empty.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
