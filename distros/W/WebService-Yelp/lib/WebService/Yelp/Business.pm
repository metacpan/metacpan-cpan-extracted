package WebService::Yelp::Business;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_ro_accessors(qw/distance neighborhoods state avg_rating city
                             review_count latitude url id longitude 
                             rating_img_url_small reviews name categories
                             rating_img_url phone photo_url address1 address2
                             nearby_url zip photo_url_small/);

=head1 NAME

WebService::Yelp::Business - Yelp.com API Business Class (heh, get it?)

=head1 SYNOPSIS

 use strict;
 use WebService::Yelp;

 my $yelp = WebService::Yelp->new({ywsid => 'XXXXXXXXXXXX'});

 my $biz_res = $yelp->search_review_hood({
                                             term => 'cream puffs',
                                             location => 'San Francisco',
                                             };
 for my $b (@{$biz_res->businesses()}) {

   print $b->name " has " . $b->review_count . " review(s)\n";
 }

=head1 DESCRIPTION

This class represents a business returned from a search.


=head1 METHODS (Read Only)

=head2 id

The business id.

=head2 latitude

The latitude of the business location.

=head2 longtitude

The longitude of the business location.

=head2 url

The URL for the business profile.

=head2 avg_rating

The business average rating.

=head2 review_count

The number of reviews for this business.

=head2 distance

The distance from the center of the city.

=head2 name

The business name.

=head2 address1

The first line of the business address.

=head2 address2

The second line of the business address.

=head2 city

The business city.

=head2 state

The business state.

=head2 zip

The business zip code.

=head2 phone

The business phone number.

=head2 photo_url

The url to a thumbnail pic of this business. (100x100 pixels)

=head2 photo_url_small

The url to a smaller thumbnail pic of this business. (40x40 pixels)

=head2 rating_img_url

The url to the star image for the business rating.

=head2 nearby_url

The url to search for other businesses nearby.

=head2 reviews

Returns an array reference of (up to) 3 B<WebService::Yelp::Review> objects.

=head2 categories

Returns an array reference of B<WebService::Yelp::Category> objects.

=head2 neighborhoods

Returns an array reference of B<WebService::Yelp::Neighborhood> objects.

=cut

1;
