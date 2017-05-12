package WebService::Walmart;
# ABSTRACT: Interface to Walmart's open API
use strict;
use warnings;
$WebService::Walmart::VERSION = "0.01";
use Moose;
use Try::Tiny;
use JSON::MaybeXS qw/ decode_json /;
use Data::Dumper;

use WebService::Walmart::Store;
use WebService::Walmart::Item;
use WebService::Walmart::Review;
use WebService::Walmart::Taxonomy;


#use WebService::Walmart::Exception;
with 'WebService::Walmart::Request';

sub BUILD {
    my $self = shift;
}
# Lookup API
sub items {
    my ($self, $args)  = @_;
    
    my $path = "/items/";
    $path .= "$args->{id}?";

    my $response = $self->_get($path);
    
    my $content = $response->{content};
    my $status  = $response->{status};
    
    my $h = decode_json($content);
    #return $h;
    my $item = WebService::Walmart::Item->new($h);
    return $item;
}

# reviews API
sub reviews {
    my ($self, $args)  = @_;
    
    my $path = "/reviews/";
    $path .= "$args->{id}?";

    my $response = $self->_get($path);
    
    my $content = $response->{content};
    my $status  = $response->{status};
    my $h = decode_json($content); 
    my $r = $h->{reviews};
    
    my @reviews;
    foreach my $store_json (@$r) {
        my $store = WebService::Walmart::Review->new($store_json);
        push @reviews, $store;
    }
    return @reviews;
}

# search API
sub search {
    my ($self, $args)  = @_;
    
    my $path = "/search?";
    $path .= "query=$args->{query}?";
    $path .= "&facet=$args->{facet}"                   if ($args->{facet});
    $path .= "&facet.filter=$args->{'facet.filter'}"   if ($args->{'facet.filter'});

    my $response = $self->_get($path);
    
    my $content = $response->{content};
    my $status  = $response->{status};
    
    my $h = decode_json($content);
    
    my $s = $h->{items};
    
    my @searches;
    foreach my $search_json (@$s) {
        my $search = WebService::Walmart::Item->new($search_json);
        push @searches, $search;
    }
    return @searches;
}

# value of the data
sub vod {
    my $self = shift;
    
    my $path = "/vod?";

    my $response = $self->_get($path);
    
    my $content = $response->{content};
    my $status  = $response->{status};
    
    my $h = decode_json($content);
    # return $h;
    my $item = WebService::Walmart::Item->new($h);
    return $item;
}

# taxonomy
sub taxonomy {
    my $self = shift;
    
    my $path = "/taxonomy?";

    my $response = $self->_get($path);
    
    my $content = $response->{content};
    my $status  = $response->{status};
    
    my $h = decode_json($content);
    my $s = $h->{categories};
    my @taxonomy;
    foreach my $taxonomy_json (@$s) {
        my $tax = WebService::Walmart::Taxonomy->new($taxonomy_json);
        push @taxonomy, $tax;
    }
    return @taxonomy;
}

# store locators
sub stores {
    my ($self, $args)  = @_;
    
    my $path = "/stores?";
    $path .= "lat=$args->{lat}"   if ($args->{lat});
    $path .= "lon=$args->{lon}"   if ($args->{lon});
    $path .= "city=$args->{city}" if ($args->{city});
    $path .= "zip=$args->{zip}"   if ($args->{zip});

    my $response = $self->_get($path);
    
    my $content = $response->{content};
    my $status  = $response->{status};
    my $success = $response->{success};
    my $reason  = $response->{reason};
    
    my $h = decode_json($content);
    my @stores;
    foreach my $store_json (@$h) {
        my $store = WebService::Walmart::Store->new($store_json);
        push @stores, $store;
    }
    return @stores;
}

# trending api
sub trends {
    my $self = shift;
    
    my $path = "/trends?";

    my $response = $self->_get($path);
    
    my $content = $response->{content};
    my $status  = $response->{status};
    
    my $h = decode_json($content);
    # return $h;
    my $s = $h->{items};
    
    my @trends;
    foreach my $search_json (@$s) {
        my $trend = WebService::Walmart::Item->new($search_json);
        push @trends, $trend;
    }
    return @trends;
}

