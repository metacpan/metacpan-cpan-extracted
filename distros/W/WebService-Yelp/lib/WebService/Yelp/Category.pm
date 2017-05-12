package WebService::Yelp::Category;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_ro_accessors(qw/search_url name category_filter/);

=head1 NAME 

WebService::Yelp::Category - Yelp.com API Category Class

=head1 SYNOPSIS

use strict;
use WebService::Yelp;

 my $yelp = WebService::Yelp->new({ywsid => 'XXXXXXXXXXXX'});

 my $biz_res = $yelp->search_review_hood({
                                             term => 'cream puffs',
                                             location => 'San Francisco',
                                             };
 for my $b (@{$biz_res->businesses()}) {
   for my $c (@{$b->categories()}) {
     my $href = qq[<a href="] . $c->search_url . qq[">] . 
       $c->name . qq[<br>\n];
   }
 }

=head1 DESCRIPTION

A business has one or more categories associated with it. You can see
 Yelp's complete list at:

 http://www.yelp.com/developers/documentation/category_list

=head1 METHODS (Read Only)

=head2 name

Category display name.

=head2 search_url

Category search URL for yelp.com for the current location.

=head2 category_filter

Category filter name.

=cut

1;
