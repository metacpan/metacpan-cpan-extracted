package XML::XSS;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: XML stylesheet system
$XML::XSS::VERSION = '0.3.5';

use 5.10.0;


use MooseX::SemiAffordanceAccessor;
use Moose;
use MooseX::ClassAttribute;
use Moose::Exporter;

use XML::LibXML;

use XML::XSS::Element;
use XML::XSS::Document;
use XML::XSS::Text;
use XML::XSS::Comment;
use XML::XSS::ProcessingInstruction;

use XML::XSS::Template;

use MooseX::Clone;

use experimental 'smartmatch';

with 'MooseX::Clone';

no warnings qw/ uninitialized /;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'style' ],
    as_is => ['xsst'],
);

sub style { 
    my $metaclass = shift;
    my $master = ($metaclass->linearized_isa)[0]->master;

    my $element = shift;

    my %attr = @_;

    $master->set( $element, \%attr );

}

#class_has 'master' => (
#    is => 'ro',
#    lazy => 1,
#    lazy_build => 1,
#);

sub _build_master {
    my $self = shift;

    return XML::XSS->new;

}

sub master {
    my $class = shift;
    $class = ref $class if ref $class;

    my $var = '$'.$class.'::master';

    my $master = eval $var;

    return $master if $master;

    $master = $class->new;

    for my $super ( reverse grep { $_->isa('XML::XSS') } $class->meta->superclasses ) {
        $master->include( $super->master ) if $super->has_master;
    }

    eval "$var = \$master";

    return $master;
}

sub has_master {
    my $class = shift;
    $class = ref $class if ref $class;

    return eval '$'.$class.'::master';
}

sub include {
    my $self = shift;
    my $to_include = shift;

    for my $elt ( $to_include->element_keys ) {
        $self->_set_element( $elt, $to_include->_element( $elt )->clone );
    }

    $self->set_comment( $to_include->comment->style_attribute_hash );
    $self->set_pi( $to_include->pi->style_attribute_hash );
    $self->set_text( $to_include->text->style_attribute_hash );


}

around new => sub {
    my $orig = shift;
    my $self = shift;

    if ( $self->has_master ) {
        my $self = $self->master->clone;
        $self->BUILDALL( $self->BUILDARGS(@_) );
        return $self;
    }

    return $self->$orig(@_);

};


has document => (
    is      => 'ro',
    default => sub {
        XML::XSS::Document->new( stylesheet => $_[0] );
    },
    traits => [ 'Clone' ],
);



has 'text' => (
    is      => 'ro',
    default => sub { XML::XSS::Text->new( stylesheet => $_[0] ) },
    handles => {
        set_text   => 'set',
        clear_text => 'clear',
    },
    traits => [ 'Clone' ],
);


has comment => (
    is => 'ro',
    default =>
      sub { XML::XSS::Comment->new( stylesheet => $_[0] ) },
    handles => {
        set_comment => 'set',
    },
    traits => [ 'Clone' ],
);


has '_elements' => (
    isa       => 'HashRef[XML::XSS::Element]',
    default   => sub { {} },
    handles  => {
        '_set_element' => 'set',
        '_element' => 'get',
        'element_keys' => 'keys',
    },
    traits => [ 'Clone', 'Hash' ],
);


sub element {
    my ( $self, $name ) = @_;
    my $elt = $self->_element($name);
    unless ($elt) {
        $elt = XML::XSS::Element->new( stylesheet => $self );
        $self->_set_element( $name => $elt );
    }
    return $elt;
}

sub set_element {
    my $self = shift;
    my ( $name, $args ) = @_;

    if ( ref $args eq 'HASH' ) {
        $self->element($name)->set(%$args);
    }
    else {
        $self->_set_element( $name => $args );
    }
}


has 'catchall_element' => (
    is      => 'rw',
    isa     => 'XML::XSS::Element',
    default => sub {
        XML::XSS::Element->new( stylesheet => $_[0] );
    },
    lazy => 1,
    traits => [ 'Clone' ],
);

