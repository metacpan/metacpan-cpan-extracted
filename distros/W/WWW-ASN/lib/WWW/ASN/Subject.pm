package WWW::ASN::Subject;
use strict;
use warnings;
use Moo;

has 'id' => (
    is       => 'ro',
    required => 0,
);
has 'name' => (
    is       => 'ro',
    required => 0,
);

# This is arguably bad to trust, because the
# subject data might be cached and old.
has 'document_count' => (
    is       => 'ro',
    required => 0,
);

=head1 NAME

WWW::ASN::Subject - Represents an academic subject

=head1 SYNOPSIS

    use WWW::ASN;

    my $asn = WWW::ASN->new();
    for my $subject ($asn->subjects) {
        say $subject->name,
            " id: ", $subject->id;
    }


=head1 ATTRIBUTES

=head2 name

The name of the subject.

e.g. 'Mathematics'

=head2 id

This is a globally unique URI for this subject.

=cut

=head1 AUTHOR

Mark A. Stratman, C<< <stratman at gmail.com> >>


=head1 SEE ALSO

L<WWW::ASN>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
