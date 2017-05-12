package XML::Struct::Simple;
use strict;
use Moo;
use List::Util qw(first);
use Scalar::Util qw(reftype blessed);

our $VERSION = '0.26';

has root => (
    is => 'rw', 
    default => sub { 0 },
);

has attributes => (
    is => 'rw', 
    default => sub { 1 }, 
    coerce => sub { !defined $_[0] or ($_[0] and $_[0] ne 'remove') },
);

has content => (
    is => 'rw', 
    default => sub { 'content' },
);

has depth => (
    is => 'rw',
    coerce => sub { (defined $_[0] and $_[0] >= 0) ? $_[0] : undef },
);

sub transform {
    my ($self, $element) = @_;
    
    my $simple = $self->transform_content($element,0);

    # enforce root for special case <root>text</root>
    if ($self->root or !ref $simple) {
        my $root = $self->root !~ /^[+-]?[0-9]+$/ ? $self->root : $element->[0];
        return { $root => $simple };
    } else {
        return $simple;
    }
}

# returns a (possibly empty) hash or a scalar
sub transform_content {
    my ($self, $element, $depth) = @_;
    $depth = 0 if !defined $depth;

    if (defined $self->depth and $depth >= $self->depth) {
        return $element;
    } elsif ( @$element == 1 ) { # empty tag
        return { }; 
    }

    my $attributes = {};
    my $children;

    if ( reftype $element->[1] eq 'HASH' ) { # [ $tag, \%attributes, \@children ]
        $attributes = $element->[1] if $self->attributes;
        $children   = $element->[2];
    } else {                                 # [ $tag, \@children ]
        $children   = $element->[1];
    }
    
    # no element children
    unless ( first { ref $_ } @$children ) {
        my $content = join "", @$children;
        if ($content eq '') {
            return { %$attributes };
        } elsif (!%$attributes) {
            return $content;
        } else {
            return { %$attributes, $self->content => $content };
        }
    }

    my $simple = { map {$_ => [$attributes->{$_}] } keys %$attributes };

    foreach my $child ( @$children ) {
        next unless ref $child; # skip mixed content text

        my $name    = $child->[0];
        my $content = $self->transform_content($child, $depth+1);

        if ( $simple->{$name} ) {
            push @{$simple->{$name}}, $content;
        } else {
            $simple->{$name} = [$content];
        }
    }

    foreach my $name (keys %$simple) {
        next if @{$simple->{$name}} != 1;
        my $c = $simple->{$name}->[0];
        if (!ref $c or (!blessed $c and reftype $c eq 'HASH')) {
            $simple->{$name} = $c;
        }
    }

    return $simple;
}

sub removeXMLAttr {
    my $node = shift;
    ref $node
        ? ( $node->[2]
            ? [ $node->[0], [ map { removeXMLAttr($_) } @{$node->[2]} ] ]
            : [ $node->[0] ] ) # empty element
        : $node;               # text node
}


1;
__END__

=encoding UTF-8

=head1 NAME

XML::Struct::Simple - Transform MicroXML data structures into simple (unordered) form

=head1 SYNOPSIS

    my $micro = [ 
        root => { xmlns => 'http://example.org/' }, 
        [ '!', [ x => {}, [42] ] ]
    ];
    my $converter = XML::Struct::Simple->new( root => 'record' );
    my $simple = $converter->transform( $micro );
    # { record => { xmlns => 'http://example.org/', x => 42 } }

=head1 DESCRIPTION

This module implements a transformation from structured XML (MicroXML) to
simple key-value format (SimpleXML) as known from L<XML::Simple>: Attributes
and child elements are treated as hash keys with their content as value. Text
elements without attributes are converted to text and empty elements without
attributes are converted to empty hashes.

L<XML::Struct> can export the function C<simpleXML> for easy use. Function
C<readXML> and L<XML::Struct::Reader> apply transformation to SimpleXML with
option C<simple>. 

=head1 METHODS

=head2 transform( $element )

Transform XML given as array reference (MicroXML) to XML as hash reference
(SimpleXML) as configured.

=head2 transform_content( $element [, $depth ] )

Transform child nodes and attributes of an XML element given as array reference
at a given depth (C<0> by default). Returns a hash reference, a scalar, or the
element unmodified.

=head1 CONFIGURATION

=over

=item root

Keep the root element instead of removing. This corresponds to option
C<KeepRoot> in L<XML::Simple>. In addition a non-numeric value can be used to 
override the name of the root element. Disabled by default.

=item attributes

Include XML attributes. Enabled by default. The special value C<remove> is
equivalent to false. Corresponds to option C<NoAttr> in L<XML::Simple>.

=item content

Name of a field to put text content in. Set to "C<content> by default.
Corresponds to option C<ContentKey> in L<XML::Simple>.

=item depth

Only transform up to a given depth. Set to a negative value by default for
unlimited depth. Elements below depth are not cloned but copied by reference.
Depth 0 will return the element unmodified.

=back

Option C<KeyAttr>, C<ForceArray>, and other fetures of L<XML::Simple> not
supported. Options C<NsExpand> and C<NsStrip> supported in
L<XML::LibXML::Simple> are not supported yet.

=head2 FUNCTIONS

=head2 removeXMLAttr( $element )

Recursively remove XML attributes from XML given as array reference (MicroXML).

This function is deprecated.

=cut
