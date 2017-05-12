package WebService::ClinicalTrialsdotGov::Study;

use strict;
use warnings;

use Carp qw( cluck );
use base qw( Class::Accessor );

WebService::ClinicalTrialsdotGov::Study->mk_accessors(qw(
   
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
     
   ));

=head1 NAME

WebService::ClinicalTrialsdotGov::Study - Wrapper around the clinicaltrials.gov API

=head1 ACCESSORS

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