has pi => (
    is      => 'ro',
    default => sub {
        XML::XSS::ProcessingInstruction->new( stylesheet => $_[0] );
    },
    traits => [ 'Clone' ],
    handles => {
        set_pi => 'set',
    },
);


has stash => (
    is      => 'ro',
    writer  => '_set_stash',
    isa     => 'HashRef',
    default => sub { {} },
);

sub clear_stash { $_[0]->_set_stash( {} ) }


use overload
    '.' => sub { $_[0]->get($_[1]) },
    '""' => sub { return ref shift };


sub set {
    my $self = shift;

    while ( @_ ) {
        my $name = shift;
        my $attrs = shift;

        $self->get($name)->set(%$attrs);
    }
}

sub get {
    my ( $self, $name ) = @_;

    given ( $name ) {
        when ( '#document' ) {
            return $self->document;
        }
        when( '#text' ) {
            return $self->text;
        }
        when( '#comment' ) {
            return $self->comment;
        }
        when( '#pi' ) {
            return $self->pi;
        }
        when( '*' ) {
            return $self->catchall_element;
        }
        default {
            return $self->element($name);
        }
    }


}


sub render {
    my $self = shift;

    my $args = ref( $_[-1] ) eq 'HASH' ? pop @_ : {};

    if ( @_ == 1 and not ref $_[0] ) {
        @_ = ( XML::LibXML->load_xml( string => $_[0] ) );
    }

    my $output;

    for my $node (@_) {

        my $renderer = $self->resolve($node);

        $output .= $renderer->apply( $node, $args );
    }

    return $output;
}

sub detach {
    my ( $self, $node ) = @_;

    # iterate through the nodes and replace the node by a copy

    my $copy = $node->clone;
    $node->set_is_detached(1);

    if ( ref $node eq 'XML::XSS::Text' ) {
        $self->set_text($copy);
        return;
    }
    elsif ( ref $node eq 'XML::XSS::Element' ) {
        for ( $self->element_keys ) {
            if ( $self->element($_) eq $node ) {    # FIXME
                    # FIXME set_element in Stylesheet
                $self->set_element( $_ => $copy );
            }
        }
       if ( $self->catchall_element eq $node ) {
           $self->set_catchall_element( $copy );
       }
    }
    else {
        die;
    }

}


