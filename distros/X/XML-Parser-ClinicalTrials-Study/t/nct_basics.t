#! perl

use strict;
use warnings;

use Test::Most;
use File::Slurper 'read_text';

use XML::Parser::ClinicalTrials::Study;

exit main( @ARGV );

sub main {
    subtest 'Some dates missing'    => \&test_dates_some_missing;
    subtest 'Dates with attributes' => \&test_dates_from_attributes;
    subtest 'Secondary ids present' => \&test_secondary_ids;
    subtest 'Titles present'        => \&test_titles;
    subtest 'Lead sponsor present'  => \&test_lead_sponsor;
    subtest 'All sponsors present'  => \&test_sponsors;
    subtest 'Summary present'       => \&test_summary;
    subtest 'Description present'   => \&test_description;
    subtest 'Status present'        => \&test_recruitment_status;
    subtest 'Phase present'         => \&test_phase;
    subtest 'Enrollment values'     => \&test_enrollment;
    subtest 'Trial locations'       => \&test_locations;
    subtest 'Detail link'           => \&test_link;
    subtest 'MeSH terms'            => \&test_mesh_terms;
    subtest 'Contacts'              => \&test_contacts;

    done_testing;
    return 0;
}

sub create_parser {
    my $file = shift;
    my $xml  = read_text( "t/data/${file}.xml" );

    return XML::Parser::ClinicalTrials::Study->new( xml => $xml );
}

sub test_dates_some_missing {
    my $study = create_parser( 'NCT00001295' );

    is $study->start_date, '1992-01-01',
        'start date should get cleaned up to yyyy-mm-dd';
    is $study->completion_date, undef,
        'missing completion date should be undef';
}

sub test_dates_from_attributes {
    my $study = create_parser( 'NCT00003095' );

    is $study->start_date, '1997-11-01',
        'start date should be available';
    is $study->completion_date, '2001-02-01',
        'actual completion date should be available when provided';
    is $study->primary_completion_date, '2001-02-01',
        'primary completion date should be available when provided';
    is $study->last_changed, '2013-11-07',
        'last changed date should be available';
    is $study->first_received, '1999-11-01',
        'first received date should be available';
}

sub test_secondary_ids {
    my $study = create_parser( 'NCT00003095' );
    my @ids   = sort @{ $study->secondary_ids };

    cmp_deeply \@ids, [qw( CDR0000065813 S9719 U10CA032102 )],
        'secondary ids should be available';
}

sub test_titles {
    my $study = create_parser( 'NCT00003095' );

    like $study->brief_title,
        qr/^S9719 Gene Damage Following.+Stage III Breast Cancer$/,
        'brief title should be available';

    is length $study->brief_title, 90, '... in full';

    like $study->official_title,
        qr/^S9719: Clonal Hematopoiesis.+Ancillary to S9623$/,
        'official title should be available';

    is length $study->official_title, 162, '... in full';
}

sub test_lead_sponsor {
    is create_parser( 'NCT00003095' )->sponsor, 'Southwest Oncology Group',
        'sponsor should be correct';

    is create_parser( 'NCT00001295' )->sponsor,
        'National Cancer Institute (NCI)',
        '... only for lead sponsor';
}

sub test_sponsors {
    my $study    = create_parser( 'NCT00003095' );
    my $sponsors = $study->sponsors;
    is @$sponsors, 2, 'sponsors should return sponsor and collaborators';

    is $sponsors->[1], 'National Cancer Institute (NCI)',
        '... in proper order';

    is @{ create_parser( 'NCT00001295' )->sponsors }, 1,
        '... and should allow zero collaborators';
}

sub test_summary {
    my $study   = create_parser( 'NCT00003095' );
    my $summary = $study->summary;

    like $summary,
        qr/^RATIONALE: Drugs used in chemotherapy.+lymph nodes\.$/,
        'summary should be available';
    unlike $summary, qr/\n/,
        '... with newlines and extraneous whitespace removed';
    is length $summary, 318, '... and the remaining text as written';
}

