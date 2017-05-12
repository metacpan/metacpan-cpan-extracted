package YAX::Element;

use strict;

use base qw/YAX::Node/;

use YAX;
use YAX::Query;
use YAX::Constants qw/ELEMENT_NODE/;

use Carp ();
use Scalar::Util qw/weaken/;

use overload
    '@{}' => \&children,
    '%{}' => \&attributes,
    '""'  => \&as_string,
    fallback => 1;

sub NAME () { 0 }
sub ATTR () { 1 }
sub KIDS () { 2 }
sub PRNT () { 3 }

sub new {
    my $class = shift;
    my ( $name, %atts ) = @_;
    my $self = bless \[ $name, \%atts, [ ] ], $class;
    $self;
}

sub type { ELEMENT_NODE() }

sub name {
    my $self = shift;
    $$self->[NAME] = shift if @_;
    $$self->[NAME];
}

sub clone {
    my $self = shift;
    my $deep = shift;
    my $copy = ref( $self )->new( $self->name, %$self );
    @$copy = map { $_->clone( $deep ) } @$self if $deep;
    return $copy;
}

sub query {
    my ( $self, $expr ) = @_;
    YAX::Query->new( $self )->select( $expr );
}

sub parent {
    my $self = shift;
    weaken( $$self->[PRNT] = $_[0] ) if @_;
    $$self->[PRNT];
}

sub children {
    my $self = shift;
    $$self->[KIDS];
}

sub attributes {
    my $self = shift;
    $$self->[ATTR];
}

sub append {
    my $self = shift;
    my $node = shift;
    if ( UNIVERSAL::isa( $node, 'YAX::Fragment' ) ) {
        $self->append( $_ ) for @$node;
    } else {
        push @$self, $self->adopt( $node );
    }
    $#$self;
}

sub replace {
    my ( $self, $new, $ref ) = @_;

    for ( my $x = 0; $x < @$self; $x++ ) {
        if ( $self->[$x] == $ref ) {
            if ( UNIVERSAL::isa( $new, 'YAX::Fragment' ) ) {
                splice( @$self, $x, 1, map { $self->adopt( $_) } @$new );
            } else {
                splice( @$self, $x, 1, $self->adopt( $new ) );
            }
            return $x;
        }
    }
}

sub remove {
    my ( $self, $chld ) = @_;
    return unless $chld->parent == $self;
    for ( my $x = 0; $x < @$self; $x++ ) {
        if ( $self->[$x] == $chld ) {
            splice( @$self, $x, 1 );
            $chld->parent( undef );
            return $x;
        }
    }
}

sub insert {
    my ( $self, $new, $ref ) = @_;

    unless ( defined $ref ) {
        if ( UNIVERSAL::isa( $new, 'YAX::Fragment' ) ) {
            unshift( @$self, map { $self->adopt( $_ ) } @$new );
        } else {
            unshift( @$self, $self->adopt( $new ) );
        }
        return 0;
    }

    for ( my $x = 0; $x < @$self; $x++ ) {
        if ( $self->[$x] == $ref ) {
            if ( UNIVERSAL::isa( $new, 'YAX::Fragment' ) ) {
                splice( @$self, $x, 0, map { $self->adopt( $_ ) } @$new );
            } else {
                splice( @$self, $x, 0, $self->adopt( $new ) );
            }
            return $x;
        }
    }
}

sub adopt {
    my ( $self, $node ) = @_;
    unless ( UNIVERSAL::isa( $node, 'YAX::Node' ) ) {
        Carp::croak( "cannot insert `$node' into the document tree" );
    }
    my $prnt = $node->parent;
    if ( defined $prnt and $prnt != $self ) {
        $prnt->remove( $node );
    }
    $node->parent( $self );
    return $node;
}

sub as_string {
    my $self = shift;
    my $name = $self->name;
    my $atts = $self->attributes_as_string;

    return "<$name $atts />" unless @{ $self->children };

    my $kids = $self->children_as_string;
    return "<$name".( $atts ? " $atts" : '' ).">".$kids."</$name>";
}

sub attributes_as_string {
    my $self = shift;
    return join(' ', map {
        $_.'="'.quote( $self->{$_} ).'"'
    } keys %$self);
}

sub children_as_string {
    my $self = shift;
    join( '', map { $_->as_string } @{ $self->children } );
}

sub quote {
    my $str = pop;
    $str =~ s/"/&#34;/gs;
    $str;
}

1;
__END__

=head1 NAME

YAX::Element - a DOM element node

=head1 SYNOPSIS

 use YAX::Element;
  
 # construct
 my $elmt = YAX::Element->new( $name, %attr );
  
 # access an attribute
 $elmt->attributes->{foo} = 'bar';
 $elmt->{foo} = 'bar';  # same as above, '%{}' is overloaded
  
 # access a child
 my $chld = $elmt->children->[2];
 my $chld = $elmt->[2]; # same as above, '@{}' is overloaded
  
 # access the parent
 my $prnt = $elmt->parent;
  
 # access siblings
 my $next = $elmt->next;
 my $prev = $elmt->prev;
  
 # manipulation
 $elmt->append( $new_child );
 $elmt->remove( $old_child );
 $elmt->replace( $new_child, $ref_child );
 $elmt->insert ( $new_child, $ref_child );
  
 # cloning
 my $copy = $elmt->clone( $deep );
  
 # querying
 my $list = $elmt->query( $expr );
  
 # misc
 my $name = $elmt->name;    # tag name
 my $type = $elmt->type;    # YAX::Constants::ELEMENT_NODE
  
 # stringify
 my $xstr = $elmt->as_string;
 my $xstr = "$elmt";

=head1 DESCRIPTION

This module represents element nodes in a YAX node tree.

=head1 METHODS

=over 4

=item type

Returns the value of YAX::Constants::ELEMENT_NODE

=item name

Returns the tag name of this element.

=item next

Returns the next sibling if any.

=item prev

Returns the previous sibling if any.

=item parent

Returns the parent node if any.

=item attributes

Returns a hash ref of attributes.

=item children

Returns an array ref of child nodes.

=item append( $new_child )

Appends $new_child to this node. This is preferred over:

 push @$elmt, $child;

because the C<append(...)> makes sure that the C<$child> knows about
its new parent, and removes it from any existing parent first.

If this doesn't matter to you, then pushing or assigning directly to
the children array ref is faster.

=item replace( $new_child, $ref_child )

Replaces C<$ref_child> with C<$new_child>. As above, this is preferred
to assigning directly to the children array ref.

=item remove( $child )

Removes C<$child>.

=item insert( $new_child, $ref_child )

Inserts C<$new_child> before C<$ref_child> and updates the parent field.

=item clone( $deep )

Clones the node. If C<$deep> is true, then clones deeply.

=item query( $expr )

Returns a query list object containing nodes which match the query
expression C<$expr>. If C<$expr> is not defined, then still returns a
query list object which can be used for chaining.

For details on see L<YAX::Query>.

=item as_string

Serializes this node. '""' is overloaded to call this method, so the
following are equivalent:

 my $xml_str = $node->as_string;
 my $xml_str = "$node";

=back

=head1 SEE ALSO

L<YAX:Node>, L<YAX::Text>, L<YAX::Fragment>, L<YAX::Constants>, L<YAX::Query>

=head1 AUTHOR

 Richard Hundt

=head1 LICENSE

This program is free software and may be modified and distributed under
the same terms as Perl itself.