sub resolve {
    my ( $self, $node ) = @_;

    my $type = ref $node;

    given ($type) {
        when ('XML::LibXML::Document') {
            return $self->document;
        }
        when ('XML::LibXML::Element') {
            my $name = $node->nodeName;
            return $self->_element($name) || $self->catchall_element;
        }
        when ('XML::LibXML::Text') {
            return $self->text;
        }
        when ('XML::LibXML::CDATASection') {
            return $self->text;
        }
        when ( 'XML::LibXML::Comment' ) {
            return $self->comment;
        }
        when ( 'XML::LibXML::PI' ) {
            return $self->pi;
        }
        default {
            die "unknown node type: $type";
        }
    }

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XSS - XML stylesheet system

=head1 VERSION

version 0.3.5

=head1 SYNOPSIS

    use XML::XSS;

    my $xss = XML::XSS->new;

    $xss->set( pod => { 
        pre => "=pod\n", 
        post => "=cut\n", 
    } );

    $xss->set( section => { 
        pre => \&pre_section 
    } );

    sub pre_section {
        my ( $self, $node, $args ) = @_;

        return "=head1 " . $node->findvalue( '@title' ) . "\n\n";
    }

    print $xss->render( <<'END_XML' );
    <pod>
        <section title="NAME">XML::XSS - a XML stylesheet system</section>
        ...
    </pod>
    END_XML

=head1 DESCRIPTION

Caution: this is alpha-quality software. Here be enough dragons to send 
Beowulf packing. Caveat maximus emptor.

C<XML::XSS> is a XML stylesheet system loosely similar to 
CSS and XSLT.  A C<XML::XSS> object is made up of 
rendering rules that dictate how the different nodes of
an XML document are to be rendered, and can be applied 
against one or many XML documents. 

C<XML::XSS> is a rewrite of L<XML::XPathScript>, which was
initially part of the L<AxKit> framework.

=head2 The XML Document

C<XML::XSS> uses L<XML::LibXML> under the hood as its XML DOM
API.  Documents can be passed as strings, in which case the creation
of the XML::LibXML object will be done behind the curtain

    $xss->render( '<foo>yadah</foo>' );

or the L<XML::LibXML> object can be passed directly

    my $doc = XML::LibXML->load_xml( location => 'foo.xml' );
    $xss->render( $doc );

=head2 Stylesheet Rules

C<XML::XSS> has 5 different kinds of rules that reflect the
different kinds of nodes that a XML document can have (as per
L<XML::LibXML>): L<XML::XSS::Document>, L<XML::XSS::Text>,
L<XML::XSS::Comment>, L<XML::XSS::ProcessingInstruction> and
L<XML::XSS::Element>. Whereas there are can many C<XML::LibXML::Element>
rules, there is only one instance of each of the first 4 rules per
stylesheet. In addition of the regular C<XML::LibXML::Element> rules, 
a special I<catch-all> C<XML::LibXML::Element> also exists that will
be applied to any document element not explicitly matched by one of the 
element rules.

=head2 Rules Style Attributes

Each rule has a set of style attributes that control how the matching
document node is transformed.  The different types of rule
(L<XML::XSS::Document>, L<XML::XSS::Element>,
L<XML::XSS::Text>, L<XML::XSS::Comment> and L<XML::XSS::ProcessingInstruction>) 
have each a different set of style attributes, which are
described in their relative manpages.

Unless specified otherwise, a style attribute can be assigned a
scalar value or a reference to a sub.  In the second case, the sub will
be evaluated in the context of the processed node and its return value will
be used as the style attribute value.

Upon execution, the sub references will be passed three parameters: 
the invoking rule, the C<XML::LibXML> node it is rendering and the arguments 
ref given to C<render()>. 

    $css->set( 'foo' => {
        pre => '[[[',         
        post => sub {        
            my ( $self, $node, $args ) = @_;
            return $node->findvalue( '@bar' );
        }
    } );

=head2 Modifying Rules While Rendering

Rules attributes changed while rendering only apply to 
the current element.

    $xss->set( 'section' => { 
        process => sub {
            my ( $self, $node ) = @_;
            $self->stash->{section_nbr}++;
            if ( $self->stash->{section_nbr} == 5 ) {
                # only applies to the one section
                $self->set_pre( '>>> this is the fifth section <<<' ); 
            }
            return 1;
        }
    } );

If you want to change the global rule, you have to access the rule
from the stylesheet, like so

    $xss->set( 'section' => { 
        process => sub {
            my ( $self, $node ) = @_;
            $self->stash->{section_nbr}++;
            if ( $self->stash->{section_nbr} == 6 ) {
                $self->stylesheet->element('section')->set_pre( 
                    '>>> this is after the fifth section <<<' 
                ); 
            }
            return 1;
        }
    } );

=head1 ATTRIBUTES

=head2 document 

The document rule. Note that this matches against the
C<XML::LibXML::Document> node, not the root element node of
the document.

=head3 document()

Attribute getter.

=head2 text 

The text rule.

=head3 text()

Attribute getter.

=head3 set_text( ... )

Shortcut for

    $xss->text->set( ... );

=head3 clear_text()

Shortcut for

    $xss->text->clear;

=head2 comment

The comment rule.

=head3 comment()

Attribute getter.

=head3 set_comment( ... )

Shortcut for 

    $xss->comment->set( ... )

=head2 elements

The collection of user-defined element rules. 

=head3 element( $name )

Returns the L<XML::XSS::Element> node associated to the tag C<$name>.
If the element didn't already exist, it is automatically created.

    my $elt = $xss->element( 'foo' );  # element for <foo>
    $elt->set( pre => '[foo]' );

=head2 catchall_element

The catch-all element rule, which is applied to
all the element nodes that aren't explicitly matched.

    # change all tags to <unknown> except for <foo>
    $xss->set( 'foo' => { showtag => 1 } );
    $xss->set( '*' => { rename => 'unknown' } );

=head3 catchall_element()

The attribute getter.

=head2 stash

The stylesheet has a stash (an hashref) that is accessible to all the
rules during the rendering of a document, and can be used to pass 
information back and forth.

    $xss->set( section => {  
        intro => \&section_title,
    } );

    # turns <section title="blah"> ...
    # into 1. blah
    sub section_title {
        my ( $self, $node, $args ) = @_;

        my $section_nbr = $self->stash->{section_nbr}++;

        return $section_nbr . ". " . $node->findvalue( '@title' );
    }

By default, the stash is cleared when rendering a document.
To change this behavior, see L<XML::XSS::Document/use_clean_stash>.

=head3 stash()

The attribute getter.

=head3 clear_stash()

Clear the stash.

=head1 OVERLOADING

=head2 Concatenation (.)

The concatenation operator is overloaded to behave as an alias for C<get()>.

    my $chapter = $xss.'chapter';           # just like $xss->get('chapter')

    $chapter->set_pre( '<div class="chapter">' );
    $chapter->set_post( '</div>' );

Gets really powerful when used in concert with the overloading of the rules
and style attributes:

    # equivalent as example above
    $xss.'chapter'.'pre'  *= '<div class="chapter">';
    $xss.'chapter'.'post' *= '</div>';

=head1 METHODS

=head2 set( $element_1 => \%attrs, $element_2 => \%attrs_2, ... )

Sets attributes for a rendering node. 

The C<$name> can be 
an XML element name, or one of the special keywords C<#document>,
C<#text>, C<#comment>, C<#pi> or C<*> (for the
I<catch-all> element), 
which will resolve to the corresponding rendering object.

    $xss->set( 'foo' => { rename => 'bar' } );
    # same as $xss->element('foo')->set( rename => 'bar' );

    $xss->set( '#text' => { filter => { uc shift } } );
    # same as $xss->text->set( filter => { uc shift } );

