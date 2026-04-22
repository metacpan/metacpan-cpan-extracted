package XML::Chain::Selector;

use warnings;
use strict;
use utf8;
use 5.010;

our $VERSION = '0.07';

use Class::XSAccessor accessors => [qw(current_elements _xc)];
use Carp        qw(croak);
use XML::LibXML qw(:libxml);

sub new {
    my ( $class, @args ) = @_;
    my %args = @args == 1 && ref( $args[0] ) eq 'HASH' ? %{ $args[0] } : @args;

    return bless {
        current_elements => $args{current_elements} || [],
        _xc              => $args{_xc},
    }, $class;
}

use overload '""' => \&as_string, fallback => 1;

### chained methods

sub append_and_select {
    my ( $self, $el_name, @attrs ) = @_;

    my $attrs_ns_uri = {@attrs}->{xmlns};

    # Get the namespace from the prefix if present.
    unless ( defined($attrs_ns_uri) ) {
        my @el_name_parts = split( ':', $el_name, 2 );
        if ( @el_name_parts > 1 ) {
            my $ns_prefix;
            ( $ns_prefix, undef ) = @el_name_parts;
            $attrs_ns_uri = $self->{_xc}
                ->dom->documentElement->getAttribute( 'xmlns:' . $ns_prefix );
        }
    }

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el)           = @_;
                    my $ns_uri         = $attrs_ns_uri // $el->{ns};
                    my $child_elements = $self->{_xc}
                        ->_create_element( $el_name, $ns_uri, @attrs );
                    foreach my $child_el (@$child_elements) {
                        $el->{lxml}->appendChild( $child_el->{lxml} );
                    }
                    return @$child_elements;
                }
            )
        ]
    );
}

*c                  = \&append_and_select;
*append_and_current = \&append_and_select;    # name until <= 0.02

sub append {
    my ( $self, $el_name, @attrs ) = @_;
    return $self->append_and_select( $el_name, @attrs )->parent;
}

*a = \&append;

sub append_text {
    my ( $self, $text ) = @_;

    $self->_cur_el_iterrate(
        sub {
            return $_[0]->{lxml}->appendText($text);
        }
    );

    return $self;
}

*t = \&append_text;

sub parent {
    my ($self) = @_;

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el) = @_;
                    my $parent_el = $el->{lxml}->parentNode;

                    # Stop at the document root: if parent is a document
                    # node, return the current element unchanged
                    return $el
                        if $parent_el->nodeType == XML_DOCUMENT_NODE;

                    return $self->{_xc}->_xc_el_data($parent_el);
                }
            )
        ]
    );
}

*up = \&parent;

sub document_element {
    my ($self) = @_;
    return $self->{_xc}->document_element;
}

*root = \&document_element;

sub find {
    my ( $self, $xpath, @namespaces ) = @_;
    croak 'need xpath as argument' unless defined($xpath);

    my $xpc = XML::LibXML::XPathContext->new();
    while (@namespaces) {
        $xpc->registerNs( splice( @namespaces, 0, 2 ) );
    }
    my $new_self = eval {
        $self->_new_related(
            [   $self->_cur_el_iterrate(
                    sub {
                        my ($el) = @_;
                        my $lxml_el = $el->{lxml};
                        return
                            map { $self->{_xc}->_xc_el_data($_) }
                            $xpc->findnodes( $xpath, $lxml_el );
                    }
                )
            ]
        );
    };
    croak $@ if $@;
    return $new_self;
}

sub children {
    my ($self) = @_;

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el) = @_;
                    return map { $self->{_xc}->_xc_el_data($_) }
                        grep { $_->nodeType == XML_ELEMENT_NODE }
                        $el->{lxml}->childNodes;
                }
            )
        ]
    );
}

sub first {
    my ($self) = @_;
    return $self->_new_related(
        [     @{ $self->current_elements }
            ? @{ $self->current_elements }[0]
            : ()
        ]
    );
}

sub auto_indent {
    my ( $self, $set_to ) = @_;
    croak 'need true/false/options for auto indentation' if @_ < 2;

    $self->_cur_el_iterrate( sub { $_[0]->{auto_indent} = $set_to } );

    return $self;
}

sub empty {
    my ($self) = @_;

    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $el->{lxml}->removeChildNodes;
        }
    );

    return $self;
}

sub rename {
    my ( $self, $new_name ) = @_;
    croak 'need a new name' unless defined($new_name);

    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $el->{lxml}->setNodeName($new_name);
        }
    );

    return $self;
}

