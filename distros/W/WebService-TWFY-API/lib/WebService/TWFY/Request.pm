package WebService::TWFY::Request ;

use strict ;
use warnings ;

use Carp ;

use HTTP::Request ;
use URI ;

our $VERSION = 0.07 ;
our @ISA = qw( HTTP::Request ) ;

=head1 NAME

WebService::TWFY::Request - API interface for TheyWorkForYou.com

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

This module encapsulates a single request and its arguments. 
C<WebService::TWFY::Request> is essentially a subscall of C<HTTP::Request>.

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

C<WebService::TWFY::API>, C<WebService::TWFY::Response>, L<http://www.theyworkforyou.com/api/>, L<http://www.theyworkforyou.com/>

=cut


sub new {
  my $class = shift ;
  my $self = new HTTP::Request ;
  my $function = shift ;
  my $rh_args = shift ;
  
  $self->{function} = $function ;
  $self->{args} = $rh_args ;
  
  $self->method('POST') ;
  my $uri = &_get_uri_for_function($function) ;
  
  if (not defined $uri) {
    croak "Invalid function: $function\nPlease look at the documentation for supported functions." ;
  }
  
  $self->{uri} = $uri ;
  
  bless $self, $class ;
  return $self ;
}
  
sub _get_uri_for_function {
  my $function = shift ;
  my $URL = 'http://www.theyworkforyou.com/api/' ;
  
  return unless defined $function ;
  
  my $rh_valid_functions = {
    'convertURL'        => 'Convert a parliament.uk URL into a TheyWorkForYou one, if possible',
    'getConstituency'   => 'Searches for a constituency',
    'getConstituencies' => 'Returns a list of constituencies',
    'getMP'             => 'Returns the main details for an MP',
    'getMPInfo'         => 'Returns extra information for an MP',
    'getMPs'            => 'Returns list of MPs',
    'getLord'           => 'Returns details for a Lord',
    'getLords'          => 'Returns list of Lords',
    'getGeometry'       => 'Returns centre, bounding box of constituency',
    'getCommittee'      => 'Returns members of Select Committee',
    'getDebates'        => 'Retuns Debates',
    'getWrans'          => 'Returns Written Answers',
    'getWMS'            => 'Returns Written Ministerial Statements',
    'getComments'       => 'Returns comments',
  } ;

  return unless exists $rh_valid_functions->{$function} ;
  my $uri = $URL . $function ;
  
  return $uri ;

}
  
  
sub encode_arguments {
  my $self = shift ;
  
  my $rh_args = $self->{args} ;
  my $url = URI->new( $self->{uri}, 'http' ) ;
    
  if (exists $rh_args->{output}) {
    &validate_output_argument($rh_args->{output}) ;
  }

  &validate_arguments( $self->{function}, $rh_args ) ;
    
    
  $url->query_form( %$rh_args ) ;
  return $url ;
    
}

sub validate_output_argument {
  my $output = shift ;
  
  croak "Missing value for output parameter.\n" unless 
    defined $output ;
    
  my $rh_valid_params = {
    'xml'  => 'XML output',
    'php'  => 'Serialized PHP',
    'js'   => 'a JavaScript object', 
    'rabx' => 'RPC over Anything But XML',
  } ;
  
  croak "Invalid output selected: $output.\nPlease consult the documentation for valid output modes\n" 
    unless exists $rh_valid_params->{$output} ;
  
}

sub validate_arguments {
  my ($function, $rh_args) = (@_) ;
    
  # make an initial check for missing values 
  
  foreach (keys %$rh_args) {
    croak "Missing value for : $_ " unless
      (defined $rh_args->{$_}) ;
  }
  
  # a list of functions and what parameters 
  # are mandatory for them.
  
  my $rha_functions_params = {
    'convertURL'        => [ 'url' ],
    'getConstituency'   => [ 'postcode' ],
    'getConstituencies' => [ ], 
    'getMP'             => [ ],
    'getMPInfo'         => [ 'id' ],
    'getMPs'            => [ ],
    'getLord'           => [ 'id' ],
    'getLords'          => [ ],
    'getGeometry'       => [ ],
    'getCommittee'      => [ 'name' ],
    'getDebates'        => [ 'type' ],
    'getWrans'          => [ ],
    'getWMS'            => [ ],
    'getComments'       => [ ],
  } ;
  
  my $ra_req_params = $rha_functions_params->{$function}  ;
      
  foreach (@$ra_req_params) {
    croak "$function requires the '$_' parameter \n" unless exists $rh_args->{$_} and
           defined $rh_args->{$_} ;
  } ;

}
  
  
  
  
  
  


1 ;