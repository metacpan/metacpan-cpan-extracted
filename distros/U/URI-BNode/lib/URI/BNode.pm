package URI::BNode;

use 5.010;
use strict;
use warnings FATAL => 'all';

use base qw(URI);

use Carp               ();
use Scalar::Util       ();
use Data::GUID::Any    ();
use Data::UUID::NCName ();

# lolol

our $PN_CHARS_BASE = qr/[A-Za-z\x{00C0}-\x{00D6}}\x{00D8}-\x{00F6}
                           \x{00F8}-\x{02FF}\x{0370}-\x{037D}
                           \x{037F}-\x{1FFF}\x{200C}-\x{200D}
                           \x{2070}-\x{218F}\x{2C00}-\x{2FEF}
                           \x{3001}-\x{D7FF}\x{F900}-\x{FDCF}
                           \x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}]/ox;

# from the turtle spec: http://www.w3.org/TR/turtle/#BNodes
our $BNODE = qr/^\s*(_:)?((?:$PN_CHARS_BASE|[_0-9])
                    (?:$PN_CHARS_BASE|[._0-9\x{00B7}
                            \x{0300}-\x{036F}\x{203F}-\x{2040}-])*
                    (?:$PN_CHARS_BASE|[_0-9\x{00B7}
                            \x{0300}-\x{036F}\x{203F}-\x{2040}-])*)
                \s*$/osmx;

sub _uuid () {
    lc Data::GUID::Any::v4_guid_as_string();
}

=head1 NAME

URI::BNode - RDF blank node identifiers which are also URI objects

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    my $bnode = URI::BNode->new;

    print "$bnode\n"; # something like _:EH_kW827XQ6vvX0yF8YzRA

=head1 DESCRIPTION

This module has two purposes:

=over 4

=item 1

Provide a reliable factory interface for generating RDF blank nodes
(via random UUIDs permuted through L<Data::UUID::NCName>).

=item 2

When an RDF blank node class is a subclass of URI, you can use
identity tests to make more robust RDF interfaces, like so:

    $node->isa('URI');        # either URI or bnode, but not literal
    $node->isa('URI::BNode'); # narrow it down further

Along the same vein, coerce string literals into the correct class by
heuristic:

    my $subject = '_:foo';
    my $node = URI::BNode->new($subject); # _:foo becomes a bnode

    # URI::BNode->new('http://foo/') would properly become
    # a URI::http object.

=back

=head1 METHODS

=head2 new [$ID]

Creates a new blank node identifier. If C<$ID> is undefined or empty,
one will be generated using L<Data::UUID::NCName>. If C<$ID> has a
value, it must either begin with C<_:> or conform to the blank node
syntax from the Turtle spec. Other values, including other URIs, will
be passed to the L<URI> constructor.

=cut

sub new {
    my $class = shift;

    my $bnode = _validate(@_);
    return URI->new(@_) unless defined $bnode;

    bless \$bnode, $class;
}

sub _validate {
    my $val = shift;

    if (!defined $val or $val eq '' or $val eq '_:') {
        $val = Data::UUID::NCName::to_ncname(_uuid);
    }
    elsif (my ($scheme, $opaque) = ($val =~ $BNODE)) {
        $val = $opaque;
    }
    else {
        return;
    }

    "_:$val";
}

=head2 name [$NEWVAL]

Alias for L</opaque>.

=head2 opaque [$NEWVAL]

Retrieve or, if supplied a value, replace the blank node's value with
a new one. This method will croak if passed a C<$NEWVAL> which doesn't
match the spec in L<http://www.w3.org/TR/turtle/#BNodes>.

=cut

sub opaque {
    my $self = shift;
    if (@_) {
        my $val = _validate(@_) or
            Carp::croak("Blank node identifier doesn't match Turtle spec");
        $$self = $val;
    }

    (split(/:/, $$self, 2))[1];
}

*name = \&opaque;

# dirty little scheme function
sub _scheme {
    return '_';
}

=head2 from_uuid_urn $UUID

Takes a L<URI::urn::uuid> object and turns it into a blank node. Can
be invoked as either a class or an instance method.

=cut

sub from_uuid_urn {
    my ($class, $uuid) = @_;
    return unless defined $uuid and Scalar::Util::blessed($uuid)
        and $uuid->isa('URI::urn::uuid');
    $class = ref $class || $class;
    $class->new('_:' . Data::UUID::NCName::to_ncname($uuid->uuid));
}

=head2 to_uuid_urn

Takes a blank node (in L<the proper form|Data::UUID::NCName>) and
turns it into a L<URI::urn::uuid> object.

=cut

sub to_uuid_urn {
    my $self   = shift;
    my $opaque = $self->opaque;
    return unless $opaque =~ /^[A-J][0-9A-Za-z_-]{21}(?:[0-9A-Z]{4})?$/;
    URI->new('urn:uuid:' . Data::UUID::NCName::from_ncname($opaque));
}

=head2 skolemize $AUTHORITY

Return the skolemized URI (C<$AUTHORITY/.well-known/genid/...>) for a
given blank node. See
L<RDF 1.1 Concepts|http://www.w3.org/TR/rdf11-concepts/#section-skolemization>.

=cut

sub skolemize {
    my ($self, $base) = @_;
    return unless Scalar::Util::blessed($base) and $base->isa('URI')
        and $base->can('authority') and $base->can('path');
    $base = $base->canonical->clone;
    $base->path('/.well-known/genid/' . $self->opaque);
    $base;
}

=head2 de_skolemize $URI

Take a skolemized URI like C<http://foo.com/.well-known/genid/asdf>
and turn it into C<_:asdf>.

=cut

sub de_skolemize {
    my ($class, $uri) = @_;
    return unless Scalar::Util::blessed($uri) and $uri->isa('URI')
        and $uri->can('authority') and $uri->can('path')
            and $uri->path =~ m!^/.well-known/genid/(.*)!;

    # check this sucka up front
    my $candidate = _validate($1) or return;

    # this is a static method
    $class = ref $class || $class;

    # no need to invoke the constructor, candidate is already valid.
    bless \$candidate, $class;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-uri-bnode at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-BNode>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::BNode


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-BNode>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-BNode>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-BNode>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-BNode/>

=back


=head1 SEE ALSO

=over 4

=item L<URI>

=item L<Data::UUID::NCName>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut

1; # End of URI::BNode