sub each {
    my ( $self, $code_ref ) = @_;
    croak 'need a code ref' if ref($code_ref) ne 'CODE';

    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $_ = XML::Chain::Element->new(
                _xc_el_data => $el,
                _xc         => $self->{_xc},
            );
            $code_ref->();
        }
    );

    return $self;
}

sub map_selection {
    my ( $self, $code_ref ) = @_;
    croak 'need a code ref' if ref($code_ref) ne 'CODE';

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el) = @_;
                    local $_ = XML::Chain::Element->new(
                        _xc_el_data => $el,
                        _xc         => $self->{_xc},
                    );
                    my @results = $code_ref->();
                    return CORE::map { @{ $_->current_elements } }
                        CORE::grep {
                               defined($_)
                            && ref($_)
                            && $_->isa('XML::Chain::Selector')
                        } @results;
                }
            )
        ]
    );
}

sub grep_selection {
    my ( $self, $code_ref ) = @_;
    croak 'need a code ref' if ref($code_ref) ne 'CODE';

    return $self->map_selection( sub { $code_ref->() ? $_ : () } );
}

sub remap {
    my ( $self, $code_ref ) = @_;
    croak 'need a code ref' if ref($code_ref) ne 'CODE';

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el) = @_;
                    my $el_xc = XML::Chain::Element->new(
                        _xc_el_data => $el,
                        _xc         => $self->{_xc},
                    );
                    local $_ = $el_xc;
                    my @new_elements = $code_ref->();

                    # Element removed.
                    if ( !defined( $new_elements[0] ) ) {
                        $el_xc->rm;
                        return;
                    }

                    @new_elements = map {
                        croak 'must return isa XML::Chain::Selector'
                            unless $_->isa('XML::Chain::Selector');
                        @{ $_->current_elements }
                    } @new_elements;

                    # Element removed.
                    if ( @new_elements == 0 ) {
                        $el_xc->rm;
                        return;
                    }

                    # If changed, replace the first new element with the old one.
                    if ( $new_elements[0]->{eid} != $el->{eid} ) {
                        $el->{lxml}->replaceNode( $new_elements[0]->{lxml} );
                        $el = $new_elements[0];
                    }

                    # Add all the rest after it.
                    my $i = 1;
                    while ( $i < @new_elements ) {
                        $el->{lxml}->parentNode->insertAfter(
                            $new_elements[$i]->{lxml},
                            $new_elements[ $i - 1 ]->{lxml}
                        );
                        $i++;
                    }

                    return @new_elements;
                }
            )
        ]
    );

    return $self;
}


sub remove_and_parent {
    my ($self) = @_;

    my $parent = $self->parent;
    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $el->{deleted} = 1;
            $el->{lxml}->parentNode->removeChild( $el->{lxml} );
            $el->{lxml} = undef;
        }
    );

    return $parent;
}

*rm = \&remove_and_parent;

sub attr {
    my ( $self, @attrs ) = @_;

    croak 'need an attribute name' unless @attrs;

    # getter
    if ( @attrs == 1 ) {
        my $attr_name = $attrs[0];
        my @attribute_values;
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;
                push( @attribute_values,
                    $el->{lxml}->getAttribute($attr_name) );
            }
        );
        return ( @attribute_values == 1
            ? $attribute_values[0]
            : @attribute_values );
    }

    # setter
    while ( my ( $attr_name, $attr_value ) = splice( @attrs, 0, 2 ) ) {
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;
                if ( defined($attr_value) ) {
                    $el->{lxml}->setAttribute( $attr_name => $attr_value );
                }
                else {
                    $el->{lxml}->removeAttribute($attr_name);
                }
            }
        );
    }

    return $self;
}

### methods

*toString = \&as_string;

sub as_string {
    my ($self) = @_;
    return join(
        '',
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;

                my $auto_indent       = $el->{auto_indent};
                my $auto_indent_chars = (
                    ( ref($auto_indent) eq 'HASH' )
                    ? $auto_indent->{chars}
                    : undef
                );
                $auto_indent_chars = "\t"
                    unless defined($auto_indent_chars);

                my $render_el = $el->{lxml};
                if ($auto_indent) {
                    my $render_doc =
                        XML::LibXML::Document->new( '1.0', 'UTF-8' );
                    $render_el = $render_doc->importNode( $render_el, 1 );
                    $render_doc->setDocumentElement($render_el);
                    _reindent_children( $render_el, $auto_indent_chars );
                }

                return $render_el->toStringC14N;
            }
        )
    );
}

