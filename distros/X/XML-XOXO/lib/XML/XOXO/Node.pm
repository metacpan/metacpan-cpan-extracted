package XML::XOXO::Node;
use strict;
use Class::XPath 1.4
  get_name     => 'name',
  get_parent   => 'parent',
  get_root     => 'root',
  get_children => sub { $_[0]->contents ? @{ $_[0]->contents } : () },
  get_attr_names => sub { keys %{ $_[0]->attributes } },
  get_attr_value => sub { $_[0]->attributes->{ $_[1] } || '' },
  get_content    => sub { $_[0]->attributes->{text} };

sub new {
    my $self = bless {}, $_[0];
    $self->{attributes} = {};
    $self->{contents}   = [];
    $self;
}

sub name       { my $this = shift; $this->stash( 'name',       @_ ); }
sub parent     { my $this = shift; $this->stash( 'parent',     @_ ); }
sub contents   { my $this = shift; $this->stash( 'contents',   @_ ); }
sub attributes { my $this = shift; $this->stash( 'attributes', @_ ); }

sub root {
    my $e = shift;
    while ( $e->can('parent') && $e->parent ) { $e = $e->parent }
    $e;
}

sub stash {
    $_[0]->{ $_[1] } = $_[2] if defined $_[2];
    $_[0]->{ $_[1] };
}

#--- output

sub as_xml {
    my $this = shift;
    my $node = shift || $this;
    die 'A node is required when invoking as_xml as a class method.'
      unless ref($node);
    my $name     = $node->name;
    my $a        = \%{ $node->attributes };    # cloned.
    my $children = $node->contents;
    my $out      = "<$name>\n";

    # special attributes
    my $text = $a->{text} || $a->{title} || $a->{url};
    delete $a->{text};
    my $aa = '';
    if ( exists $a->{url} ) {
        $a->{href} = $a->{url};
        delete $a->{url};
    }
    map { $aa .= " $_=\"" . encode_xml( $a->{$_}, 1 ) . "\""; delete $a->{$_}; }
      grep { exists $a->{$_} } qw( href title rel type );
    if ( length($aa) ) {
        $text = encode_xml( $text, 1 );
        $out .= "<a$aa>$text</a>\n";
    }

    # extended (including multi-valued) attributes
    my $cout = '';
    foreach ( sort keys %$a ) {
        $cout .= '<dt>' . encode_xml($_) . "</dt>\n";
        $cout .= '<dd>';
        $cout .=
          ref( $a->{$_} )
          ? "\n" . $this->as_xml( $a->{$_} )
          : encode_xml( $a->{$_}, 1 );
        $cout .= "</dd>\n";
    }
    $out .= "<dl>\n" . $cout . "</dl>\n" if length($cout);

    # children elements
    map { $out .= $this->as_xml($_) } @$children;
    $out .= "</$name>\n";
    $out;
}

my %Map = (
            '&'  => '&amp;',
            '"'  => '&quot;',
            '<'  => '&lt;',
            '>'  => '&gt;',
            '\'' => '&#39;'
);
my $RE = join '|', keys %Map;

sub encode_xml {
    my ( $str, $nocdata ) = @_;
    return unless defined($str);
    if (
        !$nocdata
        && $str =~ m/
        <[^>]+>  ## HTML markup
        |        ## or
        &(?:(?!(\#([0-9]+)|\#x([0-9a-fA-F]+))).*?);
                 ## something that looks like an HTML entity.
    /x
      ) {
        ## If ]]> exists in the string, encode the > to &gt;.
        $str =~ s/]]>/]]&gt;/g;
        $str = '<![CDATA[' . $str . ']]>';
      } else {
        $str =~ s!($RE)!$Map{$1}!g;
    }
    $str;
}

*query = \&match;

1;

__END__

=begin

=head1 NAME

XML::XOXO::Node -- a node in the XML::RSS::Parser parse tree.

=head1 METHODS

=over

=item XML::XOXO::Node->new( [\%init] )

Constructor for XML::XOXO::Node. 

=item $element->root

Returns a reference to the root node of from the parse tree.

=item $element->parent( [$element] )

Returns a reference to the parent node. A
L<XML::XOXO::Node> object or one of its subclasses can be
passed to optionally set the parent.

=item $element->name( [$extended_name] )

Returns the name of the node (that XHTML tag) as a SCALAR. 

=item $element->attributes( [\%attributes] )

Returns a HASH reference contain attributes and their values as key
value pairs. An optional parameter of a HASH reference can be
passed in to set multiple attributes. Returns C<undef> if no
attributes exist. B<NOTE:> When setting attributes with this
method, all existing attributes are overwritten irregardless of
whether they are present in the hash being passed in.

This is where the node information, such as url, text, and description, 
is be found. Values are scalars unless they are multi-valued in which 
an ARRAY reference is returned.

=item $element->contents([\@children])

Returns an ordered ARRAY reference of direct sibling nodes.
Returns a reference to an empty array if the element does not have
any siblings. If a parameter is passed all the direct siblings are
(re)set.

=item $element->as_xml

Creates an XHTML fragment for the node including its siblings. This has 
its limitations, but should suffice for the relatively straight-forward 
markup used by XOXO.

=back

=head2 XPath-esque Methods

=over

=item $element->query($xpath)

Finds matching nodes using an XPath-esque query from anywhere in
the tree. See the L<Class::XPath> documentation for more
information.

=item $element->xpath

Returns a unique XPath string to the current node which can be used
as an identifier.

=back

These methods were implemented for internal use with L<Class::XPath>
and have now been exposed for general use.

=back

=head1 SEE ALSO

L<XML::Parser>, L<Class::XPath>

=head1 AUTHOR & COPYRIGHT

Please see the XML::XOXO manpage for author, copyright, and
license information.

=cut

=end
