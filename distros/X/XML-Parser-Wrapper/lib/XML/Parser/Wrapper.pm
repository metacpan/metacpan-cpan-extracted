# -*-perl-*-
# Creation date: 2005-04-23 22:39:14
# Authors: Don
# $Revision: 1599 $
#
# Copyright (c) 2005-2010 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

XML::Parser::Wrapper - A simple object wrapper around XML::Parser

=cut

use strict;
use XML::Parser ();

use XML::Parser::Wrapper::SAXHandler;

{   package XML::Parser::Wrapper;

    use vars qw($VERSION);
    
    $VERSION = '0.15';

    my %i_data;

=pod

=head1 VERSION

 0.14

=cut

=head1 SYNOPSIS

 use XML::Parser::Wrapper;
 
 my $xml = qq{<foo><head id="a">Hello World!</head><head2><test_tag id="b"/></head2></foo>};
 my $root = XML::Parser::Wrapper->new($xml);
 
 my $root2 = XML::Parser::Wrapper->new({ file => '/tmp/test.xml' });
 
 my $parser = XML::Parser::Wrapper->new;
 my $root3 = $parser->parse({ file => '/tmp/test.xml' });
 
 my $root4 = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                    handler => $handler,
                                                    start_tag => 'stuff',
                                                    # start_depth => 2,
                                                  }, $xml);
 
 my $root_tag_name = $root->name;
 my $roots_children = $root->elements;
 
 foreach my $element (@$roots_children) {
     if ($element->name eq 'head') {
         my $id = $element->attr('id');
         my $hello_world_text = $element->text; # eq "Hello World!"
     }
 }
 
 my $head_element = $root->first_element('head2');
 my $head_elements = $root->elements('head2');
 my $test = $root->element('head2')->first_element('test_tag');
 
 my $root = XML::Parser::Wrapper->new_doc('root_tag', { root => 'attr' });
 
 my $new_element = $root->add_kid('test4', { attr1 => 'val1' });
 
 my $kid = $root->update_kid('root_child', { attr2 => 'stuff2' }, 'blah');
 $kid->update_node({ new_attr => 'new_stuff' });
 
 $new_element->add_kid('child', { myattr => 'stuff' }, 'bleh');
 
 my $another_element = $root->new_element('foo', { bar => '1' }, 'test');
 $root->add_kid($another_element);
 
 my $new_xml = $root->to_xml;

 my $doctype_info = $root->get_doctype;

 my $xml_decl_info = $root->get_xml_decl;

=head1 DESCRIPTION

XML::Parser::Wrapper provides a simple object around XML::Parser
to make it more convenient to deal with the parse tree returned
by XML::Parser.

For a list of changes in recent versions, see the documentation
for L<XML::Parser::Wrapper::Changes>.


=head1 METHODS

=head2 C<new()>, C<new($xml)>, C<new({ file =E<gt> $filename })>

Calls XML::Parser to parse the given XML and returns a new
XML::Parser::Wrapper object using the parse tree output from
XML::Parser.

If no parameters are passed, a reusable object is returned
-- see the parse() method.

