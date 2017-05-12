package YAX::Node;

use strict;

use Scalar::Util qw/weaken refaddr/;

use YAX::Query;
use YAX::Constants qw/:all/;

use overload
    '""'   => \&as_string,
    '<=>'  => \&num_cmp,
    'bool' => \&as_bool,
    fallback => 1;

sub NAME () { 0 }
sub TYPE () { 1 }
sub TEXT () { 2 }
sub PRNT () { 3 }

sub new {
    my $class = shift;
    return bless \[ @_ ], $class;
}

sub name {
    my $self = shift;
    $$self->[NAME]
}
sub type {
    my $self = shift;
    $$self->[TYPE];
}
sub data {
    my $self = shift;
    $$self->[TEXT] = shift if @_;
    $$self->[TEXT];
}

sub parent {
    my $self = shift;
    weaken( $$self->[PRNT] = $_[0] ) if @_;
    $$self->[PRNT];
}

sub num_cmp {
    my ( $a, $b ) = @_;
    refaddr( $a ) <=> refaddr( $b );
}

sub next {
    my $self = shift;
    return undef unless $self->parent;
    return undef if $self->parent->[-1] == $self;
    for ( my $x = 0; $x < @{ $self->parent }; $x++ ) {
        if ( $self == $self->parent->[$x] ) {
            return $self->parent->[$x+1];
        }
    }
    return undef;
}

sub prev {
    my $self = shift;
    return undef unless $self->parent;
    return undef if $self->parent->[0] == $self;
    for ( my $x = 0; $x < @{ $self->parent }; $x++ ) {
        if ( $self == $self->parent->[$x] ) {
            return $self->parent->[$x-1];
        }
    }
    return undef;
}

sub document {
    my $self = shift;
    my $root = $self;
    while ( $root->parent ) {
        $root = $root->parent;
        return $root if $root->type == DOCUMENT_NODE;
    }
    return ( );
}

sub as_string {
    my $self = shift;
    if ( $self->type == COMMENT_NODE ) {
        return '<!--'.$self->data.'-->';
    }
    if ( $self->type == CDATA_SECTION_NODE ) {
        return '<![CDATA['.$self->data.']]>';
    }
    if ( $self->type == PROCESSING_INSTRUCTION_NODE ) {
        return '<?'.$self->name.' '.$self->data.' ?>';
    }
}

# prevent stringification when in a boolean context
sub as_bool { 1 }

1;
__END__

=head1 NAME

=head1 DESCRIPTION

This module is used both as a base for L<YAX::Elememt>, L<YAX::Text>
and L<YAX::Fragment>. It is also partly mixed into L<YAX::Document>.

It is also used to represent comment, cdata sections and processing
instruction nodes.

=head1 METHODS

=over 4

=item type()

Returns the type of the node as a number in a way analogous to the
W3C DOM:

 use YAX::Constants qw/:all/;

 if ( $node->type == ELEMENT_NODE ) {
     ...
 }

=item name()

If the node is an element node, then returns the tag name,
otherwise returns a human readible string: '#text', '#document',
'#processing-instruction', etc.

=item data( $new_val )

Used for text nodes, CDATA sections, processing instructions and
declaration nodes to store the text values associated with them.

=item next()

Returns the next sibling if any.

=item prev()

Returns the previous sibling if any.

=item parent( $new_value )

Returns the parent node if any.

=item document()

Returns the document node ancestor of this node. Only works if this node
is actually part of the tree (this is different to the W3C DOM where a
node remains owned by a document after it is removed).

=item as_string()

Serializes this node. '""' is overloaded to call this method, so the
following are equivalent:

 my $xml_str = $node->as_string;
 my $xml_str = "$node";

=back

=head1 SEE ALSO

L<YAX:Element>, L<YAX::Text>, L<YAX::Fragment>, L<YAX::Constants>,
L<YAX::Document>

=head1 AUTHOR

 Richard Hundt

=head1 LICENSE

This program is free software and may be modified and distributed under
the same terms as Perl itself.