Note that subsequent calls to C<set()> are additive. I.e.:

    $xss->set( foo => { pre => 'X' } );
    $xss->set( foo => { post => 'Y' } );  # pre is still set to 'X'

If you want to delete an attribute, passes it C<undef> as its 
value.

=head2 render( $xml, \%args )

Returns the output produced by the application of the 
stylesheet to the xml document.  The xml can
be passed as a string, or as a C<XML::LibXML> object.
Several C<XML::LibXML> objects can also be passed, in
which case the return value will be the concatenation
of their transformations.

    my $sections = $xss->render( $doc->findnodes( 'section' ) );

The C<%args> is optional, and will defaults to an empty
hash if not provided.  The reference to C<%args> is also passed to
the recursive calls to C<render()> for the children of the processed
node, which allows for another way for parent/children nodes to pass
information in addition to the C<stash>.

    # count the descendents of all nodes
    $xss->set(
        '*' => {
            process => sub {
                my ( $self, $node, $attrs ) = @_;
                $attrs->{children}++;
                return 1;
            },
            content => sub {
                my ( $self, $node, $attrs ) = @_;

                my %c_attrs;
                my $c_ref = \%c_attrs;
                my $output = $self->render( $node->childNodes, $c_ref );

                $attrs->{children} += $c_ref->{children};

                $self->{post} =
                "\n>>> node has " 
                    . ($c_ref->{children}||0) 
                    . " descendents\n";

                return $output;
            },
        } );

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2013, 2011, 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
