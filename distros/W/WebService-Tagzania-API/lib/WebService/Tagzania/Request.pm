package WebService::Tagzania::Request ;

use warnings ;
use strict ;

use Carp ;
use URI ;
use HTTP::Request ;
use Data::Dumper ;

our $VERSION = 0.01 ;
our @ISA = qw ( HTTP::Request ) ;

sub new {
  my $class = shift ;
  my $rh_params = shift ;

  my $self = new HTTP::Request ;
      
  return unless $rh_params 
         && defined $rh_params
         && ref $rh_params eq 'HASH' ;
    
  $self->{args} = $rh_params ;
  
  
  $self->method('POST') ;
  my $uri = 'http://www.tagzania.com/xml/bounds/index_html' ;
    
  $self->{uri} = $uri ;
  
  bless $self, $class ;
  return $self ;
}

=head2 encode_arguments

internal function: encode the arguments into the url

=cut

sub encode_arguments {
  my $self = shift ;
  
  my $rh_params = $self->{args} ;
  my $url = URI->new( $self->{uri}, 'http' ) ;
  
  unless ( &validate_arguments( $rh_params ) ) {
    croak "Invalid or missing arguments\n" ;
  }
      
  $url->query_form( %$rh_params ) ;
  return $url ;
    
}

=head2 validate_arguments

internal function: validate the query arguments

=cut

sub validate_arguments {
 my $rh_params = shift ;

 return unless $rh_params 
           && defined $rh_params 
           && ref $rh_params eq 'HASH' ;
 
 unless (   exists $rh_params->{start}  && defined $rh_params->{start} 
         && exists $rh_params->{number} && defined $rh_params->{number}
         && exists $rh_params->{minlng} && defined $rh_params->{minlng}
         && exists $rh_params->{minlat} && defined $rh_params->{minlat}
         && exists $rh_params->{maxlng} && defined $rh_params->{maxlng}
         && exists $rh_params->{maxlat} && defined $rh_params->{maxlat}
  ) {
    croak "Invalid or missing arguments.\nPlease reffer to the documentation for required arguments." ;
  }
      
  return 1 ;

}

=head1 NAME

WebService::Tagzania::API - Tagzania API Interface

=head1 SYNOPSIS

  use WebService::Tagzania::API;
  my $tagobj = new WebService::Tagzania::API() ;
  
  my $rh_params = {
    start  => 0,
    number => 200,
    minlng => -9.25,
    minlat => 35.35,
    maxlng => 4.55,
    maxlat => 43.80,
  } ;

  my $results = $api->query( $rh_params ) ;
  
  next unless 
       $results->{_msg} eq 'OK' ;
  
  my $content = $results->{_content} ;
  
  # do something with the XML inside $content

=head1 DESCRIPTION

Base class for the Tagzania API Request object.

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

L<WebService::Tagzania::API>, L<WebService::Tagzania::Response>, L<http://www.tagzania.com>

=cut


1 ;
