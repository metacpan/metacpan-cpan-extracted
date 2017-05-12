package WebService::Geograph::Response;

use strict ;
use warnings ;

use Data::Dumper ;
use HTTP::Response ;

our @ISA = qw(HTTP::Response) ;

our $VERSION = '0.05' ;

=head1 NAME

WebService::Geograph::Response - A response object from Geograph API

=head1 SYNOPSIS

  use WebService::Geograph::API;
  
  my $api = new WebService::Geograph::API ( { 'key' => 'your_api_key_here'} ) ;

  my $rv = $api->lookup ( 'csv', { 'i'     => 12345,
                                   'll'    => 1,
                                   'thumb' => 1,
                                 }) ;

  my $data = $rd->{results} ;

=head1 DESCRIPTION

This object encapsulates a single response as returned from the API. 

The C<WebService::GeoGraph::Request> object is essentially a subclass of C<HTTP::Response> so you can
actually edit its usual parameters as much as you want.

It also has a number of additional keys.
	
	{
		sucess        => 1 or 0 
		error_code    => contains the error code (if any)
		error_message => contains the error message (if any)
		results       => will always contain the data 
		
	}

=cut

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

=cut 

=head1 SEE ALSO

L<WebService::Geograph::API>, L<WebService::Geograph::Request>, L<http://www.geograph.co.uk>, L<http://www.geograph.org.uk/help/api#api>

=cut

sub new {
	my $class = shift ;
	my $self = new HTTP::Response ;
	my $options = shift ;
	bless $self, $class ;
	return $self ;
	
}

sub init_stats {
 my $self = shift ;
 $self->{results} = undef ;
 $self->{success} = 0 ;
 $self->{error_code} = 0 ;
 $self->{error_message} = 0 ;
}

sub set_fail {
	my ($self, $code, $message) = (@_) ;
	$self->{success} = 0 ;
	$self->{error_code} = $code ;
	$self->{error_message} = $message ;
}

sub set_success {
	my ($self, $data) = (@_) ;
	$self->{success} = 1 ;
	$self->{results} = $data ;
}



	



1 ;

'ERROR: no api key or email address' 