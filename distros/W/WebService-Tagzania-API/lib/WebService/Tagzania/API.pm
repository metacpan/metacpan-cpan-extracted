package WebService::Tagzania::API;

use strict   ;
use warnings ;

use WebService::Tagzania::Request ;
use WebService::Tagzania::Response ;

use LWP::UserAgent ;
use Data::Dumper ;

our @ISA = qw ( LWP::UserAgent ) ;
our $VERSION = '0.1' ;

=head1 METHODS

=head2 new

Create a new object for the Tagzania API class.

  my $tagobj = new WebService::Tagzania::API() ;

=cut

sub new {
    my $class = shift ;
    
    ## Please do not change the following parameter. 
  	## It does not reveal any personal information 
  	## but helps Tagzania in tracking usage of their API
  	## through this module.
    
    my %options = ( 'agent' => 'WebService::Tagzania::API' ) ;
    my $self = new LWP::UserAgent ( %options );
    
    bless $self, $class ;
    return $self ;
}

=head2 query
  
Perform a query to the Tagzania API. Accepts a reference to a hash 
with the required query arguments.
  
  my $rh_params = {
    'start'  => 0,
    'number' => 10,
    'minlng' => -9.25,
    'minlat' => 35.35,
    'maxlng' => 4.55,
    'maxlat' => 43.80,
  } ;

  my $response = $tagobj->query( $rh_params ) ;
  
The required parameters are :
  
  start  => defined the element number of which to start from
  number => defined the number of total results to return
  minlng, maxlng, minlat, maxlat => coordinates of bounding box of location to query

  The Tagzania API returns well-formed XML. This will be present in the
  '_content' key of the response.

=cut

sub query {
  my $self = shift ;
  my $rh_params = shift ;
  
  return unless $rh_params
         && defined $rh_params 
         && ref $rh_params eq 'HASH' ;
        
  my $query = new WebService::Tagzania::Request ( $rh_params ) ;
  
  if ( defined $query ) {
   $self->execute_query($query) ;
  } else {
    return undef ;
  }
}

=head2 execute_query

internal function

=cut

sub execute_query {
  my $self = shift ;
  my $query = shift ;
    
  my $url = $query->encode_arguments() ;
  my $response = $self->get($url) ;
  
  bless $response, 'WebService::Tagzania::Response' ;
  
  unless ($response->{_rc} = 200) {
  	  $response->set_fail(0, "API returned a non-200 status code: ($response->{_rc})") ;
  		return $response ;
    } ;
  
  unless ($response->{_msg} eq 'OK') {
    $response->set_fail(0, "An API error has occured: $response->{_msg}") ;
    return $response ;
  }
  
  my $results = $response->{_content} ;
  $response->set_success($results) ;
  
  return $response ;
  
}

=head1 NAME

WebService::Tagzania::API - Tagzania API Interface

=head1 SYNOPSIS

  use WebService::Tagzania::API;
  my $tagobj = new WebService::Tagzania::API() ;
  
  my $rh_params = {
    'start'  => 0,
    'number' => 200,
    'minlng' => -9.25,
    'minlat' => 35.35,
    'maxlng' => 4.55,
    'maxlat' => 43.80,
  } ;

  my $results = $api->query( $rh_params ) ;
  
  my $content = $results->{_content} ;
  
  # do something with the XML inside $content

=head1 DESCRIPTION

Tagzania is all about tags and places. Tagzania lets you create custom maps,
add points of interest on them and share them with other users, all in an extremely
easy fashion. This module provides a Perl OO-ish wrapper around the Tagzania.com API.

=head1 BUGS

None.
That I know of ;)

=head1 AUTHOR

    Spiros Denaxas
    CPAN ID: SDEN
    Lokku Ltd
    s [dot] denaxas [@] gmail [dot]com
    http://idaru.blogspot.com
    http://www.nestoria.co.uk 

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<WebService::Tagzania::Request>, L<WebService::Tagzania::Response>, L<http://www.tagzania.com>

=cut

1;

