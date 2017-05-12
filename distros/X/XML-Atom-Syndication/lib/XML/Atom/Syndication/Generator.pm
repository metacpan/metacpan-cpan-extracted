package XML::Atom::Syndication::Generator;
use strict;

use base qw( XML::Atom::Syndication::Object );
use XML::Elemental::Characters;

XML::Atom::Syndication::Generator->mk_accessors('attribute', 'uri', 'version');
XML::Atom::Syndication::Generator->mk_accessors('attribute', 'url')
  ;    # deprecated 0.3 accessors

sub element_name { 'generator' }

sub agent {
    my $e = $_[0]->elem;
    if (@_ > 1) {
        my $chars = XML::Elemental::Characters->new;
        $chars->data($_[1]);
        $chars->parent($e);
        $e->contents([$chars]);
    } else {
        $e->text_content;
    }
}

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Generator - class representing the Atom feed generator

=head1 DESCRIPTION

Identifies the agent used to generate a feed, for debugging and other purposes.

=head1 METHODS

XML::Atom::Syndication::Generator is a subclass of
L<XML::Atom::Syndication:::Object> that it inherits a number of
methods from. You should already be familiar with this base
class before proceeding.

All of these accessors return a string. You can set these attributes
by passing in an optional string.

=over 

=item uri

An IRI reference [RFC3987] that should return a
representation that is relevant to the generating agent.

=item version

Indicates the version of the generating agent. 

=item agent

The contents of the tagset, a human-readable name
for the generating agent.

=back

=head2 DEPRECATED

=over 

=item url

This attribute was renamed C<uri> in version 1.0 of the format.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
