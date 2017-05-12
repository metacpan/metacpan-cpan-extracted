package XML::Parser::ClinicalTrials::Study;
$XML::Parser::ClinicalTrials::Study::VERSION = '1.20150818';
use 5.010;

use constant PREFIX => 'XML::Parser::ClinicalTrials::Study';

use XML::Rabbit::Root;
use DateTime::Format::Natural;

has_xpath_value nct_number                => './id_info/nct_id';
has_xpath_value sponsor                   => './sponsors/lead_sponsor/agency';
has_xpath_value condition                 => './condition';
has_xpath_value study_design              => './study_design';
has_xpath_value description_raw           => './detailed_description/textblock';
has_xpath_value recruitment_status        => './overall_status';
has_xpath_value source                    => './source';
has_xpath_value summary_raw               => './brief_summary/textblock';
has_xpath_value type                      => './study_type';
has_xpath_value brief_title               => './brief_title';
has_xpath_value official_title            => './official_title';
has_xpath_value phase                     => './phase';

has_xpath_value start_date_raw                => './start_date';
has_xpath_value last_changed_raw              => './lastchanged_date';
has_xpath_value first_received_raw            => './firstreceived_date';
has_xpath_value completion_date_raw           =>
    q|./completion_date[@type='Actual']|;
has_xpath_value estimated_completion_date_raw =>
    q|./completion_date[@type='Anticipated']|;
has_xpath_value primary_completion_date_raw =>
    q|./primary_completion_date[@type='Actual']|;

has_xpath_value actual_enrollment    => q|./enrollment[@type='Actual']|;
has_xpath_value estimated_enrollment => q|./enrollment[@type='Anticipated']|;

has_xpath_value_list secondary_ids   =>
    './id_info/org_study_id|./id_info/secondary_id';

has_xpath_value_list sponsors   =>
    './sponsors/lead_sponsor/agency|./sponsors/collaborator/agency';

has_xpath_object_list link            => './link'
                                      => PREFIX . '::Link';

has_xpath_object_list interventions   =>
                     './intervention' => PREFIX . '::Intervention';
has_xpath_object_list design          =>
                     './study_design' => PREFIX . '::Design';
has_xpath_object_list mesh_terms      =>
                     './condition_browse/mesh_term|./intervention_browse/mesh_term'
                                      => PREFIX . '::MeSHTerm';

has_xpath_object_list locations => './location'
                                => PREFIX . '::Location';
has_xpath_object_list contacts  => './overall_contact|./overall_contact_backup'
                                => PREFIX . '::Contact';

has [qw( last_changed first_received start_date completion_date
         estimated_completion_date primary_completion_date )], is => 'rw';

has 'summary',     is => 'ro', lazy => 1, builder => '_build_summary';
has 'description', is => 'ro', lazy => 1, builder => '_build_description';

has 'normalized_phase', is      => 'ro', lazy => 1,
                        builder => '_build_normalized_phase';

sub _build_summary {
    my $raw = $_[0]->summary_raw;
    return unless $raw;

    $raw =~ s/\s+/ /g;
    $raw =~ s/\n/ /g;
    $raw =~ s/\A\s+|\s+\Z//g;

    return $raw;
}

sub _build_description {
    my $raw = $_[0]->description_raw;
    return unless $raw;

    my @lines = split /\n\n/, $raw;

    do {
        s/^\s+|\s+$//g;
        s/\s+/ /g;
    } for @lines;

    return join "\n\n", @lines;
}

sub _build_normalized_phase {
    state $phases = {
        1 => 'I',
        2 => 'II',
        3 => 'III',
        4 => 'IV',
        5 => 'V',
    };

    my $raw = $_[0]->phase;
    return if $raw eq 'N/A';

    $raw =~ s/Phase (\d+)/$phases->{$1}/gi;

    return $raw;
}

has [qw( last_changed first_received start_date
         completion_date estimated_completion_date primary_completion_date )],
    is => 'ro', lazy_build => 1;

sub _build_last_changed    { $_[0]->_normalize_date( 'last_changed_raw'    ) }
sub _build_first_received  { $_[0]->_normalize_date( 'first_received_raw'  ) }
sub _build_start_date      { $_[0]->_normalize_date( 'start_date_raw'      ) }
sub _build_completion_date { $_[0]->_normalize_date( 'completion_date_raw' ) }

sub _build_estimated_completion_date {
    $_[0]->_normalize_date( 'estimated_completion_date_raw' )
}

sub _build_primary_completion_date {
    $_[0]->_normalize_date( 'primary_completion_date_raw' )
}

sub _normalize_date {
    my ($self, $raw) = @_;
    my $value        = $self->$raw;
    return unless $value;

    return DateTime::Format::Natural->new->parse_datetime( $value )->ymd;
}

finalize_class();

__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study - XML parser/representation for ClinicalTrials.gov data

=head1 SYNOPSIS

    use File::Slurper 'read_text';
    use XML::Parser::ClinicalTrials::Study;

    # XML file downloaded from clinicaltrials.gov
    my $xml   = read_text( 'NCT00003095.xml' );
    my $study = XML::Parser::ClinicalTrials::Study->new( xml => $xml );


=head1 DESCRIPTION

The web site L<http://clinicaltrials.gov/> publishes information about
pharmaceutical clinical trials. This module parses the XML files available for
those trials into Moose objects with data accessors. For more details about the
contents of these files, see the glossary of CT.gov site terms at
L<http://www.clinicaltrials.gov/ct2/info/glossary>.

=head1 ACCESSORS

Study instances have several accessors, both simple value accessors and object
accessors.

=head2 Value Accessors

These accessors provide simple values. When a value is not present in the XML
file, this accessor will return the empty string.

=over 4

=item * nct_number

=item * sponsor

=item * condition

=item * study_design

=item * description

=item * recruitment_status

=item * source

=item * summary

=item * type

=item * brief_title

=item * official_title

=item * phase

=item * start_date

=item * last_changed

=item * first_received

=item * completion_date

=item * estimated_completion_date

=item * primary_completion_date

=item * actual_enrollment

=item * estimated_enrollment

=item * normalized_phase

=back

=head2 Object Accessors

These accessors provide array references of other Moose objects with their own
accessors. Where a value is not present in the source XML file, the returned
array reference will be empty.

=over 4

=item * link

An array reference of L<XML::Parser::ClinicalTrials::Study::Link> objects.

=item * interventions

An array reference of L<XML::Parser::ClinicalTrials::Study::Intervention>
objects.

=item * design

An array reference of L<XML::Parser::ClinicalTrials::Study::Design> objects.

=item * mesh_terms

An array reference of L<XML::Parser::ClinicalTrials::Study::MeSHTerm> objects.

=item * locations

An array reference of L<XML::Parser::ClinicalTrials::Study::Location> objects.

=item * contacts

An array reference of L<XML::Parser::ClinicalTrials::Study::Contact> objects.

=back

=head1 NOTES

These modules don't represent I<all> of the data found in CT.gov XML files.
Patches welcome.

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 SEE ALSO

L<XML::Rabbit>, L<WebService::ClinicalTrialsdotGov>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License, version 2.
