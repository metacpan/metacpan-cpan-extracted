package WebService::TWFY::Response ;

use strict ;
use warnings ;

use HTTP::Response ;

our $VERSION = 0.07 ;
our @ISA = qw( HTTP::Response ) ;

=head1 NAME

WebService::TWFY::Response - API interface for TheyWorkForYou.com

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

This module encapsulates a response from the API. 
C<WebService::TWFY::Response> is essentially a subscall of C<HTTP::Response>.

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

C<WebService::TWFY::API>, C<WebService::TWFY::Request>, L<http://www.theyworkforyou.com/api/>, L<http://www.theyworkforyou.com/>

=cut


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


1 ;