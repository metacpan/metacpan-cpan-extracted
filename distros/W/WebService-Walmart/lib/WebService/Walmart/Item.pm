package WebService::Walmart::Item;
use strict;
use warnings;
$WebService::Walmart::Item::VERSION = '0.01';
use Moose;
use namespace::autoclean;

# from https://developer.walmartlabs.com/docs/read/Item_Field_Description
has api_version             => ( is => 'ro', default => 20);
has itemId                  => ( is => 'ro');
has parentItemId            => ( is => 'ro');
has name                    => ( is => 'ro');
has msrp                    => ( is => 'ro');
has salePrice               => ( is => 'ro');
has upc                     => ( is => 'ro');
has categoryPath            => ( is => 'ro');
has categoryNode            => ( is => 'ro');
has shortDescription        => ( is => 'ro');
has longDescription         => ( is => 'ro');
has brandName               => ( is => 'ro');
has thumbnailImage          => ( is => 'ro');
has mediumImage             => ( is => 'ro');
has largeImage              => ( is => 'ro');
has productTrackingUrl      => ( is => 'ro');
has ninetySevenCentShipping => ( is => 'ro');
has standardShipRate        => ( is => 'ro');
has twoThreeDayShippingRate => (is => 'ro');
has overnightShippingRate   => ( is => 'ro');
has size                    => ( is => 'ro');
has color                   => ( is => 'ro');
has marketplace             => ( is => 'ro');
has sellerinfo              => ( is => 'ro');
has shipToStore             => ( is => 'ro');
has freeShipToStore         => ( is => 'ro');
has modelNumber             => ( is => 'ro');
has productUrl              => ( is => 'ro');
has availableOnline         => ( is => 'ro');
has stock                   => ( is => 'ro');
has rollBack                => ( is => 'ro');
has specialBuy              => ( is => 'ro');
has customerRating          => ( is => 'ro');
has customerRatingImage     => ( is => 'ro');
has numReviews              => ( is => 'ro');
has clearance               => ( is => 'ro');
has preOrder                => ( is => 'ro');
has preOrderShipsOn         => ( is => 'ro');

__PACKAGE__->meta->make_immutable();
1;

=pod


=head1 SYNOPSIS

This module represents the metadata associated with the item. It is based upon
https://developer.walmartlabs.com/docs/read/Item_Field_Description

You probably shouldn't be calling this directly

=cut