package WWW::ASN;
use strict;
use warnings;
use Moo;
extends 'WWW::ASN::Downloader';

use XML::Twig;

use WWW::ASN::Jurisdiction;
use WWW::ASN::Subject;


=head1 NAME

WWW::ASN - Retrieve learning objectives from Achievement Standards Network

=cut

our $VERSION = '0.01';

has jurisdictions_cache => (
    is => 'ro',
);

has subjects_cache => (
    is => 'ro',
);

=head1 SYNOPSIS

Without using caches:

    use WWW::ASN;

    my $asn = WWW::ASN->new;
    for my $jurisdiction (@{ $asn->jurisdictions }) {
        # $jurisdiction is a WWW::ASN::Jurisdiction object

        if ($jurisdictions->name =~ /Common Core/i) {
            for my $document (@{ $jurisdictions->documents({ status => 'published' }) }) {
                # $document is a WWW::ASN::Document object

                for my $standard (@{ $document->standards }) {
                    # $standard is a WWW::ASN::Standard document
                    print $standard->identifier, ": ", $standard->text;
                    ...
                    for my $sub_standard (@{ $standard->child_standards }) {
                        ...
                    }
                }
            }
        }
    }

Another example, With cache files (recommended, if possible):

    use WWW::ASN;
    use URI::Escape qw(uri_escape);

    my $asn = WWW::ASN->new({
        jurisdictions_cache => 'jurisdictions.xml',
        subjects_cache      => 'subjects.xml',
    });
    for my $jurisdiction (@{ $asn->jurisdictions }) {
        my $docs_cache = 'doclist_' . $jurisdiction->abbreviation . '.xml';
        for my $doc (@{ $jurisdictions->documents({ cache_file => $docs_cache }) }) {
            # Set these cache values before calling standards()
            $doc->details_cache_file(
                "doc_" . $jurisdiction->abbreviation . '_details_' . uri_escape($doc->id)
            );
            $doc->manifest_cache_file(
                "doc_" . $jurisdiction->abbreviation . '_manifest_' . uri_escape($doc->id);
            );
            for my $standard (@{ $document->standards }) {
                # $standard is a WWW::ASN::Standard document
                ...
                for my $sub_standard (@{ $standard->child_standards }) {
                    ...
                }
            }
        }
    }

=head1 DESCRIPTION

This module allows you to retrieve standards documents from
the Achievement Standards Network (L<http://asn.jesandco.org/>).

As illustrated in the L</SYNOPSIS>, you will typically first
retrieve a L<jurisdiction|WWW::ASN::Jurisdiction> such as a state,
or other organization that creates L<standards documents|WWW::ASN::Document>.
From this jurisdiction you can then retrieve specific documents.

B<Note:> Because this is such a niche module and there aren't many expected
users, some of the documentation may take for granted your familiarity
with the Achievement Standards Network.
If you have difficulties using this module, please feel free to
contact the author with any questions

=head2 Cache files

Many of the methods in these modules allow for the use
of cache files. The main purpose of these options is to allow
you to be a good citizen and avoid unnecessary hits to the
ASN website during your development and testing.

Using them is very simple: Just provide a file name.  That's it!

When a filename is provided it will be used
instead of downloading the data again - unless the file doesn't
exist, in which case the data will be downloaded and saved
to the file.

=head1 ATTRIBUTES

=head2 jurisdictions_cache

Optional.  The name of a file containing the XML data from
http://asn.jesandco.org/api/1/jurisdictions

If the file does not exist, it will be created.

Leave this option undefined to force retrieval 
each time L</jurisdictions> is called.

=head2 subjects_cache

Optional.  The name of a file containing the XML data from
http://asn.jesandco.org/api/1/subjects

If the file does not exist, it will be created.

Leave this option undefined to force retrieval 
each time L</subjects> is called.

=head1 METHODS

In addition to get/set methods for each of the attributes above,
the following methods can be called:

=head2 jurisdictions

Returns an array reference of L<WWW::ASN::Jurisdiction> objects.

=cut

sub jurisdictions {
    my $self = shift;

    my $jurisdictions_xml = $self->_read_or_download(
        $self->jurisdictions_cache, 
        'http://asn.jesandco.org/api/1/jurisdictions',
    );

    my @rv = ();
    my $handle_jurisdiction = sub {
        my ($twig, $jur) = @_;

        my %jur_params = ();
        for my $info ($jur->children) {
            my $tag = $info->tag;

            my $val = $info->text;

            # tags should be organizationName, organizationAlias, ...
            # with 'DocumentCount' being the exception
            $tag =~ s/^organization//;
            $tag = lc $tag;

            if ($tag eq 'name') {
                $jur_params{name} = $val;
            } elsif ($tag eq 'alias') {
                $jur_params{id} = $val;
            } elsif ($tag eq 'jurisdiction') {
                $jur_params{abbreviation} = $val;
            } elsif ($tag eq 'class') {
                $jur_params{type} = $val;
            } elsif ($tag eq 'documentcount') {
                $jur_params{document_count} = $val;
            } else {
                warn "Unknown tag in Jurisdiction: " . $info->tag;
            }
        }
        push @rv, WWW::ASN::Jurisdiction->new(%jur_params);
    };

    my $twig = XML::Twig->new(
        twig_handlers => {
            '/asnJurisdictions/Jurisdiction' => $handle_jurisdiction,
        },
    );
    $twig->parse($jurisdictions_xml);

    return \@rv;
}

=head2 subjects

Returns an array reference of L<WWW::ASN::Subject> objects.

=cut

sub subjects {
    my $self = shift;

    my $subjects_xml = $self->_read_or_download(
        $self->subjects_cache, 
        'http://asn.jesandco.org/api/1/subjects',
    );

    my @rv = ();
    my $handle_subject = sub {
        my ($twig, $subject) = @_;

        push @rv, WWW::ASN::Subject->new(
            id             => $subject->first_child('SubjectIdentifier')->text,
            name           => $subject->first_child('Subject')->text,
            document_count => $subject->first_child('DocumentCount')->text,
        );
    };

    my $twig = XML::Twig->new(
        twig_handlers => {
            '/asnSubjects/Subject' => $handle_subject,
        },
    );
    $twig->parse($subjects_xml);

    return \@rv;
}

=head1 TODO

=over 4

=item *

Currently you need to start with a jurisdiction (either from calling C<jurisdictions>
on a C<WWW::ASN> object, or by creating one with an C<abbreviation> attribute (and
optionally other attributes), then looping its documents, then fetching their standards.

Ideally the interface should give you more direct routes to get to the data you're interested in.

=cut

=item *

When a L<document|WWW::ASN::Document> creates a L<WWW::ASN::Standard> object, it has to fetch two
documents, the "details" xml and the "manifest" json.

Ideally this would get everything from the "details" document.  We use both though, since it's
simpler and took less time to parse the manifest than the xml.

=item *

Investigate the feasibility of interfacing with the SPARQL endpoint to allow
for more powerful queries.

e.g. get a list of recently updated documents.

=back

=head1 AUTHOR

Mark A. Stratman, C<< <stratman at gmail.com> >>

=head1 SEE ALSO

L<WWW::ASN::Jurisdiction>

L<WWW::ASN::Document>

L<WWW::ASN::Standard>

L<WWW::ASN::Subject>

=head1 ACKNOWLEDGEMENTS

This library retrieves and manipulates data from the Achievement Standards Network.
L<http://asn.jesandco.org/>


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::ASN
