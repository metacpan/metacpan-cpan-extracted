package YAX::Builder;

use strict;

use YAX::Text;
use YAX::Element;
use YAX::Fragment;

sub new {
    my ( $class ) = @_;
    my $self = bless { }, $class;
    $self;
}

sub build {
    my ( $self, @specs ) = @_;
    my @nodes = map { $self->node( $_ ) } @specs;
    return wantarray ? @nodes : $nodes[0];
}

sub node {
    my ( $self, $spec ) = @_;
    if ( ref $spec eq 'ARRAY' ) {
        my @copy = @$spec;
        my $name = splice @copy, 0, 1;
        my %atts = ref $copy[0] eq 'HASH' ? %{ splice @copy, 0, 1 } : ( );

        my $node = $self->element( $name, %atts );
        $node->append( $_ ) for $self->build( @copy );
        return $node;
    }
    elsif ( UNIVERSAL::isa( $spec, 'YAX::Node' ) ) {
        return $spec;
    }
    else {
        return $self->text( $spec );
    }
}

sub text {
    my $self = shift;
    YAX::Text->new(@_);
}

sub element {
    my ( $self, $name, %atts ) = @_;
    YAX::Element->new( $name, %atts );
}

sub fragment {
    my ( $self, @kids ) = @_;
    YAX::Fragment->new( $self->build( @kids ) );
}

1;
__END__

=head1 NAME

YAX::Builder - Declarative programmatic DOM construction

=head1 SYNOPSIS

 use YAX::Builder;
 my $elmt = YAX::Builder->node([ $name, @kids ]);
 my $elmt = YAX::Builder->node([ $name, \%atts, @kids ]);

 my @nodes = YAX::Builder->build([ $name1, ... ], [ $namen, ... ]);

 my $text = YAX::Builder->text( $data );
 my $elmt = YAX::Builder->element( $name, %atts );
 my $frag = YAX::Builder->fragment( @kids );

=head1 DESCRIPTION

This module implements a builder for creating DOM trees in a declarative
way (meaning you specify what the shape of the tree fragment is without
specifying how it is constructed) using a terse, array reference based
syntax. For example to following:

 my $node = YAX::Builder->node(
     [ div => { class => 'fancy' },
         [ a => { href => 'http://www.example.com' }, 'Click Me!' ]
     ]
 );

gives you the structure:

 <div class="fancy"><a href="http://www.example.com">Click Me!</a></div>

There are a few simple rules to the structure of an element descriptor
(a L<Text::Node> descriptor is simply a string):

The first element must be a string and is taken as the tag name.
The second element is an optional hash reference which is the attributes.
If the attributes hash reference is not present, then the child nodes
start at the second element.  Anything else is a child. Plain text is
turned into L<YAX::Text> nodes. Examples:

 $n = YAX::Builder->node([ 'div' ])
 $n = YAX::Builder->node([ 'div', { class => 'fancy' }, "Text content" ])
 $n = YAX::Builder->node([ 'div', "Text content 1" ])
 $n = YAX::Builder->node([ 'div', [ 'em', "emphasized" ], $a_node ])

=head1 METHODS

=over 4

=item node( $spec )

Takes an array reference as described above or a single string and returns
either a L<YAX::Element> node, or a L<YAX::Text> node respectively.

=item text( $text )

Takes a text string and returns a L<YAX::Text> node.

=item build( @specs )

Takes a list of descriptors and returns a list of nodes. In a scalar context
returns only the first node.

=item fragment( @specs )

Takes a list of descriptors and returns a L<YAX::Fragment>.

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired by L<HTML::Builder>.

=head1 AUTHOR

 Richard Hundt

=head1 SEE ALSO

L<YAX::Element>, L<YAX::Text>, L<YAX::Fragment>

=head1 LICENSE

This program is free software and may be modified and distributed under the
same terms as Perl itself.
