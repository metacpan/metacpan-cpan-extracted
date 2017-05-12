package YAX::Document;

use strict;

use YAX::Text;
use YAX::Element;
use YAX::Fragment;
use YAX::Constants qw/:all/;
use YAX::Query;

use overload '@{}' => \&children, '%{}' => \&elements, fallback => 1;

sub HASH () { 0 }
sub KIDS () { 1 }
#sub TYPE () { 3 }

sub new {
    my $class = shift;
    my $self = bless \[ { }, [ ], '' ], $class;
    return $self;
}

sub type { DOCUMENT_NODE }
sub name { '#document' }

sub document { $_[0] }

sub elements {
    my $self = shift;
    $$self->[HASH];
}

sub children {
    my $self = shift;
    $$self->[KIDS];
}

sub parent { undef }

#sub doctype {
#    my $self = shift;
#    $$self->[TYPE] = shift if @_;
#    $$self->[TYPE];
#}

sub set {
    my ( $self, $id, $elmt ) = @_;
    $self->elements->{$id} = $elmt;
}

sub get {
    my ( $self, $id ) = @_;
    return $self->elements->{$id};
}

sub root {
    my ( $self ) = @_;
    foreach my $node ( @$self ) {
        return $node if $node->type == ELEMENT_NODE;
    }
    return undef;
}

sub text {
    my ( $self, $text ) = @_;
    my $node = YAX::Text->new( $text );
    return $node;
}

sub element {
    my ( $self, $name, %atts ) = @_;
    my $node = YAX::Element->new( $name, %atts );
    return $node;
}

sub fragment {
    my $self = shift;
    my $frag = YAX::Fragment->new(@_);
    return $frag;
}

*query        = \&YAX::Element::query;
*append       = \&YAX::Element::append;
*replace      = \&YAX::Element::replace;
*remove       = \&YAX::Element::remove;
*insert       = \&YAX::Element::insert;
*_claim_child = \&YAX::Element::_claim_child;

sub as_string {
    my $self = shift;
    my @kids = @{ $self->children };
    my $kids = join('', map { $_->as_string } @{ $self->children });
    join( '', $kids );
}

1;

__END__

=head1 NAME

YAX::Document - A DOM document object for YAX

=head1 SYNOPSIS

 use YAX::Document;
 
 $xdoc = YAX::Document->new;
 
 # set/get the doctype
 $xdoc->doctype( $type );
 $type = $xdoc->doctype;
 
 # get the document element (root node)
 $root = $xdoc->root;
 
 $xdoc->set( $node_id => $element );
 $xdoc->get( $node_id );
 
 # the following should be used with care because the document can only
 # have a single root element, so it doesn't make sense to append multiple
 # elements to a document (although YAX doesn't stop you from doing so):
 $xdoc->append( $new_child );
 $xdoc->remove( $old_child );
 $xdoc->replace( $new_child, $ref_child );
 $xdoc->insert ( $new_child, $ref_child );

 # creator methods:
 $elmt = $xdoc->element( $name, %atts );
 $text = $xdoc->text( $text );
 $frag = $xdoc->fragment( @kids );

 # stringify
 $xstr = $xdoc->as_string();

=head1 DESCRIPTION

This module implements a document object for YAX which is returned by
the parser, so you will generally not be constructing these by hand.

It also serves as a registry for nodes keyed on their `id' attribute.

A noteworthy difference between YAX and the W3C DOM is that nodes
in a YAX tree do not keep a reference to the document in which they
are found. However, the document can be accessed from a node if the
node is a descendant of the document, as it is looked up dynamically
by traversing up the ancestor chain.

=head1 SEE ALSO

L<YAX:Node>, L<YAX::Text>, L<YAX::Element>, L<YAX::Fragment>,
L<YAX::Constants>, L<YAX::Query>

=head1 AUTHOR

 Richard Hundt

=head1 LICENSE

This program is free software and may be modified and distributed under
the same terms as Perl itself.


