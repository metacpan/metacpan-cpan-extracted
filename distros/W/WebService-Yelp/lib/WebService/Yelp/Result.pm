package WebService::Yelp::Result;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_ro_accessors(qw/businesses neighborhoods message/);

=head1 NAME

WebService::Yelp::Result - Yelp.cpm API Search Result Container

=head1 SYNOPSIS

 use strict;
 use WebService::Yelp;

 my $yelp = WebService::Yelp->new({ywsid => 'XXXXXXXXXXXX'});

 my $biz_res = $yelp->search_review_hood({
                                             term => 'cream puffs',
                                             location => 'San Francisco',
                                             };

 if($biz_res->message->code() == 0) {
   # returns an array ref of businesses
   my $businesses = $biz_res->businesses(); 
   # ...
 }

 my $hood_res = $yelp->search_neigborhood_location({
                                                   location => 'Shattuck Avenue, Berkeley, CA',
                                                  });
 if($hood_res->message->code() == 0) {
   # returns an array ref of neighborhoods
   my $neighborhoods = $hood_res->neighborhoods();
   # ...
 }

=head1 DESCRIPTION

This class simply contains the results of a Review or Neighborhood
search, as well as the result B<WebService::Yelp::Message> class. It
is the return value of all search methods (including the raw call()
method) from B<WebService::Yelp> *if* no other output type was
specified.

If the call was a review search, the businesses method will return an
array reference of B<WebService::Yelp::Business> objects. Likewise, a
neighborhood search returns an array reference of
B<WebService::Yelp::Neighborhood> objects via the neighborhoods
method.

=head1 METHODS (Read Only)

=head2 businesses

Returns an array reference of B<WebService::Yelp::Business> objects.

=head2 neighborhoods

Returns an array reference of B<WebService::Yelp::Neighborhood> objects.

=head2 message

Returns a B<WebService::Yelp::Message> object.


=cut

1;

