package WWW::ASN::Document;
use strict;
use warnings;
use Moo;
extends 'WWW::ASN::Downloader';

use WWW::ASN::Standard;
use JSON;

=head1 NAME

WWW::ASN::Document - Represents a collection of standards or learning objectives

=head1 SYNOPSIS

    for my $standard (@{ $document->standards }) {
        # $standard is a WWW::ASN::Standard document
        ...
    }

=head1 ATTRIBUTES

=head2 uri

B<Required>.  e.g. http://asn.jesandco.org/resources/D1000195

=cut

has 'uri' => (
    is       => 'ro',
    required => 1,
);

=head2 details_cache_file

Path to a file used as a cache for the "details" download.  If the file does not exist, it will be created.

See L<WWW::ASN/"Cache files"> for more details.

=cut

has details_cache_file => (
    is       => 'rw',
    required => 0,
);

=head2 manifest_cache_file

Path to a file used as a cache for the "manifest" download.  If the file does not exist, it will be created.

See L<WWW::ASN/"Cache files"> for more details.

=cut

has manifest_cache_file => (
    is       => 'rw',
    required => 0,
);

has details_file_contents => (
    is       => 'rw',
    lazy     => 1,
    builder  => '_build_details_file_contents',
);
sub _build_details_file_contents {
    my $self = shift;
    return $self->_read_or_download(
        $self->details_cache_file,
        $self->uri_details_xml,
    );
}
has manifest_file_contents => (
    is       => 'rw',
    lazy     => 1,
    builder  => '_build_manifest_file_contents',
);
sub _build_manifest_file_contents {
    my $self = shift;
    return $self->_read_or_download(
        $self->manifest_cache_file,
        $self->uri_manifest_json,
    );
}

=head2 id

This is a globally unique URI for this document.

=cut

has 'id' => (
    is       => 'ro',
    required => 0,
);

=head2 titles

Array ref of values like this: C< { language => 'en', title => 'Title goes here' } >.

See also L</title> for convenience.

=cut

has 'titles' => (
    is       => 'ro',
    required => 0,
);
sub title {
    my $self = shift;
    return undef unless defined $self->titles;
    my @titles = @{ $self->titles };
    return undef unless @titles;

    for (@titles) {
        if ($_->{language} eq 'en') {
            return $_->{title};
        }
    }
    return $titles[0]->{title};
}

=head2 description

A long description of this document.

=cut

has 'description' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_description',
);
sub _build_description {
    my $self = shift;
    my $details = $self->details;

    my $descriptions = $details->{$self->id}->{'http://purl.org/dc/terms/description'};
    for (@$descriptions) {
        if ($_->{lang} && $_->{lang} eq 'en-US') {
            return $_->{value};
        }
    }
    return @$descriptions ? $descriptions->[0]->{value} : '';
}

=head2 education_levels

Array ref of strings, describing the education levels. e.g. [ qw(K 1 2 3) ]

=cut

has 'education_levels' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_education_levels',
);

sub _build_education_levels {
    my $self = shift;
    my $details = $self->details;

    my $levels = $details->{$self->id}->{'http://purl.org/dc/terms/educationLevel'} || [];
    return [
        grep { defined }
        map { $_->{value} =~ /([^\/]+)$/ ? $1 : undef }
        @$levels
    ];
}

=head2 subject_names 

Array ref of subject names. e.g. [ 'English',  'Language-Arts' ]

=cut

has 'subject_names' => (
    is       => 'ro',
    required => 0,
);
sub subjects {
    my $self = shift;
    return join '; ', @{ $self->subject_names || [] };
}

=head2 jurisdiction_abbreviation

Jurisdiction abbreviation.

=cut

has 'jurisdiction_abbreviation' => (
    is       => 'ro',
    required => 0,
);

=head2 adoption_date

Adoption date

=cut

has 'adoption_date' => (
    is       => 'ro',
    required => 0,
);

=head2 status

Status

=cut

has 'status' => (
    is       => 'ro',
    required => 0,
);

sub uri_manifest_json { return $_[0]->uri . '_manifest.json'; }

sub uri_details_json { return $_[0]->uri . '_full.json'; }

sub uri_details_xml { return $_[0]->uri . '_full.xml'; }

sub uri_details_turtle { return $_[0]->uri . '_full.ttl'; }

sub uri_details_notation3 { return $_[0]->uri . '_full.n3'; }

has 'manifest' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_manifest',
);
sub _build_manifest {
    my $self = shift;
    my $opt = shift || {};

    my $json = $self->manifest_file_contents;

    return JSON->new->utf8->decode($json);
}

has 'details' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_details',
);
sub _build_details {
    my $self = shift;
    my $opt = shift || {};

    my $json = $self->details_file_contents;

    return JSON->new->utf8->decode($json);
}

=head1 METHODS

In addition to get/set methods for each of the attributes above,
the following methods can be called:

=head2 standards

Array ref of L<WWW::ASN::Standard> objects.

=cut

has 'standards' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_standards',
);
sub _build_standards {
    my $self = shift;

    my $manifest = $self->manifest;
    
    my @standards = ();
    for my $data (@$manifest) {
        push @standards, $self->_standard_from_data($data);
    }

    return \@standards;
}

sub _standard_from_data {
    my ($self, $data) = @_;

    my %params = ();

    my $children_data = $data->{children} || [];
    for my $child_data (@$children_data) {
        push @{ $params{child_standards} }, $self->_standard_from_data($child_data);
    }

    $params{description} = $data->{dcterms_description};
    if (defined $params{description} && ref $params{description}) {
        $params{description} = $params{description}->{literal};
    }

    my %hash_vals = (
        asn_indexingStatus  => 'indexing_status',
        asn_authorityStatus => 'authority_status',
        dcterms_language    => 'language',
        dcterms_subject     => 'subject',
    );
    for my $key (keys %hash_vals) {
        $params{$hash_vals{$key}} = $data->{$key} ? $data->{$key}->{prefLabel} : undef;
    }

    my %string_vals = (
        asn_identifier        => 'identifier',
        asn_statementNotation => 'statement_notification',
        cls                   => 'cls',
        text                  => 'text',
        id                    => 'id',
        leaf                  => 'leaf',
    );
    for my $key (keys %string_vals) {
        $params{$string_vals{$key}} = $data->{$key};
    }

    my $ed_levels = $data->{dcterms_educationLevel} || [];
    $ed_levels = [ $ed_levels ] unless ref $ed_levels eq 'ARRAY';
    $params{education_levels} = [ grep { defined } map { $_->{prefLabel} } @$ed_levels ];

    my $local_subjects = $data->{asn_localSubject} || [];
    $local_subjects = [ $local_subjects ] unless ref $local_subjects eq 'ARRAY';
    $params{local_subjects} = $local_subjects;

    return WWW::ASN::Standard->new(%params);
}

=head2 title

This is a convenience method to return a single, preferably English,
value from L</titles>

=head2 subject

This is a convenience method to return a string
representation of L</subject_names>

=head1 AUTHOR

Mark A. Stratman, C<< <stratman at gmail.com> >>

=head1 SEE ALSO

L<WWW::ASN>

L<WWW::ASN::Jurisdiction>

L<WWW::ASN::Standard>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