=cut

    # Takes the 'Tree' style output from XML::Parser and wraps in in objects.
    # A parse tree looks like the following:
    #
    #          [foo, [{}, head, [{id => "a"}, 0, "Hello ",  em, [{}, 0, "there"]],
    #                      bar, [         {}, 0, "Howdy",  ref, [{}]],
    #                        0, "do"
    #                ]
    #          ]
    sub new {
        my $proto = shift;
        my $self = $proto->_new;

        unless (scalar(@_) >= 1) {
            return $self;
        }

        return $self->parse(@_);        
    }

    # adapted from refaddr in Scalar::Util
    sub refaddr {
        my $obj = shift;
        my $pkg = ref($obj) or return undef;
        
        bless $obj, 'XML::Parser::Wrapper::Fake';
        
        my $i = int($obj);
        
        bless $obj, $pkg;
        
        return $i . '';
    }

    sub _doctype_handler {
        my ($self, $orig_handler, $expat, $name, $sysid, $pubid, $internal) = @_;

        $self->{_doctype} = { name => $name, sysid => $sysid,
                              pubid => $pubid, internal => $internal,
                            };

        return 0 unless defined $orig_handler;
        return $orig_handler->($expat, $name, $sysid, $pubid, $internal);
    }

    sub _xml_decl_handler {
        my ($self, $orig_handler, $expat, $version, $encoding, $standalone) = @_;

        $self->{_xml_decl} = { version => $version, encoding => $encoding,
                               standalone => $standalone,
                             };
        
        return 0 unless defined $orig_handler;
        return $orig_handler->($orig_handler, $expat, $version, $encoding, $standalone);
    }
    
    sub _new {
        my $class = shift;
        my $parser = XML::Parser->new(Style => 'Tree');

        my $self = bless { parser => $parser }, ref($class) || $class;

        # FIXME: use $parser->setHandlers() here to set handlers for doctype, etc.
        #        use the return values to get reference to handlers to call after
        #        so that the Tree style works properly (e.g., knows about any declared entities)
        # Doctype:  (Expat, Name, Sysid, Pubid, Internal)
        # XMLDecl: (Expat, Version, Encoding, Standalone)

        my $orig_doctype_handler;
        my $orig_xml_decl_handler;
        
        my $dt_h = sub { $self->_doctype_handler($orig_xml_decl_handler, @_) };
        my $xd_h = sub { $self->_xml_decl_handler($orig_xml_decl_handler, @_) };
        my %old_handlers = $parser->setHandlers(Doctype => $dt_h,
                                                XMLDecl => $xd_h,
                                               );

        $orig_doctype_handler = $old_handlers{Doctype};
        $orig_xml_decl_handler = $old_handlers{XMLDecl};
        
#         use Data::Dumper;
#         print STDERR Data::Dumper->Dump([ \%old_handlers ], [ 'old_handlers' ]) . "\n\n";
#         exit 0;

        return $self;
    }

=pod

=head2 C<new_sax_parser(\%params)>, C<new_sax_parser(\%params, $xml)>, C<new_sax_parser(\%params, { file =E<gt> $filename })>

Experimental support for SAX parsers based on XML::SAX::Base.  Valid parameters are

=head3 class

SAX parser class (defaults to XML::LibXML::SAX)

=head3 start_tag

SAX tag name starting the section you are looking for if stream parsing.

=head3 handler

Handler function to call when stream parsing.

=head3 start_depth

Use this option for picking up sections that occur inside another
section with the same tag name.  E.g., if you want to get the
inside "foo" section in this example:

=for pod2rst next-code-block: xml

 <doc><foo><bar><foo>here</foo></bar></foo></doc>

instead of the one at the top level, set start_depth to 2.  This
is the number of times your start_tag occurs in the hierarchy
before you get to the section you want (not the tag depth).

=cut
    sub new_sax_parser {
        my $class = shift;
        my $parse_spec = shift || { };

        my $parser_class = $parse_spec->{class} || 'XML::LibXML::SAX';
        my $start_tag = $parse_spec->{start_tag};
        my $user_cb = $parse_spec->{handler};
        my $start_depth = $parse_spec->{start_depth};

        my $self = bless { parser_class => $parser_class, handler => $user_cb,
                           start_tag => $start_tag,
                         },
            ref($class) || $class;

        eval "require $parser_class;";

        my $sax_handler = XML::Parser::Wrapper::SAXHandler->new({ start_tag => $start_tag,
                                                                  handler => $user_cb,
                                                                  start_depth => $start_depth,
                                                                });
        $self->{parser} = $parser_class->new({ Handler => $sax_handler,
                                               # DeclHandler => $sax_handler,
                                             });

        # DTDHandler => $sax_handler,

        $self->{sax_handler} = $sax_handler;

        unless (scalar(@_) >= 1) {
            return $self;
        }

        return $self->parse(@_);
    }

=pod

=head2 C<parse($xml)>, C<parse({ file =E<gt> $filename })>

Parses the given XML and returns a new XML::Parser::Wrapper
object using the parse tree output from XML::Parser.

