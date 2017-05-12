package WebService::TWFY::API;

use strict;
use warnings ;

use WebService::TWFY::Request ;
use WebService::TWFY::Response ;

use LWP::UserAgent ;

our @ISA = qw( LWP::UserAgent ) ;
our $VERSION = 0.07 ;

=head1 NAME

WebService::TWFY::API - API interface for TheyWorkForYou.com

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

  use WebService::TWFY::API ;
  
  my $rh = { key => 'ABC123' }; 
  my $api = WebService::TWFY::API->new( $rh ) ;

  my $rv = $api->query ( 'getConstituency', { 'postcode' => 'W128JL'
                                              'output'   => 'xml',
                                             } ) ;

  if ($rv->{is_success}) {
  
    my $results = $rv->{results} ;
    ### do whatever with results
  
  }

=head1 DESCRIPTION

This module provides a simple interface to the API of TheyWorkForYou.com.

The actual core class, C<WebService::TWFY::API> is a subsclass of C<LWP::UserAgent> so you
are able to tweak all the normal options such as timeout etc. The UserAgent identifier however
is hardcoded to "WebService::TWFY::API module". This does not provide any personal information to
the API. However, it helps them track and monitor usage of the API service from this module.

=head1 METHODS

=over 4

=item C<new> 

The following constructor method creates C<WebService::TWFY::API> object and returns it.

  my $rh = { key => 'ABC123' };

  my $api = WebService::TWFY::API->new( $rh ) ;

The API now requires a key, you can obtain one at L<http://www.theyworkforyou.com/api/key>.
The key above will not work, its only used as an example.

In future versions, if needed, it will support specifying the version of the API you wish to use.

=item C<execute_query>

Internal function which executes a request and blesses the response 
into a C<WebService::TWFY::Response> object.

=item C<query>

Creates a new C<WebService::TWFY::Request> request object and executes it with the parameters specified.

  my $rv = $api->query ( 'getConstituency', { 'postcode' => 'W128JL'
                                              'output'   => 'xml',
                                             } ) ;
  
  or

  my $rv = $api->query ( 'getMP', { 'postcode' => 'W128JL'
                                    'output'   => 'js',
                                  } ) ; 
                                            

  abstract :
  
  my $rv = $api->query ( function, { parameter1 => value, 
                                     parameter2 => value,
                                     ...  
                                   } ) ;

For a complete list of functions supported by the API, visit L<http://www.theyworkforyou.com/api>. 
Current output methods supported at the moment are B<XML> (xml), B<JS> (js), B<php> (php) and B<RPC over Anything But XML> (rabx).
This essentially returns a C<WebService::TWFY::Response> object, which is a C<HTTP::Response> subclass 
with some additional keys in place:

=over

=item * 
I<is_success>   : 0 or 1

=item *
I<results>      : results returned from the API

=item *
I<error_code>   : the error code (if any)

=item *
I<error_message> : the error message (if any)

=back

=back

=head1 SUPPORT

Please feel free to send any bug reports and suggestions to my email listed below.

For more information and useless facts on my life, you can also check my blog:

  http://ffffruit.com/

=head1 AUTHOR

    Spiros Denaxas
    CPAN ID: SDEN
    s [dot] denaxas [@] gmail [dot]com
    http://ffffruit.com

=head1 SOURCE CODE

The source code for his module is now on github L<https://github.com/spiros/WebService-TWFY-API>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

C<WebService::TWFY::Request>, C<WebService::TWFY::Response>, L<http://www.theyworkforyou.com/api/>, L<http://www.theyworkforyou.com/>

=cut

sub new {
    my $class = shift ;
    my $rh    = shift;
    
    unless ( defined $rh->{key} ) {
       die "The API requires a key. You can obtain one at http://www.theyworkforyou.com/api/key";
    }
    
    # Please do not change the following user agent parameter.
    # It does not provide TheyWorkForYou.com with any personal information
    # but however helps them track usage of this CPAN module.
    
    my %options = ( 'agent' => 'WebService::TWFY::API module' ) ;
    
    my $self = new LWP::UserAgent( %options ) ;
    
    bless $self, $class ;
    
    $self->{'_api_key'} = $rh->{'key'};
    
    return $self ;
}


sub query {
  my ( $self, $function, $rh_args ) = (@_) ;
  
  return unless ( (defined $function) and (defined $rh_args) ) ;
  return unless ref $rh_args eq 'HASH' ;
  
  $rh_args->{key} = $self->{_api_key};
  
  my $query = new WebService::TWFY::Request ( $function, $rh_args ) ;
  
  if ( defined $query ) {
    $self->execute_query($query) ;
  } else {
    return ;
  }

}

sub execute_query {
  my ($self, $query) = (@_) ;
  
  my $url = $query->encode_arguments() ;
  my $response = $self->get($url) ;
  
  bless $response, 'WebService::TWFY::Response' ;
  
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

1;

