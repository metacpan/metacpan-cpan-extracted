use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Manifest;
use base qw(
    WebService::Shippo::Item
    WebService::Shippo::Create
    WebService::Shippo::Fetch
);

sub api_resource () { 'manifests' }

sub collection_class () { 'WebService::Shippo::Manifests' }

sub item_class () { __PACKAGE__ }

BEGIN {
    no warnings 'once';
    *Shippo::Manifest:: = *WebService::Shippo::Manifest::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::CarrierAccount - Manifest class

=head1 VERSION

version 0.0.21

=head1 DESCRIPTION

Manifests are close-outs of shipping labels of a certain day. Some carriers
require manifests to properly process the shipments.

The following carriers require manifests:

=over 2

=item * DHL Express purchased through Shippo

If you use Shippo's DHL Express rates, you need to manifest ("close-out")
your shipments each day before submitting them to the carrier. If you don't
close-out a shipment, it might not be processed at all by DHL Express.

=item * USPS scan form

The USPS allows you to create "scan forms", which also is a Manifest. By
creating scan forms, the USPS doesn't need to scan each of your packages
individually and all tracking codes are updated immediately.

=item * Canada Post Contract customers

Contract customers that generally ship more than 50 shipments a day will
need to create manifests to transmit the shipments for billing, for a
given day. Contract customers that ship less than 50 daily can generally
skip the manifest requirement, but are encouraged to verify with Canada
Post. If a contract customer doesn't close out a shipment day by creating
a manifest, Canada Post may bill for & transmit the shipments on customer's
behalf.

=back

I<Note: You can't refund shipments after they have been closed-out.>

=head1 API DOCUMENTATION

For more information about Manifests, consult the Shippo API documentation:

=over 2

=item * L<https://goshippo.com/docs/#manifests>

=back

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/WebService-Shippo>

=item * L<https://github.com/cpanic/WebService-Shippo/wiki>

=back

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Iain Campbell.

You may distribute this software under the terms of either the GNU General
Public License or the Artistic License, as specified in the Perl README
file.

=cut
