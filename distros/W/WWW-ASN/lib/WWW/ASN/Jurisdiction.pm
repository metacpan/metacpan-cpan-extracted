package WWW::ASN::Jurisdiction;
use strict;
use warnings;
use Moo;
extends 'WWW::ASN::Downloader';

use URI;
use XML::Twig;
use WWW::ASN::Document;

has 'id' => (
    is       => 'ro',
    required => 0,
);
has 'name' => (
    is       => 'ro',
    required => 0,
);
has 'type' => (
    is       => 'ro',
    required => 0,
);
has 'abbreviation' => (
    is       => 'ro',
    required => 1,
);

# This is arguably bad to trust, because the
# jurisdiction data might be cached and old.
has 'document_count' => (
    is       => 'ro',
    required => 0,
);

=head1 NAME

WWW::ASN::Jurisdiction - Represents a state, organization, or other entity that publishes standards

=head1 SYNOPSIS

    use WWW::ASN;

    my $asn = WWW::ASN->new();
    for my $jurisdiction ($asn->jurisdictions) {
        say $jurisdiction->name,
            " ( ", $jurisdiction->abbreviation, ")",
            " Type: ", $jurisdiction->type,
            " id: ", $jurisdiction->id;

        foreach my $document (@{ $jurisdiction->documents }) {
            ...;
        }
    }


=head1 ATTRIBUTES

=head2 abbreviation

B<Required>.  An abbreviation for the jurisdiction.

e.g. "AL", "CCSS"

=head2 name

The name of the jurisdiction.  This is typically the state or organization name.

e.g. "Alabama", "Common Core State Standards"

=head2 type

e.g. "U.S. States and Territories", "Organization", "Country"

=head2 id

This is a globally unique URI for this jurisdiction.

=cut

=head1 METHODS

=head2 documents

    my @docs = @{
        $jurisdiction->documents({
            status => 'published',
        })
    };

Returns an array reference of L<WWW::ASN::Document> objects.

Optionally, this method accepts a hash reference containing any
of the following arguments:

=over 4

=item status

Can be one of: C<published>, C<draft>, or C<deprecated>.

Alternatively, you may provide C<statusURI> (but don't worry
if you don't know what this is).

=item subject

Can be a L<WWW::ASN::Subject> object or the string name of the subject.

States and other standards jurisdictions often are not very consistent, and may have
documents categorized under a number of very similar subjects. In general, this
option is not terribly useful for searching (e.g. don't search for "math" with
the expectation that you're receiving all math-related standards documents).

Alternatively, you may provide C<subjectURI> (but don't worry
if you don't know what this is).

=item cache_file

Path to a file used as a cache for this search.

The name of a file containing the XML data from
the last time this was called with the same
jurisdiction, subject, and status options.

If the file does not exist, it will be created.

See L<WWW::ASN/"Cache files"> for more details.

=back

=cut

sub documents {
    my $self = shift;
    my $opt = shift || {};

    my $uri = URI->new('http://asn.jesandco.org/api/1/documents');
    my $params = {
        jurisdiction => $self->abbreviation,
    };
    for (qw(subject subjectURI status statusURI)) {
        $params->{$_} = $opt->{$_} if defined $opt->{$_};
    }
    $uri->query_form($params);
    my $documents_xml = $self->_read_or_download(
        $opt->{cache_file},
        $uri,
    );

    my @rv = ();
    my $handle_document = sub {
        my ($twig, $doc) = @_;

        my $id;
        my @ids = $doc->children('DocumentID');
        for (@ids) {
            if ($_->att('type') && $_->att('type') eq 'asnUri') {
                $id = $_->text;
                last;
            }
        }
        unless ($id) {
            warn "No asnUri DocumentID found in Document element";
            return;
        }

        my @titles = ();
        for ($doc->children('DocumentTitle')) {
            my $lang = $_->att('xml:lang');
            my $title = $_->text;
            push @titles, { language => $lang, title => $title };
        }

        push @rv, WWW::ASN::Document->new(
            id             => $id,
            titles         => \@titles,
            subject_names  => [ map { $_->text } $doc->children('DocumentSubject') ],
            uri            => $id,
            jurisdiction_abbreviation => $doc->first_child('DocumentJurisdiction')->text,
            adoption_date             => $doc->first_child('LocalAdoptionDate')->text,
            status                    => $doc->first_child('PublicationStatus')->text,
        );
    };

    my $twig = XML::Twig->new(
        twig_handlers => {
            '/asnDocuments/Document' => $handle_document,
        },
    );
    $twig->parse($documents_xml);


    return \@rv;
}

=head1 AUTHOR

Mark A. Stratman, C<< <stratman at gmail.com> >>


=head1 SEE ALSO

L<WWW::ASN>

L<WWW::ASN::Document>

L<WWW::ASN::Subject>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
