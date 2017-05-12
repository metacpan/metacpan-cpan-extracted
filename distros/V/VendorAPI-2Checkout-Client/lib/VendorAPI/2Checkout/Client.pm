package VendorAPI::2Checkout::Client;

use 5.006;
use strict;
use warnings;

use LWP::UserAgent;
use Params::Validate qw(:all);
use Carp qw(confess);
use URI;
use URI::QueryParam;
require UNIVERSAL::require;

=head1 NAME

VendorAPI::2Checkout::Client - an OO interface to the 2Checkout.com Vendor API

=head1 VERSION

Version 0.1502

=cut

use vars qw( $VERSION @ISA );
$VERSION = '0.1502';

sub _base_uri { 'https://www.2checkout.com/api' };
sub _realm    { '2CO API' };
sub _netloc   { 'www.2checkout.com:443' };

sub mime_type {
  my $self = shift;
  my $format = shift;
  my %mime_types = ( XML => 'application/xml', JSON => 'application/json', );
  return $mime_types{$format} || $mime_types{JSON};
}

=head1 SYNOPSIS

    use VendorAPI::2Checkout::Client;

    my $tco = VendorAPI::2Checkout::Client->new($username, $password, $format);
    $response = $tco->list_sales();

    $response = $tco->detail_sale(sale_id => 1234554323);

    $response = $tco->list_coupons();

    $response = $tco->detail_coupon(coupon_code => 'COUPON42');

    $response = $tco->list_payments();

    $response = $tco->list_products();

    $response = $tco->list_options();

    ...

=head1 DESCRIPTION

This module is an OO interface to the 2Checkout.com Vendor API.

This modules uses Params::Validate which likes to die() when the parameters do not pass validation, so
wrap your code in evals, etc.

Presently implements list_sales(), detail_sale(), list_coupons(), and detail_coupon(), list_payments(),
list_options(), list_products().

Return data is in XML or JSON.

Please refer to L<2Checkout's Back Office Admin API Documentation|http://www.2checkout.com/documentation/api>
for input parameters and expexted return values.

=head1 CONSTRUCTORS AND METHODS

=over 4

=item $c = VendorAPI::2Checkout::Client->new($username, $password, $format, VAPI_MOOSE)
=item $c = VendorAPI::2Checkout::Client->new($username, $password, $format, VAPI_NO_MOOSE)
=item $c = VendorAPI::2Checkout::Client->new($username, $password, $format) # no moose

Contructs a new C<VendorAPI::2Checkout::Client> object to comminuncate with the 2Checkout Back Office Admin API.
You must pass your Vendor API username and password or the constructor will return undef;

=cut

sub VAPI_MOOSE { 1; }
sub VAPI_NO_MOOSE { 0; }

sub get_client {
   my $class     = shift;
   my $username  = shift;
   my $password  = shift;
   my $format    = shift;
   my $use_moose = shift;

   unless ( $username && $password) {
      return undef;
   }

   unless ( defined $format && $format =~ qr/^(?:XML|JSON)$/) {
      return undef;
   }

   $class = 'VendorAPI::2Checkout::Client::';
   if (defined $use_moose && $use_moose == VAPI_MOOSE) {
      $class .= 'Moose';
   }
   else {
      $class .= 'NoMoose';
   }

   my $return = $class->require;
   unless ($return) {
      die "require issue: $@";
   }
   return $class->new($username, $password, $format);
}


=head1 AUTHOR

Len Jaffe, C<< <lenjaffe at jaffesystems.com> >>

=head1 GITHUB

The source code is available at
L<Github|https://github.com/vampirechicken/VendorAPI--2Checkout--Client>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vendorapi-2checkout-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VendorAPI-2Checkout-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VendorAPI::2Checkout::Client

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VendorAPI-2Checkout-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VendorAPI-2Checkout-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VendorAPI-2Checkout-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/VendorAPI-2Checkout-Client/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Len Jaffe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of VendorAPI::2Checkout::Client
