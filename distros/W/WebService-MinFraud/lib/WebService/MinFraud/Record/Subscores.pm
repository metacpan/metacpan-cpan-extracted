package WebService::MinFraud::Record::Subscores;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use WebService::MinFraud::Types qw( Num );

has [
    qw(
        avs_result
        billing_address
        billing_address_distance_to_ip_location
        browser
        chargeback
        country
        country_mismatch
        cvv_result
        email_address
        email_domain
        email_tenure
        ip_tenure
        issuer_id_number
        order_amount
        phone_number
        shipping_address_distance_to_ip_location
        time_of_day
        )
] => (
    is  => 'ro',
    isa => Num,
);

1;

# ABSTRACT: Contains minFraud Factors subscores

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::Subscores - Contains minFraud Factors subscores

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );
  my $request   = { device => { ip_address => '24.24.24.24' } };
  my $factors   = $client->factors($request);
  my $subscores = $factors->subscores;
  say $subscores->ip_tenure;

=head1 DESCRIPTION

This class contains subscores for many of the individual components that are
used to calculate the overall risk score.

=head1 METHODS

This class provides the following methods:

=head2 avs_result

The risk associated with the AVS result. If present, this is a value in the
range 0.01 to 99.

=head2 billing_address

The risk associated with the billing address. If present, this is a value in
the range 0.01 to 99.

=head2 billing_address_distance_to_ip_location

The risk associated with the distance between the billing address and the
location for the given IP address. If present, this is a value in the range
0.01 to 99.

=head2 browser

The risk associated with the browser attributes such as the User-Agent and
Accept-Language. If present, this is a value in the range 0.01 to 99.

=head2 chargeback

Individualized risk of chargeback for the given IP address on your account and
shop ID.This is only available to users sending chargeback data to MaxMind. If
present, this is a value in the range 0.01 to 99.

=head2 country

The risk associated with the country the transaction originated from. If
present, this is a value in the range 0.01 to 99.

=head2 country_mismatch

The risk associated with the combination of IP country, card issuer country,
billing country, and shipping country. If present, this is a value in the range
0.01 to 99.

=head2 cvv_result

The risk associated with the CVV result. If present, this is a value in the
range 0.01 to 99.

=head2 email_address

The risk associated with the particular email address. If present, this is a
value in the range 0.01 to 99.

=head2 email_domain

The general risk associated with the email domain. If present, this is a value
in the range 0.01 to 99.

=head2 email_tenure

The risk associated with the issuer ID number on the email domain. If present,
this is a value in the range 0.01 to 99.

=head2 ip_tenure

The risk associated with the issuer ID number on the IP address. If present,
this is a value in the range 0.01 to 99.

=head2 issuer_id_number

The risk associated with the particular issuer ID number (IIN) given the
billing location and the history of usage of the IIN on your account and shop
ID. If present, this is a value in the range 0.01 to 99.

=head2 order_amount

The risk associated with the particular order amount for your account and shop
ID. If present, this is a value in the range 0.01 to 99.

=head2 phone_number

The risk associated with the particular phone number. If present, this is a
value in the range 0.01 to 99.

=head2 shipping_address_distance_to_ip_location

The risk associated with the distance between the shipping address and the
location for the given IP address. If present, this is a value in the range
0.01 to 99.

=head2 time_of_day

The risk associated with the local time of day of the transaction in the IP
address location. If present, this is a value in the range 0.01 to 99.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
