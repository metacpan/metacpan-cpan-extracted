package WWW::ASN::Standard;
use strict;
use warnings;
use Moo;

=head1 NAME

WWW::ASN::Standard - Represents a standard, or learning objective

=head1 DESCRIPTION

Below you will find a list of attributes you can get from a standard
object.

The descriptions are vague, so please simply examine some
examples to see what they contain (and of course, feel
free to send some better documentation!)

=head1 ATTRIBUTES

=head2 id

This is a globally unique URI for this standard.

=cut

has 'id' => (
    is       => 'ro',
    required => 0,
);

=head2 authority_status

Authority status

=cut

has 'authority_status' => (
    is       => 'ro',
    required => 1,
);

=head2 language

Language this standard is written in.

=cut

has 'language' => (
    is       => 'ro',
    required => 1,
);

=head2 identifier

Identifier

=cut

has 'identifier' => (
    is       => 'ro',
    required => 1,
);

=head2 subject

Subject. This may or may not be the same as L<local_subjects>.

=cut

has 'subject' => (
    is       => 'ro',
    required => 1,
);

=head2 education_levels

Array ref of strings, describing the education levels. e.g. [ qw(K 1 2 3) ]

=cut

has 'education_levels' => (
    is       => 'ro',
    required => 1,
);

=head2 description

This often (usually? always?) contains the same value as L</text>: the 
actual standard or learning objective.

=cut

has 'description' => (
    is       => 'ro',
    required => 1,
);

=head2 text

The actual text of the standard or learning objective.

=cut

has 'text' => (
    is       => 'ro',
    required => 1,
);

=head2 indexing_status

Indexing status

=cut

has 'indexing_status' => (
    is       => 'ro',
    required => 1,
);

=head2 leaf

Leaf

=cut

has 'leaf' => (
    is       => 'ro',
    required => 0,
);

=head2 cls

cls

=cut

has 'cls' => (
    is       => 'ro',
    required => 0,
);

=head2 local_subjects

Array ref of hashrefs looking like this:
{ literal => 'Visual Arts', language => 'en-US' }

For convenience, see also L</local_subject_strings>.

=cut

has 'local_subjects' => (
    is       => 'ro',
    required => 0,
);

=head2 statement_notification

Statement notification

=cut

has 'statement_notification' => (
    is       => 'ro',
    required => 0,
);

=head1 METHODS

In addition to get/set methods for each of the attributes above,
the following methods can be called:

=head2 child_standards

Array ref of L<WWW::ASN::Standard> objects, sub-standards
of this standard.

=cut

has 'child_standards' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_child_standards',
);
sub _build_child_standards {
    my $self = shift;
    return [];
}

=head2 local_subject_strings

A convenience method (not an accessor) to give a string
representation of L</local_subjects>.

=cut

sub local_subject_strings {
    return join ', ', map { $_->{literal} } @{ $_[0]->local_subjects };
}

=head1 AUTHOR

Mark A. Stratman, C<< <stratman at gmail.com> >>


=head1 SEE ALSO

L<WWW::ASN>

L<WWW::ASN::Jurisdiction>

L<WWW::ASN::Document>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
