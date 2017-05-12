package WebService::Geograph::API;

use strict;
use warnings ;

use WebService::Geograph::Request ;
use WebService::Geograph::Response ;

use LWP::UserAgent ;
use Data::Dumper ;

our @ISA = qw ( LWP::UserAgent ) ;
our $VERSION = '0.05' ;


sub new {
	my $class = shift ;
	my $rh_options = shift ;
	
	unless (defined ($rh_options->{key}) and ($rh_options->{key})) {
		warn "You must obtain a valid key before using the Geograph API service.\n" .
		     "Visit http://www.geograph.org.uk/help/api for more information.\n" ;
		return undef ;
	}	
	
	# Please do not change the following parameter. 
	# It does not provide geograph.co.uk with any personal information
	# but helps them track usage of this module.
		
	my %options = ( 'agent' => 'WebService::Geograph::API' ) ;
	my $self = new LWP::UserAgent ( %options );
	$self->{key} = $rh_options->{key} ;
	
	bless $self, $class ;
	return $self ;	

}

sub lookup {
	my ($self, $mode, $args) = (@_) ;
	
	return unless ((defined $mode) && (defined $args)) ;
	return unless ref $args eq 'HASH' ;
	
	$args->{key} = $self->{key} ;
	
	my $request = new WebService::Geograph::Request (  $mode , $args  ) ;	
	if (defined $request) {
		$self->execute_request($request) ;
		} else {
			return ;
		}
}

sub execute_request {
	my ($self, $request) = (@_) ;	
  my $url = $request->encode_args() ;
	
  my $response = $self->get($url) ;
	bless $response, 'WebService::Geograph::Response' ;
	
	unless ($response->{_rc} = 200) {
	  $response->set_fail(0, "API returned a non-200 status code: ($response->{_rc})") ;
		return $response ;
  }
	
	$self->create_results_node($request, $response) ;
	
}

sub create_results_node {
	my ($self, $request, $response) = (@_) ;
	
	if ($request->{mode} eq 'csv') {
		 if (defined $response->{_content}) {
				my $csv_data = $response->{_content} ;
				$response->set_success($csv_data) ;
				return $response ;	
		  }
	}
	
	elsif ($request->{mode} eq 'search') {
		if (defined $response->{_previous}->{_headers}->{location}) {
			my $location = $response->{_previous}->{_headers}->{location} ;
			$response->set_success($location) ;
			return $response ;			
		}
}
		
	
	
	
	
}

=head1 NAME

WebService::Geograph::API - Perl interface to the Geograph.co.uk API

=head1 SYNOPSIS

  use WebService::Geograph::API;
  
  my $api = new WebService::Geograph::API ( { 'key' => 'your_api_key_here'} ) ;

  my $rv = $api->lookup ( 'csv', { 'i'     => 12345,
                                   'll'    => 1,
                                   'thumb' => 1,
                                 }) ;

  my $data = $rd->{results} ;

=head1 DESCRIPTION

This module provides a simple interface to using the geograph.co.uk API service.

The actual core class, C<WebService::Geograph::API> is a subclass of C<LWP::UserAgent> so 
all the usual parameters apply.

=head2 METHODS

=over 4

=item C<new>

The following constructing method creates a new C<WebService::Geograph::API> object and returns it. 
It accepts a single parameter, I<key>, which is the API key for the service. You B<must> obtain
a valid key otherwise you will not be able to use the API.

Obtaining a key is free. See : http://www.geograph.org.uk/help/api#api for more information.

	my $api = new WebService::Geograph::API ( { 'key' => 'your_api_key_here'} ) ;

=item C<lookup>

Creates a new C<WebService::Geograph::Request> object and executes it.

	my $rv = $api->lookup ( 'csv', { 'i' => 12345, 'll' => 1, } ) ;
	
	or
	
	my $rv = $api->lookup ( 'search ', { q = 'W12 8JL' } ) ;

Valid modes at the moment include I<csv> for exporting CSV and I<search> for creating custom searches
and obtaining their 'i' number. A very good and detailed overview of the various parameters they
support can be find on the API page located at : http://www.geograph.org.uk/help/api#api

This method creates and returns a new C<WebService::Geograph::Response> object. The object is
a standard C<HTTP::Response> object with some additional fields. If no errors occur, the
results of the query will be located inside I<results> ;

	my $data = $rv->{results} ;

=item C<execute_request>

Internal method that executes a request and blesses the response into a 
C<WebService::Geograph::Response> object.

=item C<create_results_node>

Intenal method which assigns the actual data returned from the API within the 
response objects 'results' key.

=back

=head1 SUPPORT

Please feel free to send any bug reports and suggestions to my email listed below.

For more information and useless facts on my life, you can also check my blog:

  http://idaru.blogspot.com/

=head1 AUTHOR

    Spiros Denaxas
    CPAN ID: SDEN
    Lokku Ltd ( http://www.nestoria.co.uk )
    s [dot] denaxas [@] gmail [dot]com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<WebService::Geograph::Request>, L<WebService::Geograph::Response>, L<http://www.geograph.co.uk>, L<http://www.geograph.org.uk/help/api#api>

=cut

#################### main pod documentation end ###################

1;

