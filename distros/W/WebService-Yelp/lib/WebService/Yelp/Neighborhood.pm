package WebService::Yelp::Neighborhood;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_ro_accessors(qw/city state name url/);

=head1 NAME

WebService::Yelp::Neighborhood - Yelp.com API Neighborhood Class

=head1 SYNOPSIS

 use strict;
 use WebService::Yelp;

 my $yelp = WebService::Yelp->new({ywsid => 'XXXXXXXXXXXX'});

 my $biz_res = $yelp->search_review_hood({
                                             term => 'cream puffs',
                                             location => 'San Francisco',
                                             };
 for my $b (@{$biz_res->businesses()}) {
   for my $n (@{$b->neighborhood()}) {
     print $b->name . " is in the " . $n->name . " neighborhood\n";
   }
 }

 # or 

 my $hood_res = $yelp->search_neighborhood_location({
                                                     location => 
                                        '1512 Shattuck Avenue, Berkeley, CA',
                                                    });

 for my $n (@{$hood_res->neighborhoods}) {
   print "the " . $n->name . " neighborhood in " . $b->city . "\n";
 }

=head1 DESCRIPTION

Yelp's neighborhoods define specific area's of a city. You can see the
entire list here:

  http://www.yelp.com/developers/documentation/neighborhood_list

Note that business searches currently only return the name and URL
portions within a particular business. The neighborhood search
functions also return the city and state fields.

=head1 METHODS (Read Only)

=head2 name

The name of the neighborhood.

=head2 city 

The neighborhood's city.

=head2 state

The neighborhood's state.

=head2 url 

The url linking to Yelp's main page for this neighborhood.

=cut




1;
