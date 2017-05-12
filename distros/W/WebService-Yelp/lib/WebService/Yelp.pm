package WebService::Yelp;

use strict;
use warnings;

our $VERSION = '0.03';

use LWP::UserAgent;
use JSON;
use Scalar::Util qw/looks_like_number/;

use WebService::Yelp::Result;
use WebService::Yelp::Neighborhood;
use WebService::Yelp::Business;
use WebService::Yelp::Review;
use WebService::Yelp::Category;

use WebService::Yelp::Message;

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors(qw/ywsid base_url http_proxy 
                             http_timeout http_agent/);

use Data::Dumper;

=head1 NAME

WebService::Yelp - Yelp.com API Client Implementation

=head1 SYNOPSIS

 use strict;
 use WebService::Yelp;

 my $yelp = WebService::Yelp->new({ywsid => 'XXXXXXXXXXXX'});

 my $biz_res = $yelp->search_review_hood({
                                             term => 'cream puffs',
                                             location => 'San Francisco',
                                             };
 for my $biz (@{$biz_res->businesses()}) {

   my @reviews = $biz->reviews();
   my @hoods = $biz->neighborhoods();

 }

=head1 DESCRIPTION

This module implements a programmatic interface to yelp.com's public REST API.

=head1 REQUIREMENTS

Before you can use this module, you'll need to obtain your very own
"Yelp Web Service ID" (ywsid) from
http://www.yelp.com/developers. While you are there, I'd also urge you to read
Yelp's Terms of Use and documentation. 

Much more documentation is available on Yelp's site:

   http://www.yelp.com/developers/documentation

Most of the functions here map directly to API commands, so it would
be a good idea to familiarize yourself with their documentation first
and then take a look at the methods and parameters here.

=cut


my $base_url = 'http://api.yelp.com';

=head1 METHODS

=head2 new
 
 my $yelp = WebService::Yelp->new($hash_ref);

=head3 Required Parameters

=over 4

* ywsid - your Yelp Web Service ID.

=back

=head3 Optional Parameters

=over 4

* http_proxy - specify a proxy server to use

* http_timeout - specify a timeout (Default is 10 seconds)

=back

=head3 Return Value

=over 4

* A new WebService::Yelp object, or undef if there were problems.

=back

=cut

sub new {
  my $self = shift->SUPER::new(@_);

  unless($self->ywsid()) {
    warn "ywsid is a required init parameter";
    return undef;
  }

  # set up the user agent
  my $ua = LWP::UserAgent->new();
  $ua->agent($self->http_agent() || __PACKAGE__ . '/' . $VERSION);

  $ua->proxy('http', $self->http_proxy()) if $self->http_proxy();
  $ua->timeout($self->http_timeout()) if $self->http_timeout();

  $self->{_ua} = $ua;

  # set up our uri
  my $uri = URI->new($self->base_url() || $base_url);
  $self->{_uri} = $uri;

  # set up the json parser
  my $json = JSON->new();
  $self->{_json} = $json;
  return $self;
}


my %cmap = (
            # review search
            'search.review.bb' => {
                                   req => {
                                           tl_lat => 'double',
                                           tl_long => 'double',
                                           br_lat => 'double',
                                           br_long => 'double',
                                          },
                                   opt => { 
                                           term => 'string',
                                           num_biz_requested => 'int',
                                           output => 'string',
                                           category => 'string',
                                          },
                                   path => 'business_review_search',
                                   returns => 'businesses',
                                  },
            'search.review.gpr' => {
                                    req => {
                                            lat => 'double',
                                            long => 'double',
                                           },
                                    opt => {
                                            term => 'string',
                                            num_biz_requested => 'int',
                                            radius => 'double',
                                            output => 'string',
                                            category => 'string',
                                           },
                                    path => 'business_review_search',
                                    returns => 'businesses',
                                   },
            'search.review.hood' => {
                                     req => {
                                             location => 'string',
                                            },
                                     opt => {
                                             term => 'string',
                                             num_biz_requested => 'int',
                                             radius => 'double',
                                             output => 'string',
                                            },
                                     path => 'business_review_search',
                                     returns => 'businesses',
                                    },
            # phone search
            'search.phone' => {
                               req => {
                                       phone => 'int',
                                      },
                               opt => {
                                       output => 'string',
                                      },
                               path => 'phone_search',
                               returns => 'businesses',
                              },
            # neighborhood search
            'search.neighborhood.geocode' => {
                                              req => {
                                                      lat => 'double',
                                                      long => 'double',
                                                     },
                                              opt => {
                                                      output => 'string',
                                                     },
                                              path => 'neighborhood_search',
                                              returns => 'neighborhoods',
                                             },
            'search.neighborhood.location' => {
                                               req => {
                                                       location => 'string',
                                                      },
                                               opt => {
                                                       output => 'string',
                                                      },
                                               path => 'neighborhood_search',
                                               returns => 'neighborhoods',
                                              },
           );

=head2 Review Search Functions

This set of functions searches for and returns review and business
information. The following two parameters are common across these
functions. Note that output determines the return values for all
search functions as well.

=over 4

  * output - Result output type.

=back

This controls what is returned by the API. The default is
WebService::Yelp::* objects. Other options are 'php', 'json', and
'pickle'. If one of these three options is specified, the raw data
will be returned by the search function as a scalar value. Otherwise,
a B<WebService::Yelp::Result> object will be returned. If there was a
transport level error, search functions simply return undef and print
the requests status line to STDERR. 

Your first step should be to check the B<WebService::Yelp::Message>
object available by calling the B<WebService::Yelp::Result>->message()
method and checking the value of code(). See:

   http://www.yelp.com/developers/documentation/search_api#rCode

for more information on the return codes, messages, and error descriptions.

=over 4

  * category - Narrow results to specific categories.

=back

By selecting only specific categories, search results can be confined
to businesses that match those categories. Multiple categories can be
speficied by combining them with a plus sign, i.e. bars+poolhalls

=head2 search_review_bb - Searching by Map Bounding Box

Limit the search to an area within a specific geographical box
specified by four geographic points.

=head3 Required Parameters

=over 4

* tl_lat - Top Left latitude of bounding box

* tl_long - Top Left longitude of bounding box

* br_lat - Bottom right latitude of bounding box

* br_long - Bottom right longitude of bounding box

=back

=head3 Optional Parameters

=over 4

* term - Business name or search term.

* num_biz_requested - Number of businesses to return (1-20, Default 10).

=back 

=cut

sub search_review_bb {
  return shift->call('search.review.bb', @_);
}

=head2 search_review_gpr - Search by Geo-Point and Radius

Given a point and an outward radius, search for businesses within the area.

=head3 Required Parameters

=over 4

* lat - The latitude of the point.

* long - The longitude of the point.

=back

=head3 Optional Parameters

=over 4

* radius - The outward radius from the two points above, Max is 25.

* term - Business name or search term.

* num_biz_requested - Number of businesses to return (1-20, Default 10).

=back

=cut

sub search_review_gpr {
  return shift->call('search.review.gpr', @_);
}

=head2 search_review_hood - Search by Neighborhood, Address or City

Given a general or specific location, search for matching businesses.

=head3 Required Parameters

=over 4

* location - An address, neighborhood, city, state, or zip code.

=back

=head3 Optional Parameters

=over 4

* radius - The outward radius from the two points above, Max is 25.

* term - Business name or search term.

* num_biz_requested - Number of businesses to return (1-20, Default 10).

=back

=cut

sub search_review_hood {
  return shift->call('search.review.hood', @_);
}

=head2 search_phone - Search by Phone Number

Find a specific business by phone number.

=head3 Required Parameter

=over 4

* phone - An all digit phone number (like 1-234-567-8901)

=back

=cut 

sub search_phone {
  return shift->call('search.phone', @_);
}

=head2 Neighborhood Search Functions

The following functions return neighborhood data. The output parameter
as described above is valid for these as well.

=head2 search_neighborhood_geocode - Search for Neighborhoods by Geo-Ppoint

Given a latitude and longitude, return neighborhood information for
the location.

=head3 Required Parameters

=over 4

* lat - The latitude.

* long - The longitude.

=back

=cut

sub search_neighborhood_geocode {
  return shift->call('search.neighborhood.geocode', @_);
}

=head2 search_neighborhood_location - Search by Address, City, State or Zip

Given a general or specific location, search for matching neighborhoods.

=head3 Required Parameters

=over 4

* location - An address, neighborhood, city, state, or zip code.

=back

=cut

sub search_neighborhood_location {
  return shift->call('search.neighborhood.location', @_);
}

=head2 Other Functions

=head2 call - The actual search function caller

Call is the actual search implementation. The other functions call it by specifying the search function first, so if you'd prefer you can use it directly. Search functions names are separated by periods (in the same way the methods above use underscores) i.e.

$yelp->search_review_gpr({ ....

is the same as 

$yelp->call('search.review.gpr', { .... 

=cut

sub call {
  my ($self, $func, $params, $opts) = @_;

  return undef unless _validate($func, $params);

  $params->{ywsid} = $self->ywsid();
  $self->{_uri}->path($cmap{$func}->{path});
  $self->{_uri}->query_form($params);

  my $req = HTTP::Request->new(GET => $self->{_uri});
  my $res = $self->{_ua}->request($req);

  unless($res->is_success()) {
    warn $res->status_line();
    return undef;
  }

  # if the caller specifies a particular output type, return 
  # the raw output here, otherwise give them big fat objects

  if(defined($params->{output}) &&
     ($params->{output} eq 'json' ||
      $params->{output} eq 'pickle' ||
      $params->{output} eq 'php')) {

    return $res->content();
  }

  my $content = $self->{_json}->decode($res->content());
  my $msg = WebService::Yelp::Message->new($content->{message});
  my ($result, @results);

 PREPARE: {
    if($cmap{$func}->{returns} eq 'businesses') {

      for my $b (@{$content->{businesses}} ) {

        my @reviews;
        while(my $r = shift @{$b->{reviews}}) {
          push @reviews, WebService::Yelp::Review->new($r);
        }
        $b->{reviews} = \@reviews;

        my @neighborhoods;
        while(my $n = shift @{$b->{neighborhoods}}) {
          push @neighborhoods, WebService::Yelp::Neighborhood->new($n);
        }
        $b->{neighborhoods} = \@neighborhoods;

        my @categories;
        while(my $c = shift @{$b->{categories}}) {
          push @categories, WebService::Yelp::Category->new($c);
        }
        $b->{categories} = \@categories;

        my $biz = WebService::Yelp::Business->new($b);

        push @results, $biz;
      }
      $result = WebService::Yelp::Result->new({businesses => \@results,
                                               message => $msg});
      last PREPARE;
    }
  
    if($cmap{$func}->{returns} eq 'neighborhoods') {
      for my $n (@{$content->{neighborhoods}}) {
        my $hood = WebService::Yelp::Neighborhood->new($n);
        push @results, $hood;
      }
      $result = WebService::Yelp::Result->new({neighborhoods => \@results,
                                               message => $msg});
      
      last PREPARE;
    }
  }
  return $result;
}

# this could have probably been done with something from CPAN .. oh well, it
# was a fun wheel to reinvent
sub _validate {
  my ($func, $params) = @_;

  # verify that we know about this function.
  unless($cmap{$func}) {
    warn "Unrecognized function '$func'";
    return 0;
  }

  # verify that we have the required params
  for my $req (keys %{$cmap{$func}->{req}}) {
    unless($params->{$req}) {
      warn "$func requires the '$req' parameter";
      return 0;
    }
    return 0 unless _check_type($cmap{$func}->{req}->{$req},
                                $params->{$req});
  }

  # and do some type checking on the optional ones too
  for my $opt (keys %{$cmap{$func}->{opt}}) {
    
    if(defined($params->{$opt})) {
      return 0 unless(_check_type($cmap{$func}->{opt}->{$opt},
                                  $params->{$opt}));
    }
  }
  return 1;
}
      
sub _check_type {
  my ($type, $value) = @_;

  return 0 unless $value;
  # (very) basic type validation
  if($type eq 'int' ||
     $type eq 'double') {

    unless(looks_like_number($value)) {

      return 0;
    }
  }
  elsif($type eq 'string') {

  }
  return 1;
}


=head1 SEE ALSO

L<LWP::UserAgent>

This module's source and other documentation is hosted at 
http://code.google.com/p/perl-www-yelp-api/

=head1 AUTHOR

josh rotenberg, E<lt>joshrotenberg@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by josh rotenberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

Note that this software is not maintained, endorsed, sponsored,
supported, or otherwise managed by Yelp. All inquiries related to this
software should be directed to the author.

=cut

1;