sub _reindent_children {
    my ( $lxml_el, $indent_chars, $level ) = @_;
    $level //= 1;
    my $cur_ident = join( '', map {$indent_chars} ( 1 .. $level ) );
    my $as_string = '';
    my $cur_text  = '';
    my @child_nodes =
        map { $lxml_el->removeChild($_) } $lxml_el->childNodes();
    my $child_nodes_count = @child_nodes;
    while (@child_nodes) {
        my $node      = shift(@child_nodes);
        my $node_type = $node->nodeType;
        if ( $node_type == XML_TEXT_NODE ) {
            $cur_text .= ' ' if length($cur_text);
            $cur_text .= $node->textContent;
            $cur_text =~ s/^\s+//;
            $cur_text =~ s/\s+$//;
            next;
        }
        if ( length($cur_text) ) {
            $lxml_el->appendText( "\n" . $indent_chars . $cur_text );
            $cur_text = '';
        }
        _reindent_children( $node, $indent_chars, $level + 1 );
        $lxml_el->appendText( "\n" . $cur_ident );
        $lxml_el->addChild($node);
    }
    if ( ( $child_nodes_count == 1 ) && length($cur_text) ) {
        $lxml_el->appendText($cur_text);
    }
    else {
        if ( length($cur_text) ) {
            $lxml_el->appendText( "\n" . $indent_chars . $cur_text );
            $cur_text = '';
        }
        $lxml_el->appendText(
            "\n" . join( '', map {$indent_chars} ( 1 .. $level - 1 ) ) )
            if ( $lxml_el->childNodes() );
    }

    return $lxml_el;
}

sub text_content {
    my ($self) = @_;

    my $text = '';
    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $text .= $el->{lxml}->textContent;
            return $el;
        }
    );

    return $text;
}

sub as_xml_libxml {
    my ($self) = @_;

    my @elements;
    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            push( @elements, $el->{lxml} );
        }
    );

    return @elements;
}

sub count {
    my ($self) = @_;
    my $count = 0;
    $self->_cur_el_iterrate( sub { $count++ } );
    return $count;
}

*size = \&count;

sub store      { $_[0]->{_xc}->store }
sub set_io_any { $_[0]->{_xc}->set_io_any( $_[1], $_[2] ) }

sub single {
    my ($self) = @_;
    croak 'more than one current element'
        if @{ $self->current_elements } > 1;
    croak 'no current element' unless @{ $self->current_elements } == 1;
    my $element = @{ $self->current_elements }[0];
    return XML::Chain::Element->new(
        _xc_el_data => $element,
        _xc         => $self->{_xc},
    );
}

sub reg_global_ns {
    my ( $self, $ns_prefix, $ns_uri, $activate ) = @_;
    $self->root->as_xml_libxml->setNamespace( $ns_uri, $ns_prefix,
        ( $activate // 0 ) );
    return $self;
}

sub data {
    my ( $self, $key, $value ) = @_;

    # If called with no args or one arg, do a get-only call
    if ( @_ == 1 ) {

        # Return all data for this selection (only first element)
        my $el = @{ $self->current_elements }[0];
        return {} unless $el;
        return $el->{_data} // {};
    }
    elsif ( @_ == 2 ) {

        # Get a specific key from first element
        my $el = @{ $self->current_elements }[0];
        return undef unless $el;
        return $el->{_data}->{$key};
    }
    else {
        # Set a key on all current elements
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;
                $el->{_data} //= {};
                $el->{_data}->{$key} = $value;
            }
        );
        return $self;
    }
}

### helpers

sub _cur_el_iterrate {
    my ( $self, $code_ref ) = @_;
    croak 'need a code ref argument' unless ref($code_ref) eq 'CODE';
    return
        map { $code_ref->($_) if !$_->{deleted} }
        @{ $self->current_elements };
}

sub _new_related {
    my ( $self, $current_elements ) = @_;
    croak 'need array ref as argument'
        unless ref($current_elements) eq 'ARRAY';

    return XML::Chain::Element->new(
        _xc_el_data => $current_elements->[0],
        _xc         => $self->{_xc},
    ) if @$current_elements == 1;

    # Make current_elements unique.
    my %uniq_eid;
    $current_elements =
        [ grep { $uniq_eid{ $_->{eid} } ? 0 : ( $uniq_eid{ $_->{eid} } = 1 ) }
            @$current_elements ];

    return __PACKAGE__->new(
        current_elements => $current_elements,
        _xc              => $self->{_xc},
    );
}

1;

__END__

=encoding utf8

=head1 NAME

XML::Chain::Selector - selector for traversing XML::Chain