sub paginated {
    my $self = shift;
}

__PACKAGE__->meta->make_immutable;
1;

=pod


=head1 SYNOPSIS

WebService::Walmart  - Generic API to Walmart Labs Open API

=head1 DESCRIPTION

WebService::Walmart is an experimental Perl interface to the Walmart Open API.
While this module will attempt to implement the full API, the Walmart API is in heavy
development, and this module is still figuring out how to implement it.
    
In order to use the API, you will need to sign up for an account and get an API key
located at https://developer.walmartlabs.com/
    
B<NOTE:> This is an B<EXPERIMENTAL release>. The methods are subject to change. Walmart will most likely
change their data structures as they implement more of the API.
    
In order to use the methods below, you will first need to create an instance of this module to work with.
    
    my $walmart = WebService::Walmart->new(
                api_key => '123456781234567812345678',
                format  => 'json',
                debug   => 0,
    );
        
    
=head1 METHODS

Every method in this module currently throws a fatal exception B<WebService::Walmart::Exception> on failure. You
will either want to wrap method calls with an L<eval> statement
or use something like L<Try::Tiny> or L<Try::Catch>.

=head2 stores

 my @stores = $walmart->stores(
                                lat  => 'latitude',
                                lon  => 'longitude',
                                city => 'City Name',
                                zip  =>  zipcode,
              );

Search the API for stores with the criteria supplied and return an array containing objects of L<WebService::Walmart::Store>
for stores based upon Latitude/Longitude, City Name, or Zipcode.
More information on the response data can be found at https://developer.walmartlabs.com/docs/read/Store_Locator_API
    
Example:
    
  my @stores = $walmart->stores( zip=> 72716);
  print $stores[0]->phoneNumber;
    
=head2 items

  my $item = $walmart->item( id  => itemid);

This method will search for an item based upon ID and return a scalar object containing L<WebService::Walmart::Item>.
    
Example:
    
  my $item = $walmart->items( id => 42608121);
  print $item->name;
    
=head2 reviews

 $walmart->reviews(
    id => itemid
);
    
This method will retrieve the reviews for an item based up on ID and return an array of L<WebService::Walmart::Review>.
Example: 
    
  my @reviews = $walmart->reviews({ id => '42608121'});
  print  $review[0]->name;
             
=head2 search
 
 $walmart->search(
    query        => 'string',   # a string to search for
    categoryId   => 1234,       # a Category ID to search for. This should match the ID in the WebService::Walmart::Taxonomy package
    facet        => 'string',   # enable facets
    facet.filter => 'string',   # filter to apply to the facets
);
    
This method will search for items and return an array of L<Webservice::Walmart::Item>.
Example: 
    
    my @items  = $walmart->search({ query => 'ipod'});
    print "the first item has  ". $search[0]->numReviews . " reviews to read!\n";
             
=head2 vod

 $walmart->vod();

This method will return the value of the day in scalar format. It will return a L<WebService::Walmart::Item> object.
Example: 
    
    my $vod  = $walmart->vod();
    print "Today's Value of the Day is ". $vod->name . "\n";
             
=head2 trends

 $walmart->trends();

Returns trending items on Walmart.com. This will be an array of L<WebService::Walmart::Item> objects.
Example: 
    
    my @trends = $walmart->trends();
    print "The big name in today's trends are  ". $_->name . "\n" foreach @trends
             
=head2 taxonomy

 $walmart->taxonomy();
    
Returns a L<WebService::Walmart::Taxonomy>  objects as an array. This is how Walmart.com categorizes items.
Example: 
    
    my @taxonomy = $walmart->taxonomy();
    use Data::Dumper;
    print Dumper @taxonomy;


=head1 BUGS

There will likely be many. Please file a report and I'll fix it as soon as possible.

=head1 SEE ALSO

https://developer.walmartlabs.com/

=cut