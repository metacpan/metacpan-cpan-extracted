package WebService::Tagzania::Response ;

use warnings ;
use strict ;

use HTTP::Response ;

our @ISA = qw( HTTP::Response ) ;
our $VERSION = 0.01 ;

sub new {
  my $class = shift ;
  my $self = new HTTP::Response ;
  my $rh_oprions = shift ;
  
  bless $self, $class ;
  return $self ;
  
}

sub init_obj {
  my $self = shift ;
  $self->{results} = undef ;
  $self->{is_success} = 0 ;
  $self->{error_code} = undef ;
  $self->{error_message} = undef ;
    
}

sub set_success {
  my ($self, $data) = (@_) ;
  $self->{is_success} = 1 ;
  $self->{results} = $data ;
}

sub set_fail {
  my ($self, $errcode, $errmsg) = (@_) ;
  $self->{is_success} = 0 ;
  $self->{error_code} = $errcode ;
  $self->{error_message} = $errmsg ;
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

Base class for the Tagzania API Response object.

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

L<WebService::Tagzania::Request>, L<WebService::Tagzania::API>, L<http://www.tagzania.com>

=cut

1 ;