=head1 SYNOPSIS

    my $user = xc('user', xmlns => 'http://testns')->auto_indent({chars=>' 'x4})
        ->a('name', '-' => 'Johnny Thinker')
        ->a('username', '-' => 'jt')
        ->c('bio')
            ->c('div', xmlns => 'http://www.w3.org/1999/xhtml')
                ->a('h1', '-' => 'about')
                ->a('p', '-' => '...')
                ->up
            ->a('greeting', '-' => 'Hey')
            ->up
        ->a('active', '-' => '1')
        ->root;
    say $user->as_string;

Will print:

    <user xmlns="http://testns">
        <name>Johnny Thinker</name>
        <username>jt</username>
        <bio>
            <div xmlns="http://www.w3.org/1999/xhtml">
                <h1>about</h1>
                <p>...</p>
            </div>
            <greeting>Hey</greeting>
        </bio>
        <active>1</active>
    </user>

=head1 DESCRIPTION

L<XML::Chain::Selector> represents the current selection of one or more
XML nodes inside an L<XML::Chain> document. Most chained methods either
modify those nodes or return a new selector with an updated selection.

When exactly one node is selected, XML::Chain may return an
L<XML::Chain::Element> object instead, which is a subclass for the
single-element case.

=head1 CHAINED METHODS

=head2 c, append_and_select

Appends a new element to the current elements and changes the context to
them. The new element is defined by the parameters:

    $xc->c('i', class => 'icon-download icon-white')
    # <i class="icon-download icon-white"/>

The first parameter is the element name, followed by optional element
attributes.

=head2 a, append

Appends a new element to the current elements and then moves the current
selection back to the parent elements.

    xc('body')
        ->a('p', '-' => 'one')
        ->a('p', '-' => 'two');
    # <body><p>one</p><p>two</p></body>

=head2 t, append_text

Appends text to the current elements.

    xc('span')->t('some')->t(' ')->t('more text')
    # <span>some more text</span>

The first parameter is the text to append.

=head2 root

Sets the document element as the current element.

    say xc('p')
        ->t('this ')
        ->a(xc('b')->t('is'))
        ->t(' important!')
        ->root->as_string;
    # <p>this <b>is</b> important!</p>

=head2 up, parent

Traverses the current elements and replaces them with their parents.
When called on the document root element, returns the same element
unchanged (idempotent). This enables safe multichaining like
C<< ->parent->parent >> without needing to check whether you've
reached the root.

    my $root = xc('<root><child></child></root>');
    $root->parent->name eq 'root';

=head2 find

    say $xc->find('//p/b[@class="less"]')->text_content;
    say $xc->find('//xhtml:div', xhtml => 'http://www.w3.org/1999/xhtml')->count;

Looks up elements by XPath and sets them as the current elements. Optional
namespace prefixes for lookups can be specified. Any globally registered
namespace prefixes from L</reg_global_ns> can be used.

=head2 children

Sets all child elements of the current elements as the current
elements. Non-element child nodes, such as text nodes and comments, are
skipped.

=head2 first

Sets the first current element as the current element.

=head2 empty

Removes all child nodes from the current elements.

=head2 rename

    my $body = xc('bodyz')->rename('body');
    # <body/>

Renames node name(s).

=head2 attr

    my $img = xc('img')->attr('href' => '#', 'title' => 'image-title');
    # <img href="#" title="image-title"/>

    say $img->attr('title')
    # image-title

    say $img->attr('title' => undef)
    # <img href="#"/>

Gets or sets element attributes. With one argument, it returns the
attribute value; otherwise, it sets the attributes. Setting an attribute
to C<undef> removes it from the element.

=head2 each

    # rename using each
    $body->rename('body');
    $body
        ->a(xc('p.1')->t(1))
        ->a(xc('p.2')->t(2))
        ->a(xc('div')->t(3))
        ->a(xc('p.3')->t(4))
        ->each(sub { $_->rename('p') if $_->name =~ m/^p[.]/ });
    is($body, '<body><p>1</p><p>2</p><div>3</div><p>4</p></body>','rename using each()');

Loops through all selected elements and calls the callback for each one.

=head2 map_selection

    my $children = xc(\'<root><a/><b/><c/></root>')->children->map_selection(sub { $_ });
    # returns a selector with the same elements

    my $first_children = $root->find('//p')->map_selection(sub { $_->children->first });
    # returns a selector of the first child of each <p>

Applies the callback to each selected element (C<$_> is set to the element).
Returns a new selector built from all C<XML::Chain::Selector> objects returned
by the callback.  Elements for which the callback returns nothing (or a
non-selector value) are omitted from the result. The DOM is never modified.

=head2 grep_selection

    my $ps = xc(\'<body><p/><div/><p/></body>')->children->grep_selection(sub { $_->name eq 'p' });
    # $ps->count == 2

