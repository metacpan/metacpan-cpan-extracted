package WebService::Yelp::Review;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_ro_accessors(qw/user_photo_url_small rating_img_url_small
                             user_url rating_img_url user_name rating url
                             text_excerpt user_photo_url id/);


=head1 NAME

WebService::Yelp::Neighborhood - Yelp.com API Review Class

=head1 SYNOPSIS

 use strict;
 use WebService::Yelp;

 my $yelp = WebService::Yelp->new({ywsid => 'XXXXXXXXXXXX'});

 my $biz_res = $yelp->search_review_hood({
                                             term => 'cream puffs',
                                             location => 'San Francisco',
                                             };
 for my $b (@{$biz_res->businesses()}) {
   for my $r (@{$b->reviews()}) {
     print $b->name . " is rated " . $r->rating . " by user " 
       $r->user_name . "\n";
   }
 }

=head1 DESCRIPTION

This class represents a single review of a business on Yelp.

=head1 METHODS (Read Only)

=head2 id

This review's id.

=head2 rating

The numeric rating for this review.

=head2 rating_img_url

The URL of the stars for this rating. (84x17 pixels)

=head2 rating_img_url_small

The URL of the stars for this rating (only smaller). (50x10 pixels)

=head2 url

The url of this review.

=head2 text_excerpt

A text excerpt of the review.

=head2 user_name

The user name of the reviewer.

=head2 user_url

The user's profile URL.

=head2 user_photo_url

The user's photo URL. (100x100 pixels)

=head2 user_photo_url_small

The user's small photo URL. (40x40 pixels)

=cut

1;
