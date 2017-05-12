package WebService::ClinicalTrialsdotGov::Request;

use strict;
use warnings;

use Data::Dumper;
use Carp qw( cluck );

use HTTP::Request;
use URI;
use Clone qw( clone );

my $RH_BASE_URIS = {
   'search' => 'http://clinicaltrials.gov/search',
   'show'   => 'http://clinicaltrials.gov/show',   
};

=head1 NAME

WebService::ClinicalTrialsdotGov::Request - Wrapper around the clinicaltrials.gov API

=head1 FUNCTIONS

=head1 FUNCTIONS

=head2 new 

Creates a new request object.
Do not use this function directly.

=cut

sub new {
   my $class     = shift;
   my $rh_params = shift;

   my $self = { };
   bless $self, $class;

   my $uri    = $self->create_uri( $rh_params );
   $self->{request} = HTTP::Request->new( 'GET', $uri );

   bless $self, $class;
   
}

=head2 create_uri

Creates and encodes the URI.
Do not use this function directly.

=cut

sub create_uri {
   my $self      = shift;
   my $rh_params = shift;
   
   my $rh_search_params = clone( $rh_params );
   
   my $base_uri = 
      $RH_BASE_URIS->{ $rh_search_params->{'mode'} };
   
   if ( $rh_params->{'mode'} eq 'show' ) {
      $base_uri = sprintf('%s/%s', $base_uri, $rh_params->{'id'} );
      delete $rh_search_params->{id};
   }
      
   delete $rh_search_params->{mode};
   
	my $uri  = URI->new( $base_uri, 'http' ) ;

	$uri->query_form( %$rh_search_params  ) ;
	
	return $uri ;
      
}

=head2 request

Returns the internal HTTP request object.
Do not use this function directly.

=cut

sub request {
   my $self = shift;
   return $self->{request};
}

=head1 AUTHOR

Spiros Denaxas, C<< <s.denaxas at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-clinicaltrialsdotgov at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-ClinicalTrialsdotGov>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ClinicalTrialsdotGov

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-ClinicalTrialsdotGov>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-ClinicalTrialsdotGov>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-ClinicalTrialsdotGov>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-ClinicalTrialsdotGov/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Spiros Denaxas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; 