Filters the selection. Returns a new selector containing only the elements for
which the callback returns a true value (C<$_> is set to the element).
Implemented in terms of L</map_selection>.

=head2 remap

    xc('body')->a('p', i => 1)->children->remap(
        sub {
            (map {xc('e', i => $_)} 1 .. 3), $_;
        }
    )->root;
    # <body><e i="1"/><e i="2"/><e i="3"/><p i="1"/></body>

Replaces all selected elements with the elements returned by the callback.

=head2 rm, remove_and_parent

    my $pdiv = xc('base')
            ->a(xc('p')->t(1))
            ->a(xc('p')->t(2))
            ->a(xc('div')->t(3))
            ->a(xc('p')->t(4));
    my $p = $pdiv->find('//p');
    # $pdiv->find('//p[position()=3]')->rm->name eq 'base'
    # $p->count == 2     # deleted elements are skipped also in old selectors
    # <base><p>1</p><p>2</p><div>3</div></base>

Deletes current elements and returns their parent.

=head2 auto_indent

(experimental feature; useful for debugging, but it needs more testing;
works only on the element for which C<as_string> is called at that moment)

    my $simple = xc('div')
                    ->auto_indent(1)
                    ->a('div', '-' => 'in1')
                    ->a('div', '-' => 'in2')
                    ->t('in2.1')
                    ->a('div', '-' => 'in3')
    ;
    say $simple->as_string;

Will print:

    <div>
        <div>in1</div>
        <div>in2</div>
        in2.1
        <div>in3</div>
    </div>

Turns tidy/auto-indentation of document elements on or off. The default
indentation characters are tabs.

The argument can be either a true/false scalar or a hashref with
indentation options. Currently, C<{chars=>' 'x4}> sets the indentation
characters to four spaces.

=head1 CHAINED DOCUMENT METHODS

See L<XML::Chain/CHAINED DOCUMENT METHODS>.

=head1 METHODS

=head2 new

Creates a new selector object from named arguments.

=head2 current_elements

Gets or sets the internal array reference of currently selected elements.

=head2 as_string, toString

Returns a string representation of the current XML elements. Call
L<root> first to get a string representing the whole document.

    $xc->as_string
    $xc->root->as_string

=head2 as_xml_libxml

Returns the current elements as L<XML::LibXML> objects. In list context,
selectors may return multiple nodes. For the single-element case,
L<XML::Chain::Element/as_xml_libxml> returns one
L<XML::LibXML::Element> object.

=head2 text_content

Returns the text content of all current XML elements.

=head2 count / size

    say $xc->find('//b')->count;

Returns the number of current elements.

=head2 single

    my $lxml_el = $xc->find('//b')->first->as_xml_libxml;

Checks that there is exactly one current element and returns it as an
L<XML::Chain::Element> object. It throws an exception if the selection
is empty or contains more than one element.

=head2 reg_global_ns

Registers a namespace prefix on the document element so that it can be
used later in L</find> calls. The optional third argument controls
whether the namespace is activated on the root element.

    $sitemap->reg_global_ns('i' => 'http://www.google.com/schemas/sitemap-image/1.1');
    $sitemap->reg_global_ns('s' => 'http://www.sitemaps.org/schemas/sitemap/0.9');
    say $sitemap->find('/s:urlset/s:url/i:image')->count
    # 2

=head2 document_element

Returns the document root element as an L<XML::Chain::Element> object.
This is an alias for C<root>.

=head2 set_io_any

Stores C<$what, $options> for L<IO::Any> for future use with C<store>.
See L<XML::Chain/set_io_any> for details.

=head2 store

Saves the XML to the target configured via C<set_io_any>.
See L<XML::Chain/store> for details.

=head2 data

Stores and retrieves arbitrary metadata on selected elements without affecting
the XML content (jQuery-style .data() method).

    # Set data on element
    $element->data(user_id => 42);
    $element->data(status => 'active');

    # Get specific data key
    my $user_id = $element->data('user_id');

    # Get all data keys as hash
    my $all = $element->data;

    # Set on multiple elements
    $elements->data(processed => 1);

Calling with no arguments returns a hash reference of all stored data for the
first element in the selection.

Calling with one argument returns the value for that key in the first element.

Calling with two or more arguments sets the key/value on all elements in the
selection and returns C<$self> for chaining.

B<Important:> Data storage is tied to element identity within a document. If
an element is copied or imported to another document, the data does B<not>
survive the operation (the new element will have an empty data store).

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT & LICENSE

Copyright 2017 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
