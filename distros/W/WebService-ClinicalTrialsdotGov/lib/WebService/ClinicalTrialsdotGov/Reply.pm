package WebService::ClinicalTrialsdotGov::Reply;

use strict;
use warnings;

use WebService::ClinicalTrialsdotGov::Parser;
use WebService::ClinicalTrialsdotGov::SearchResult;
use WebService::ClinicalTrialsdotGov::Study;


use Carp qw( cluck );
use Data::Dumper;

=head1 NAME

WebService::ClinicalTrialsdotGov::Reply - Wrapper around the clinicaltrials.gov API

=head1 FUNCTIONS

=head2 new

Create a new instance of the reply object.
Do not use this function directly.

=cut

sub new {
   my $class     = shift;
   my $rh_params = shift;
   my $raw_data  = shift;
   my $self      = { };
   
   return undef
      unless defined $raw_data;
   
   bless $self, $class;
   
   $self->{parser} =
      WebService::ClinicalTrialsdotGov::Parser->new();
   
   $self->{decoded} =
      $self->{parser}->parse( $raw_data );   
   
   return $self;
   
}

=head2 get_study

   my $Study = $Results->get_study;

A series of accessors are provided:

   oversight_info
  detailed_description
  study_type
  primary_completion_date
  primary_outcome
  intervention
  intervention_browse
  has_expanded_access
  arm_group
  number_of_arms
  overall_official
  brief_title
  study_design
  location
  id_info
  firstreceived_date
  overall_contact
  overall_status
  verification_date
  source
  keyword
  sponsors
  official_title
  enrollment
  condition_browse
  brief_summary
  location_countries
  is_section_801
  secondary_outcome
  responsible_party
  eligibility
  phase
  lastchanged_date
  start_date
  is_fda_regulated
  required_header
  overall_contact_backup
  condition

This function returns a I<WebService::ClinicalTrialsdotGov::Study> object for a single study.
This function returns I<undef> on error.

=cut

sub get_study {
   my $self = shift;
   
   my $study_content = 
      $self->{decoded};
   
   return undef
      unless defined $study_content && $study_content;
   
   return  WebService::ClinicalTrialsdotGov::Study->new( $study_content );      
   
}


=head2 get_search_results

my $ra_all_obj = 
   $Results->get_search_results;
   
A series of accessors are provided:

   last_changed
   condition_summary
   nct_id
   status
   order
   url
   title
   score
    
This function returns a reference to an array of I<WebService::ClinicalTrialsdotGov::SearchResult> objects.
The nct_id field can be used to obtain the data on individual studies.
This function returns I<undef> on error.

=cut

sub get_search_results {
   my $self = shift;
   my $ra_studies = 
      $self->{decoded}->{clinical_study} || [ ];
   
   return undef
      unless defined $ra_studies && scalar(@$ra_studies);
   
   my $ra_out = [ ];
   
   foreach my $rh_study ( @$ra_studies ) {
      my $obj = 
         WebService::ClinicalTrialsdotGov::SearchResult->new( $rh_study );
      push( @$ra_out, $obj );
   }
   return $ra_out;
}

=head2 count_total

   my $num = $Results->count;

Returns the total number of search results reported by the API.
This function returns I<undef> on error.

=cut

sub count_total {
   my $self = shift;
   return $self->{decoded}->{count} || 0;
}

=head2 count

   my $num = $Results->count;

Returns the total number of search results returned by the API.
This function return I<undef> on error.

=cut

sub count {
   my $self = shift;
   my $ra_all = 
      $self->get_all_studies();
   return scalar(@$ra_all);
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