=cut
    sub parse {
        my $self = shift;
        my $arg = shift;

        my $parser = $self->{parser};

        my $tree = [];
        if (ref($arg) eq 'HASH') {
            if (exists($arg->{file})) {
                if ($self->{sax_handler}) {
                    if (UNIVERSAL::isa($arg->{file}, 'GLOB') and *{$arg->{file}}{IO}) {
                        $self->{parser}->parse(Source => { ByteStream => $arg->{file} });
                    }
                    else {
                        $self->{parser}->parse(Source => { SystemId => $arg->{file} });
                    }
                    
                    $tree = $self->{sax_handler}->get_tree;
                }
                else {
                    $tree = $parser->parsefile($arg->{file});
                }
            }
        } else {
            if ($self->{sax_handler}) {
                if (UNIVERSAL::isa($arg, 'GLOB')) {
                    $self->{parser}->parse(Source => { ByteStream => $arg });
                }
                else {
                    $self->{parser}->parse(Source => { String => $arg });
                }
                $tree = $self->{sax_handler}->get_tree;
            }
            else {
                $tree = $parser->parse($arg);
            }
        }

        return undef unless defined($tree) and ref($tree);
        
        my $obj = bless $tree, ref($self);

        my $k = refaddr($obj);
        $i_data{$k} = { doctype => $self->{_doctype}, xmldecl => $self->{_xml_decl} };
        
        return $obj;
    }

=pod

=head2 C<get_xml_decl()>

Returns information about the XML declaration at the beginning of
the document.  E.g., for the declaration

=for pod2rst next-code-block: xml

 <?xml version="1.0" encoding="utf-8"?>

The return value is

    {
     'version' => '1.0',
     'standalone' => undef,
     'encoding' => 'utf-8'
    }


B<NOTE:> This does not work for the SAX parser interface.


=cut
    sub get_xml_decl {
        my ($self) = @_;

        my $k = refaddr($self);
        my $data = $i_data{$k};

        if ($data) {
            return $data->{xmldecl};
        }
        return undef;
    }

=pod

=head2 C<get_doctype()>

Returns information about the doctype declaration.  E.g., for the declaration

=for pod2rst next-code-block: xml

 <!DOCTYPE greeting SYSTEM "hello.dtd">

The return value is

    {
     'pubid' => undef,
     'sysid' => 'hello.dtd',
     'name' => 'greeting',
     'internal' => ''
    }

B<NOTE:> This does not work for the SAX parser interface.


=cut
    sub get_doctype {
        my ($self) = @_;

        my $k = refaddr($self);
        my $data = $i_data{$k};

        if ($data) {
            return $data->{doctype};
        }
        return undef;
    }

    sub _new_element {
        my $proto = shift;
        my $tree = shift || [];

        return bless $tree, ref($proto) || $proto;
    }

=pod

=head2 C<name()>

Returns the name of the element represented by this object.

Aliases: tag(), getName(), getTag()

=cut
    sub tag {
        my $tag = shift()->[0];
        return '' if $tag eq '0';
        return $tag;
    }
    *name = \&tag;
    *getTag = \&tag;
    *getName = \&tag;

=pod

=head2 C<is_text()>

Returns a true value if this element is a text element, false
otherwise.

Aliases: isText()

=cut
    sub is_text {
        my $self = shift;
        if (@$self and defined($self->[0])) {
            return $self->[0] eq '0';
        }
        return;

        # return $self->[0] eq '0';
    }
    *isText = \&is_text;

=pod

=head2 C<text()>

If this element is a text element, the text is returned.
Otherwise, return the text from the first child text element, or
undef if there is not one.

Aliases: content(), getText(), getContent()

=cut
    sub text {
        my $self = shift;
        if ($self->is_text) {
            return $self->[1];
        } else {
            my $kids = $self->kids;
            foreach my $kid (@$kids) {
                return $kid->text if $kid->is_text;
            }
            return undef;
        }
    }
    *content = \&text;
    *contents = \&text;
    *getText = \&text;
    *getContent = \&text;
    *getContents = \&text;

=pod

=head2 C<html()>

