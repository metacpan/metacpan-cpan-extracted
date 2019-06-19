package WebService::MinFraud::Record::CreditCard;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use WebService::MinFraud::Record::Issuer;
use WebService::MinFraud::Types
    qw( Bool BoolCoercion IssuerObject IssuerObjectCoercion Str );

has brand => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has country => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has is_issued_in_billing_address_country => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    coerce  => BoolCoercion,
);

has is_prepaid => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    coerce  => BoolCoercion,
);

has is_virtual => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    coerce  => BoolCoercion,
);

has issuer => (
    is        => 'ro',
    isa       => IssuerObject,
    coerce    => IssuerObjectCoercion,
    predicate => 1,
);

has type => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

1;

# ABSTRACT: Contains data for the credit card record associated with a transaction

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::CreditCard - Contains data for the credit card record associated with a transaction

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );
  my $request     = { device => { ip_address => '24.24.24.24' } };
  my $insights    = $client->insights($request);
  my $credit_card = $insights->credit_card;
  say $credit_card->is_prepaid;
  say $credit_card->issuer->name;

=head1 DESCRIPTION

This class contains the credit card data associated with a transaction.

This record is returned by the Insights web service.

=head1 METHODS

This class provides the following methods:

=head2 issuer

Returns the L<WebService::MinFraud::Record::Issuer> object for the credit card.

=head2 brand

Returns the brand of the credit card, e.g. Visa, MasterCard, American Express etc.

=head2 country

Returns the two letter L<ISO 3166-1 alpha 2 country
code|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2> associated with the
location of the majority of customers using this credit card as determined by
their billing address. In cases where the location of customers is highly
mixed, this defaults to the country of the bank issuing the card.

=head2 is_issued_in_billing_address_country

Returns a boolean indicating whether the country of the billing address
matches the country of the majority of customers using this credit card. In
cases where the location of customers is highly mixed, the match is to the
country of the bank issuing the card.

=head2 is_prepaid

Returns a boolean indicating whether the credit card is prepaid.

=head2 is_virtual

Returns a boolean indicating whether the credit card is virtual.

=head2 type

Returns the type of the card if known: charge, credit or debit

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_issuer

=head2 has_country

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
