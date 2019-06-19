package WebService::MinFraud::Model::Insights;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use Types::Standard qw( HashRef InstanceOf );
use WebService::MinFraud::Record::BillingAddress;
use WebService::MinFraud::Record::Country;
use WebService::MinFraud::Record::CreditCard;
use WebService::MinFraud::Record::Device;
use WebService::MinFraud::Record::Disposition;
use WebService::MinFraud::Record::Email;
use WebService::MinFraud::Record::IPAddress;
use WebService::MinFraud::Record::Issuer;
use WebService::MinFraud::Record::Location;
use WebService::MinFraud::Record::ShippingAddress;
use WebService::MinFraud::Record::Warning;

with 'WebService::MinFraud::Role::Model',
    'WebService::MinFraud::Role::HasLocales',
    'WebService::MinFraud::Role::HasCommonAttributes';

## no critic (ProhibitUnusedPrivateSubroutines)
sub _has { has(@_) }
## use critic

__PACKAGE__->_define_model_attributes(
    billing_address  => 'BillingAddress',
    credit_card      => 'CreditCard',
    device           => 'Device',
    disposition      => 'Disposition',
    email            => 'Email',
    ip_address       => 'IPAddress',
    shipping_address => 'ShippingAddress',
);

1;

# ABSTRACT: Model class for minFraud Insights

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Model::Insights - Model class for minFraud Insights

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );

  my $request = { device => { ip_address => '24.24.24.24' } };
  my $insights = $client->insights($request);

  my $shipping_address = $insights->shipping_address;
  say $shipping_address->is_high_risk;

  my $ip_address = $insights->ip_address;
  my $postal     = $ip_address->postal;
  say $postal->code;

  say $insights->device->id;

=head1 DESCRIPTION

This class provides a model for the data returned by the minFraud Insights web
service.

The Insights model class includes more data than the Score model class. See
the L<API
documentation|https://dev.maxmind.com/minfraud/>
for more details.

=head1 METHODS

This model class provides the following methods:

=head2 billing_address

Returns a L<WebService::MinFraud::Record::BillingAddress> object representing
billing data for the transaction.

=head2 credit_card

Returns a L<WebService::MinFraud::Record::CreditCard> object representing
credit card data for the transaction.

=head2 device

Returns a L<WebService::MinFraud::Record::Device> object representing the
device that MaxMind believes is associated with the IP address passed in the
request.

=head2 disposition

Returns a L<WebService::MinFraud::Record::Disposition> object representing the
disposition set for the transaction using custom rules.

=head2 funds_remaining

Returns the  I<approximate> US dollar value of the funds remaining on your
account. The fund calculation is near realtime so it may not be exact.

=head2 id

Returns a UUID that identifies the minFraud request. Please use this UUID in
bug reports or support requests to MaxMind so that we can easily identify a
particular request.

=head2 ip_address

Returns a L<WebService::MinFraud::Record::IPAddress> object representing IP
address data for the transaction. This object has the following methods:

=over 4

=item * C<< city >>

=item * C<< continent >>

=item * C<< country >>

=item * C<< most_specific_subdivision >>

=item * C<< postal >>

=item * C<< registered_country >>

=item * C<< represented_country >>

=item * C<< risk >>

=item * C<< subdivisions >>

=item * C<< traits >>

=back

For details, please refer to L<WebService::MinFraud::Record::IPAddress/METHODS>.

=head2 queries_remaining

Returns the I<approximate> number of queries remaining for this service before
your account runs out of funds. The query counts are near realtime so they may
not be exact.

=head2 risk_score

Returns the risk score which is a number between 0.01 and 99. A higher score
indicates a higher risk of fraud.

=head2 shipping_address

Returns a L<WebService::MinFraud::Record::ShippingAddress> object representing
shipping data for the transaction.

=head2 warnings

Returns an ArrayRef of L<WebService::MinFraud::Record::Warning> objects. It is
B<highly recommended that you check this array> for issues when integrating the
web service.

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_funds_remaining

=head2 has_id

=head2 has_queries_remaining

=head2 has_risk_score

=head2 has_warnings

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