sub test_description {
    my $study = create_parser( 'NCT00003095' );
    my $desc  = $study->description;

    like $desc,
        qr/\AOBJECTIVES: I\..+200 patients\.\Z/s,
        'detailed description should be available';

    unlike $desc, qr/\n +/, '... with whitespace trimmed';
    is length $desc, 2091, '... and the remaining text as written';
}

sub test_recruitment_status {
    is create_parser( 'NCT00003095' )->recruitment_status, 'Completed',
        'recruitment status should be available';
    is create_parser( 'NCT00001295' )->recruitment_status,
        'Active, not recruiting', 'recruitment status should be available';
}

sub test_phase {
    is create_parser( 'NCT00003095' )->phase, 'N/A',
        'phase should be available';
    is create_parser( 'NCT00001295' )->phase, 'N/A',
        'phase should be available';
    is create_parser( 'NCT01811784' )->normalized_phase, 'I/II',
        '... and normalized, when possible';
}

sub test_enrollment {
    my $study = create_parser( 'NCT00003095' );
    is $study->actual_enrollment, 26, 'actual enrollment should be available';
    is $study->estimated_enrollment, '',
        'estimated enrollment should be empty string when not available';

    $study = create_parser( 'NCT01811784' );
    is $study->actual_enrollment, '',
        'actual enrollment should be empty string when not available';
    is $study->estimated_enrollment, 7696,
        'estimated enrollment should be available';
}

sub test_locations {
    is @{ create_parser( 'NCT00001295' )->locations }, 1,
        'location should be available';

    my $study = create_parser( 'NCT00003095' );
    my $locs  = $study->locations;

    is @$locs, 83, '... all of them';

    my $facility = $locs->[0]->facilities->[0];
    is $facility->name,    'MBCCOP - University of South Alabama';
    is $facility->city,    'Mobile';
    is $facility->state,   'Alabama';
    is $facility->zip,     36688;
    is $facility->country, 'United States';

    $facility = $locs->[-1]->facilities->[-1];
    is $facility->name,    'CCOP - Northwest';
    is $facility->city,    'Tacoma';
    is $facility->state,   'Washington';
    is $facility->zip,     '98405-0986';
    is $facility->country, 'United States';
}

sub test_link {
    is @{ create_parser( 'NCT01811784' )->link }, 0,
        'link should produce empty array reference when absent';
    my $study = create_parser( 'NCT00003095' );
    my $link  = $study->link->[0];

    is $link->url,           'http://cancer.gov/clinicaltrials/SWOG-S9719';
    like $link->description, qr/^Clinical trial summary.+database$/;
}

sub test_mesh_terms {
    my $study = create_parser( 'NCT00001295' );
    my $terms = $study->mesh_terms;

    is @$terms, 5, 'mesh_terms should return array ref of all MeSH terms';
    cmp_deeply, [ map { $_->term } @$terms ],
        [
            'Acquired Immunodeficiency Syndrome',
            'HIV Infections',
            'Neoplasms',
            'Immunologic Deficiency Syndromes',
            'Skin Diseases',
        ], '... with the proper terms';

}

sub test_contacts {
    my $study    = create_parser( 'NCT01811784' );
    my $contacts = $study->contacts;

    is @$contacts, 2, 'contacts should return array ref of contact and backup';
    my $contact  = $contacts->[0];
    is $contact->email, 'rebeca@icddrb.org';
    is $contact->last_name, 'Rebeca Sultana, MSS in Anthropology';
    is $contact->phone, '+88029827001-10';
    is $contact->phone_ext, '2548';

    $contact     = $contacts->[1];
    is $contact->email, 'sluby@stanford.edu';
    is $contact->last_name, 'Stephen P Luby, MD';
    is $contact->phone, '';
    is $contact->phone_ext, '';
}
