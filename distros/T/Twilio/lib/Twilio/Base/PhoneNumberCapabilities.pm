package Twilio::Base::PhoneNumberCapabilities;

use 5.016;
use warnings;

our $VERSION = '2.001';

my @CAPABILITIES = qw(fax mms sms voice);

sub capabilities {
  return @CAPABILITIES;
}

sub new {
  my ($class, $capabilities) = @_;

  # Available numbers send MMS and SMS in upper case, and the numbers you own send them in
  # lower case.
  my %lower_case = map { lc $_ => $capabilities->{$_} } keys %{$capabilities};
  return bless { map { $_ => $lower_case{$_} ? 1 : 0 } @CAPABILITIES }, $class;
}

sub fax   { return $_[0]{fax} }
sub mms   { return $_[0]{mms} }
sub sms   { return $_[0]{sms} }
sub voice { return $_[0]{voice} }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Base::PhoneNumberCapabilities - What a phone number can do

=head1 SYNOPSIS

  say 'It can send SMS' if $number->capabilities->sms;

=head1 DESCRIPTION

The value of the C<capabilities> field of a phone number.

=head1 METHODS

=head2 new

  my $capabilities = Twilio::Base::PhoneNumberCapabilities->new(\%capabilities);

Takes the hash reference from Twilio, whatever the case of its keys.

=head2 fax

=head2 mms

=head2 sms

=head2 voice

Return 1 when the number has the capability, and 0 when it does not or when
Twilio did not say.

=head2 capabilities

  my @names = Twilio::Base::PhoneNumberCapabilities->capabilities;

Returns the names of the capabilities.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