Like text(), except HTML-escape the text (escape &, <, >, and ")
before returning it.

Aliases: content_html(), getContentHtml()

=cut
    sub html {
        my $self = shift;

        return $self->escape_html($self->text);
    }
    *content_html = \&html;
    *getContentHtml = \&html;

=pod

=head2 C<xml()>

Like text(), except XML-escape the text (escape &, <, >, and ")
before returning it.

Aliases: content_xml(), getContentXml()

=cut
    sub xml {
        my $self = shift;

        return $self->escape_xml_attr($self->text);
    }
    *content_xml = \&html;
    *getContentXml = \&html;

=pod

=head2 C<to_xml(\%options)>

Converts the node back to XML.  The ordering of attributes may
not be the same as in the original XML, and CDATA sections may
become plain text elements, or vice versa.  This assumes the data
is encoded in utf-8.

Valid options

=head3 pretty

If pretty is a true value, then whitespace is added to the output
to make it more human-readable.

=head3 cdata

If cdata is defined, any text nodes with length greater than
cdata are output as a CDATA section, unless it contains "]]>", in
which case the text is XML escaped.

Aliases: toXml()

=head3 decl

If a true value, output an XML declaration before outputing the
converted document, i.e.,

=for pod2rst next-code-block: xml

 <?xml version="1.0" encoding="UTF-8"?>

=cut
    sub to_xml {
        my ($self, $options) = @_;

        unless ($options and ref($options) and UNIVERSAL::isa($options, 'HASH')) {
            $options = { };
        }

        if ($options->{decl}) {
            my $xml = qq{<?xml version="1.0" encoding="UTF-8"?>};
            if ($options->{pretty}) {
                $xml .= "\n";
            }
            
            $xml .= $self->_to_xml(0, $options, 0);

            return $xml;
        }
        
        return $self->_to_xml(0, $options, 0);
    }
    
    sub _to_xml {
        my ($self, $level, $options, $index) = @_;

        unless ($options and ref($options) and UNIVERSAL::isa($options, 'HASH')) {
            $options = { };
        }

        if ($self->is_text) {
            my $text = $self->text;

            if (defined $options->{cdata}) {
                if (length($text) >= $options->{cdata}) {
                    unless (index($text, ']]>') > -1) {
                        return '<![CDATA[' . $text . ']]>';
                    }
                }
            }
            
            return $self->escape_xml_body($text);
        }

        my $pretty = $options->{pretty};

        my $attributes = $self->_get_attrs;
        my $name = $self->name;
        my $kids = $self->kids;

        my $indent = $pretty ? ('    ' x $level) : '';
        my $eol = $pretty ? "\n" : '';

        my $xml = '';

        if ($pretty and $level >= 1) {
            $xml .= $eol if $index == 0;
        }
        
        $xml .= qq{$indent<$name};
        if ($attributes and %$attributes) {
            my @pairs;
            foreach my $key (sort keys %$attributes) {
                my $val = $attributes->{$key} . '';
                
                push @pairs, $key . '=' . '"' . $self->escape_xml_attr($val) . '"';
            }
            $xml .= ' ' . join(' ', @pairs);
        }
        
        if ($kids and @$kids) {
            my $cnt = 0;
            $xml .= '>' . join('', map { $_->_to_xml($level + 1, $options, $cnt++) } @$kids);
            $xml .= $indent if scalar(@$kids) > 1;
            $xml .= "</$name>$eol";
        }
        else {
            $xml .= "/>$eol";
        }
    }
    *toXml = \&to_xml;


sub to_jsonml {
    my ($self) = @_;

    return $self->_to_jsonml;
}

sub _to_jsonml {
    my ($self) = @_;

    if ($self->is_text) {
        return $self->_quote_json_str($self->text);
    }

    my $name = $self->name;
    my $attrs = $self->_get_attrs;
    my $kids = $self->kids;

    my $json = '[' . $self->_quote_json_str($name);
    if ($attrs and %$attrs) {
        my @keys = sort keys %$attrs;
        my @pairs =
            map { $self->_quote_json_str($_) . ':' . $self->_quote_json_str($attrs->{$_}) } @keys;
        my $attr_str = '{' . join(',', @pairs) . '}';
        $json .= ',' . $attr_str;
    }

    if ($kids and @$kids) {
        foreach my $kid (@$kids) {
            $json .= ',' . $kid->_to_jsonml;
        }
    }

    $json .= ']';

    return $json;
}

sub _quote_json_str {
    my ($self, $str) = @_;

    $str =~ s/\\/\\\\/g;
    $str =~ s/\"/\\\"/g;
    $str =~ s/\x00/\\u0000/g;

    # FIXME: do tabs, etc.
    $str =~ s/\x08/\\b/g;
    $str =~ s/\x09/\\t/g;
    $str =~ s/\x0a/\\n/g;
    $str =~ s/\x0c/\\f/g;
    $str =~ s/\x0d/\\r/g;
    $str =~ s/([\x00-\x1e])/sprintf("\\u%04x", ord($1))/eg;
    
    return '"' . $str . '"';
}

=pod

=head2 C<attributes()>, C<attributes($name1, $name2, ...)>

If no arguments are given, returns a hash of attributes for this
element.  If arguments are present, an array of corresponding
attribute values is returned.  Returns an array in array context
and an array reference if called in scalar context.

E.g., for

=for pod2rst next-code-block: xml

     <field name="foo" id="42">bar</field>

use this to get the attributes:

     my ($name, $id) = $element->attributes('name', 'id');

Aliases: attrs(), getAttributes(), getAttrs()

=cut
    sub attributes {
        my $self = shift;
        my $val = $self->[1];

        if (ref($val) eq 'ARRAY' and scalar(@$val) > 0) {
            my $attr = $val->[0];
            if (@_) {
                my @keys;
                if (ref($_[0]) eq 'ARRAY') {
                    @keys = @{$_[0]};
                } else {
                    @keys = @_;
                }
                return wantarray ? @$attr{@keys} : [ @$attr{@keys} ];
            }
            return wantarray ? %$attr : $attr;
        } else {
            return {};
        }
    }
    *attrs = \&attributes;
    *getAttributes = \&attributes;
    *getAttrs = \&attributes;
    *get_attributes = \&attributes;
    *get_attrs = \&attributes;

    sub _get_attrs {
        my $self = shift;
        my $val = $self->[1];

        if (ref($val) eq 'ARRAY' and scalar(@$val) > 0) {
            my $attr = $val->[0];
            if (@_) {
                my @keys;
                if (ref($_[0]) eq 'ARRAY') {
                    @keys = @{$_[0]};
                } else {
                    @keys = @_;
                }

                return wantarray ? @$attr{@keys} : [ @$attr{@keys} ];
            }

            return wantarray ? %$attr : $attr;
        } else {
            return {};
        }
    }

=pod

=head2 C<attribute($name)>

Similar to attributes(), but only returns one value.

Aliases: attr(), getAttribute(), getAttr()

=cut
    sub attribute {
        my ($self, $attr_name) = @_;
        my $val = $self->attributes()->{$attr_name};

        return undef unless defined $val;

        return $val . '';
    }
    *attr = \&attribute;
    *getAttribute = \&attribute;
    *getAttr = \&attribute;

    sub attribute_str {
        my ($self, $attr_name) = @_;

        my $attr = $self->attribute($attr_name);
        if ($attr and ref($attr) eq 'HASH') {
            return $attr->{Value};
        }
        else {
            return $attr;
        }
    }

=pod

=head2 C<elements()>, C<elements($element_name)>

Returns an array of child elements.  If $element_name is passed,
a list of child elements with that name is returned.

Aliases: getElements(), kids(), getKids(), children(), getChildren()

=cut
    sub kids {
        my $self = shift;
        my $tag = shift;
        
        my $val = $self->[1];
        my $i = 1;
        my $kids = [];
        if (ref($val) eq 'ARRAY') {
            my $stop = $#$val;
            while ($i < $stop) {
                my $this_tag = $val->[$i];
                if (defined($tag)) {
                    push @$kids, XML::Parser::Wrapper->_new_element([ $this_tag, $val->[$i + 1] ])
                        if $this_tag eq $tag;
                } else {
                    push @$kids, XML::Parser::Wrapper->_new_element([ $this_tag, $val->[$i + 1] ]);
                }
                
                $i += 2;
            }
        }
        
        return wantarray ? @$kids : $kids;
    }
    *elements = \&kids;
    *getKids = \&kids;
    *getElements = \&kids;
    *children = \&kids;
    *getChildren = \&kids;

=pod

=head2 C<first_element()>, C<first_element($element_name)>

Returns the first child element of this element.  If
$element_name is passed, returns the first child element with
that name is returned.

Aliases: getFirstElement(), kid(), first_kid()

=cut
    sub kid {
        my $self = shift;
        my $tag = shift;
        
        my $val = $self->[1];
        if (ref($val) eq 'ARRAY') {
            if (defined($tag)) {
                my $i = 1;
                my $stop = $#$val;
                while ($i < $stop) {
                    my $kid;
                    my $this_tag = $val->[$i];
                    if ($this_tag eq $tag) {
                        return XML::Parser::Wrapper->_new_element([ $this_tag, $val->[$i + 1] ]);
                    }
                    $i += 2;
                }
                return undef;
            } else {
                return XML::Parser::Wrapper->_new_element([ $val->[1], $val->[2] ]);
            }
        } else {
            return $val;
        }
    }
    *element = \&kid;
    *first_element = \&kid;
    *getFirstElement = \&kid;
    *first_kid = \&kid;

=pod

=head2 C<first_element_if($element_name)>

Like first_element(), except if there is no corresponding child,
return an object that will work instead of undef.  This allows
for reliable chaining, e.g.

 my $class = $root->kid_if('field')->kid_if('field')->kid_if('element')
              ->kid_if('field')->attribute('class');

Aliases: getFirstElementIf(), kidIf(), first_kid_if()

=cut
    sub kid_if {
        my $self = shift;
        my $tag = shift;
        my $kid = $self->kid($tag);

        return $kid if defined $kid;

        return XML::Parser::Wrapper->_new_element([ undef, [ {} ] ]);
    }
    *kidIf = \&kid_if;
    *first_element_if = \&kid_if;
    *first_kid_if = \&kid_if;
    *getFirstElementIf = \&kid_if;


=pod

=head2 C<new_doc($root_tag_name, \%attr)>

Create a new XML document.

=cut
    sub new_document {
        my ($class, $root_tag, $attr) = @_;

        $attr = { } unless $attr;

        my $data = [$root_tag, [ { %$attr } ] ];
        
        return bless $data, ref($class) || $class;
    }
    *new_doc = \&new_document;

=pod

=head2 C<new_element($tag_name, \%attr, $text_val)>

Create a new XML element object.  If $text_val is defined, a
child text node will be created.

=cut
    sub new_element {
        my ($class, $tag_name, $attr, $val) = @_;

        unless (defined($tag_name)) {
            return undef;
        }

        my $attr_to_add;
        if ($attr and %$attr) {
            $attr_to_add = $attr;
        }
        else {
            $attr_to_add = { };
        }

        my $stuff = [ $attr_to_add ];
        if (defined($val)) {
            push @$stuff, '0', $val;
        }

        return $class->_new_element([ $tag_name, $stuff ]);
    }

    sub new_from_tree {
        my $class = shift;
        my $tree = shift;
        
        my $obj = bless $tree, ref($class) || $class;
        
        return $obj;
    }

=pod

=head2 C<add_kid($tag_name, \%attributes, $text_value)>, C<add_kid($element_obj)>

Adds a child to the current node.  If $text_value is defined, it
will be used as the text between the opening and closing tags.
The return value is the newly created node (XML::Parser::Wrapper
object) that can then in turn have child nodes added to it.
This is useful for loading and XML file, adding an element, then
writing the modified XML back out.  Note that all parameters
must be valid UTF-8.

If the first argument is an element object created with the
new_element() method, that element will be added as a child.

    my $root = XML::Parser::Wrapper->new($input);
 
    my $new_element = $root->add_kid('test4', { attr1 => 'val1' });
    $new_element->add_kid('child', { myattr => 'stuff' }, 'bleh');
 
    my $foo = $root->new_element('foo', { bar => 1 }, 'some text');
    $new_element->add_kid($foo);

Aliases: addKid(), add_child, addChild()

=cut
    sub add_kid {
        my ($self, $tag_name, $attr, $val) = @_;

        unless (defined($tag_name)) {
            return undef;
        }

        if (ref($tag_name) and UNIVERSAL::isa($tag_name, 'XML::Parser::Wrapper')) {
            push @{$self->[1]}, @$tag_name;
            return $tag_name;
        }

        my $new_element = $self->new_element($tag_name, $attr, $val);
        push @{$self->[1]}, @$new_element;

        return $new_element;

    }
    *addChild = \&add_kid;
    *add_child = \&add_kid;
    *addKid = \&add_kid;

=pod

=head2 C<set_attr($name, $val)>

Set the value of the attribute given by $name to $val for the
element.

=cut
    sub set_attr {
        my ($self, $name, $val) = @_;

        $self->[1][0]->{$name} = $val;

        return $val;
    }

=pod

=head2 C<set_attrs(\%attrs)>

Convenience method that calls set_attr() for each key/value pair
in %attrs.

=cut
    sub set_attrs {
        my ($self, $attrs) = @_;

        return undef unless $attrs;

        return 0 unless %$attrs;

        my $cnt = 0;
        foreach my $k (keys %$attrs) {
            $self->set_attr($k, $attrs->{$k});
            $cnt++;
        }

        return $cnt;
    }

=pod

=head2 C<replace_attrs(\%attrs)>

Replaces all attributes for the element with the provided ones.
That is, the old attributes are all removed and the new ones are
added.

=cut
    sub replace_attrs {
        my ($self, $attrs) = @_;

        return undef unless $attrs;
        
        my %new_attrs = %$attrs;

        $self->[1][0] = \%new_attrs;

        return \%new_attrs;
    }

=pod

=head2 C<remove_kids()>

Removes all child nodes (include text nodes) from this element.

=cut
    sub remove_kids {
        my ($self) = @_;

        @{$self->[1]} = ($self->[1][0]);

        return 1;
    }

=pod

=head2 C<remove_kid($name)>

Removes the first child node with name $name.

=cut
    sub remove_kid {
        my ($self, $name_to_remove) = @_;

        return undef unless defined $name_to_remove;

        my $index = 1;
        my $found = 0;
        my $children = $self->[1];
        if (scalar(@$children) > 1) {
            while (not $found and $index < scalar(@$children)) {
                my $name = $children->[$index];
                if ($name eq $name_to_remove) {
                    $found = 1;
                }
                else {
                    $index += 2;
                }
            }
        }

        if ($found) {
            splice(@$children, $index, 2);

            return 1;
        }

        return 0;
    }

=pod

=head2 C<set_text($text_val)>

Sets the first text child node to $text_val.  If there is no text
child node, one is created.  If $text_val is undef, the first
text child node is removed.

=cut
    sub set_text {
        my ($self, $text_val) = @_;

        my $index = 1;
        my $found = 0;
        my $children = $self->[1];
        if (scalar(@$children) > 1) {
            while (not $found and $index < scalar(@$children)) {
                my $name = $children->[$index];
                if ($name eq '0') {
                    $found = 1;
                }
                else {
                    $index += 2;
                }
            }
        }

        unless (defined($text_val)) {
            return 0 unless $found;

            splice(@$children, $index, 2);

            return 1;
        }

        if ($found) {
            $children->[$index + 1] = $text_val;
        }
        else {
            push @$children, '0', $text_val . '';
        }

        return 1;
    }

=pod

=head2 C<update_node(\%attrs, $text_val)>

Updates the node, setting the attributes to the ones provided in
%attrs, and sets the text child node to $text_val if it is
defined.  Note that this removes all child nodes.

Aliases: updateNode()

=cut
    sub update_node {
        my $self = shift;
        my $attrs = shift;
        my $text_val = shift;

        my $stuff = [ $attrs ];
        if (defined($text_val)) {
            push @$stuff, '0', $text_val;
        }

        @{$self->[1]} = @$stuff;

        return $self;
    }
    *updateNode = \&update_node;

=pod

=head2 C<update_kid($tag_name, \%attrs, $text_val)>

Calls update_node() on the first child node with name $tag_name
if it exists.  If there is no such child node, one is created by
calling add_kid().

Aliases: updateKid(), update_child(), updateChild()

=cut
    sub update_kid {
        my ($self, $tag_name, $attrs, $text_val) = @_;

        my $kid = $self->kid($tag_name);
        if ($kid) {
            $kid->update_node($attrs, $text_val);
            return $kid;
        }

        $kid = $self->add_kid($tag_name, $attrs, $text_val);
        return $kid;
    }
    *updateKid = \&update_kid;
    *update_child = \&update_kid;
    *updateChild = \&update_kid;

    sub escape_html {
        my ($self, $text) = @_;
        return undef unless defined $text;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&quot;/g;

        return $text;
    }

#     our $Escape_Map = { '&' => '&amp;',
#                         '<' => '&lt;',
#                         '>' => '&gt;',
#                         '"' => '&quot;',
#                         "'" => '&#39;',
#                       };

    sub escape_xml {
        my ($self, $text) = @_;
        return undef unless defined $text;

        # FIXME: benchmark this and test fully
#         $text =~ s/([&<>"'])/$Escape_Map->{$1}/eg;
#         return $text;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&#34;/g;
        $text =~ s/\'/\&#39;/g;

        return $text;
    }

    sub escape_xml_attr {
        my ($self, $text) = @_;
        return undef unless defined $text;

        # FIXME: benchmark this and test fully
#         $text =~ s/([&<>"'])/$Escape_Map->{$1}/eg;
#         return $text;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&#34;/g;
        $text =~ s/\'/\&#39;/g;

        return $text;
    }

    sub escape_xml_body {
        my ($self, $text) = @_;
        return undef unless defined $text;

        # FIXME: benchmark this and test fully
#         $text =~ s/([&<>"'])/$Escape_Map->{$1}/eg;
#         return $text;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;

        return $text;
    }


=pod

=head2 C<simple_data()>

Assume a data structure of hashes, arrays, and strings are
represented in the xml with no attributes.  Return the data
structure, leaving out the root tag.

=cut
    # Assume a data structure of hashes, arrays, and strings are
    # represented in the xml with no attributes.  Return the data
    # structure, leaving out the root tag.
    sub simple_data {
        my $self = shift;

        return _convert_xml_node_to_perl($self);        
    }

    sub _convert_xml_node_to_perl {
        my $node = shift;

        my $new_data;
        if ($node->is_text) {
            $new_data = $node->text;
        }
        else {
            $new_data = {};
            my $ignore_whitespace_kids;
            my $kids = $node->kids;
            my $attr = $node->attributes;

            if (scalar(@$kids) == 0) {
                return ($attr and %$attr) ? { %$attr } : undef;
            }
            elsif (scalar(@$kids) == 1) {
                if ($kids->[0]->is_text) {
                    return $kids->[0]->text;
                }
            }
            else {
                $ignore_whitespace_kids = 1;
            }

            foreach my $kid (@$kids) {
                if ($ignore_whitespace_kids and $kid->is_text and $kid->text =~ /^\s*$/) {
                    next;
                }

                my $kid_data = _convert_xml_node_to_perl($kid);
                my $node_name = $kid->name;
                if (exists($new_data->{$node_name})) {
                    unless (ref($new_data->{$node_name}) eq 'ARRAY') {
                        $new_data->{$node_name} = [ $new_data->{$node_name} ];
                    }
                    push @{$new_data->{$node_name}}, $kid_data
                }
                else {
                    $new_data->{$node_name} = $kid_data;
                }
            }

        }

        return $new_data;
    }

=pod

=head2 C<dump_simple_data($data)>

The reverse of simple_data() -- return xml representing the data
structure passed.

=cut
    # the reverse of simple_data() -- return xml representing the data structure provided
    sub dump_simple_data {
        my $self = shift;
        my $data = shift;

        my $xml = '';
        if (ref($data) eq 'ARRAY') {
            foreach my $element (@$data) {
                $xml .= $self->dump_simple_data($element);
            }
        }
        elsif (ref($data) eq 'HASH') {
            foreach my $key (keys %$data) {
                if (ref($data->{$key}) eq 'ARRAY') {
                    foreach my $element ( @{$data->{$key}} ) {
                        $xml .= '<' . $key . '>' . $self->dump_simple_data($element)
                            . '</' . $key . '>';
                    }
                }
                else {
                    $xml .= '<' . $key . '>' . $self->dump_simple_data($data->{$key})
                        . '</' . $key . '>';
                }
            }
        }
        else {
            return $self->escape_xml_body($data);
        }

        return $xml;
    }

    sub DESTROY {
        my ($self) = @_;
        
        delete $i_data{refaddr($self)};
        
        return 1;
    }

}


{
    package XML::Parser::Wrapper::AttributeVal;

    use overload '""' => \&as_string;

    sub new {
        my ($class, $val) = @_;

        return bless { v => $val }, ref($class) || $class;
    }

    sub as_string {
        my ($self) = @_;

        my $val = $self->{v};
        
        if ($val and ref($val) and UNIVERSAL::isa($val, 'HASH')) {
            return $val->{Value};
        }
        else {
            return $val;
        }
    }
}

1;

__END__

=pod


=head1 AUTHOR

=over 4

=item Don Owens <don@regexguy.com>

=back

=head1 CONTRIBUTORS

=over 4

=item David Bushong

=back

=head1 COPYRIGHT

Copyright (c) 2003-2010 Don Owens

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl
itself.

=head1 SEE ALSO

L<XML::Parser>

=cut
