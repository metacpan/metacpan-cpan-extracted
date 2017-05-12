package WebService::ClinicalTrialsdotGov;

use warnings;
use strict;

use Carp qw( cluck );
use LWP::UserAgent;
use Data::Dumper;

use WebService::ClinicalTrialsdotGov::Request;
use WebService::ClinicalTrialsdotGov::Reply;

our $VERSION = '0.04';

my $RH_VALID_MODES = {
   'search'   => 1,
   'show'     => 1,
};

my $RH_REQUIRED_PARAMS = {
   'search' => {
      'term' => 1,
   },
    
   'show' => {
      'id' => 1,
   },
   
};

my $RH_VALID_PARAMS = {
   'search' => {
      'start'      => 1,
      'count'      => 1,
      'term'       => 1,      
      'recr'       => 1,
      'displayxml' => 1,
   },
   
   'show' => {
      'id' => 1,
   },
   
};

my $RH_DEFAULT_PARAMS = {
   'search' => {
      'count'      => '20',
      'start'      => '0',
      'displayxml' => 'true',
   },
   
  'show' => {
      'displayxml' => 'true',
   },
   
};

=head1 NAME

WebService::ClinicalTrialsdotGov - Wrapper around the clinicaltrials.gov API

=head1 SYNOPSIS

For a generic search:

   use WebService::ClinicalTrialsdotGov;

   my $rh_params = {
      'term'  => 'cancer',
      'start' => 0,
      'count' => 10,
      'mode'  => 'search',   
   };

   my $CT = 
      WebService::ClinicalTrialsdotGov->new( $rh_params );

   my $Results = $CT->results;

   my $ra_all = 
      $Results->get_search_results;

   foreach my $Study ( @$ra_all ) {
      print $Study->title;
   }
   
For obtaining the details of a specific study:

   use WebService::ClinicalTrialsdotGov;

  my $rh_params = {
     'id'    => 'NCT00622401',
     'mode'  => 'show',   
  };

  my $CT = 
     WebService::ClinicalTrialsdotGov->new( $rh_params );

  my $Results = $CT->results;

  my $Study = 
     $Results->get_study;

=head1 FUNCTIONS

=head2 new

Creates a new instance of the module. 

   my $rh_params = {
        'term'  => 'cancer',
        'start' => 0,
        'count' => 10,
        'mode'  => 'search',   
     };

  my $CT = 
     WebService::ClinicalTrialsdotGov->new( $rh_params );

The I<mode> parameter can either be I<search> for a generic search using the contents
of the I<term> parameter as the query or be I<study> using the contents of the I<id> paramter
for identifying the study's ncd_id.

One can additionally specific a stating offset using I<start> and a max results offset
using I<count>. By default, the API will return 20 results.

This function returns I<undef> on error.

=cut

sub new {
   my $class     = shift;
   my $rh_params = shift;
   my $self      = { };

   ##
   ## Check for valid mode
   
   cluck "Invalid search mode: $rh_params->{mode} "
      unless ( exists $RH_VALID_MODES->{ $rh_params->{mode} } );
      
   ##
   ## Check for required params
   
   foreach my $k ( keys %{ $RH_REQUIRED_PARAMS->{ $rh_params->{mode} } } ) {
      
      cluck "Required parameter $k is missing." 
         unless ( $rh_params->{$k} );
      
   };   
   
   ##
   ## Fill in some defaults
   
   foreach my $k ( keys %{ $RH_DEFAULT_PARAMS->{ $rh_params->{mode} } } ) {
      
      unless ( exists $rh_params->{$k} ) {
         $rh_params->{$k} = $RH_DEFAULT_PARAMS->{ $rh_params->{mode} }->{$k};
      }
   
   }
   
   $self->{request} = 
      WebService::ClinicalTrialsdotGov::Request->new( $rh_params );
   
   $self->{agent} = 
      LWP::UserAgent->new( );
   
   $self->{params} =
      $rh_params;
   
   return  bless $self, $class;   
   
}

=head2 results

   my $ResultsObject = $CT->results;

This function returns a I<WebService::ClinicalTrialsdotGov::Reply> object which can be
interrogated to obtain the results in some form or shape.

This function returns I<undef> on error.

=cut

sub results {
   my $self = shift;
   
   my $response =
      $self->{agent}->request( $self->{request}->request );
   
   if ( $response->is_success ) {
      return 
         WebService::ClinicalTrialsdotGov::Reply->new( $self->{params}, $response->decoded_content );
   }
   else {
       cluck $response->status_line;
   }
   
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
