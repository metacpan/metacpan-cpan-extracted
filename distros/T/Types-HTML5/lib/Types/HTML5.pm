use 5.008006;
use strict;
use warnings;

package Types::HTML5;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Type::Utils ();
use Type::Library -base;
use Types::Standard -types;
use Types::Path::Tiny -types;
use HTML5::DOM ();
use XML::LibXML ();

our %EXPORT_TAGS;
$EXPORT_TAGS{converters} = [
	our @EXPORT_OK = qw( html_to_xml xml_to_html str_to_html str_to_xml )
];

sub html_to_xml;
sub xml_to_html;

*xml_to_html = Type::Utils::compile_match_on_type(
	InstanceOf['XML::LibXML::Comment'] => q{
		Types::HTML5::_create_comment($_->data);
	},
	InstanceOf['XML::LibXML::Text'] => q{
		Types::HTML5::_create_text_node($_->data);
	},
	InstanceOf['XML::LibXML::Element'] => q{
		my $old = $_;
		my $new = Types::HTML5::_create_element($old->nodeName, {%$old});
		for my $child (@{ $old->childNodes }) {
			$new->appendChild(Types::HTML5::xml_to_html($child));
		}
		$new;
	},
	InstanceOf['XML::LibXML::Document'] => q{
		my $old  = $_;
		my $new  = Types::HTML5::_create_tree();
		my $root = $new->root;
		for my $child (@{ $root->childNodes }) {
			$root->removeChild($child);
		}
		for my $child (@{ $old->documentElement->childNodes }) {
			$root->appendChild(Types::HTML5::xml_to_html($child));
		}
		$root->attr({%{$old->documentElement}});
		$new;
	},
	Any() => q{
		require Carp;
		Carp::croak("dunno");
	}
);

*html_to_xml = Type::Utils::compile_match_on_type(
	InstanceOf['HTML5::DOM::Comment'] => q{
		"XML::LibXML::Comment"->new($_->text);
	},
	InstanceOf['HTML5::DOM::Text'] => q{
		"XML::LibXML::Text"->new($_->text);
	},
	InstanceOf['HTML5::DOM::Element'] => q{
		my $old = $_;
		my $new = XML::LibXML::Element->new($old->tag);
		for my $child (@{ $old->childNodes->array }) {
			$new->appendChild(Types::HTML5::html_to_xml($child));
		}
		%$new = %{ $old->attr };
		$new;
	},
	InstanceOf['HTML5::DOM::Tree'] => q{
		my $old = $_;
		my $new = XML::LibXML::Document->new;
		$new->setEncoding($old->encoding);
		$new->setDocumentElement(Types::HTML5::html_to_xml($old->root));
		$new;
	},
	InstanceOf['HTML5::DOM::Document'] => q{
		my $old = $_;
		my ($root) = grep $_->isa('HTML5::DOM::Element'), @{ $old->childNodes->array };
		my $new = XML::LibXML::Document->new;
		$new->setDocumentElement(Types::HTML5::html_to_xml($root));
		$new;
	},
	Any() => q{
		require Carp;
		Carp::croak("dunno");
	}
);

{
	my ($xml_parser, $html_parser);
	
	sub set_html_parser {
		my $class = shift;
		$html_parser = Object->( shift );
		$class;
	}
	
	sub set_xml_parser {
		my $class = shift;
		$xml_parser = Object->( shift );
		$class;
	}
	
	sub str_to_xml {
		my $string = Str->( @_ ? shift : $_  );
		
		$xml_parser ||= XML::LibXML->new;
		my $xml = eval { $xml_parser->parse_string($string) };
		return $xml if $xml;
		
		$html_parser ||= HTML5::DOM->new;
		html_to_xml($html_parser->parse($string));
	}
	
	sub str_to_html {
		my $string = Str->( @_ ? shift : $_  );
		
		$xml_parser ||= XML::LibXML->new;
		my $xml = eval { $xml_parser->parse_string($string) };
		return xml_to_html($xml) if $xml;
		
		$html_parser ||= HTML5::DOM->new;
		$html_parser->parse($string);
	}
	
	my $dummy_tree;
	
	sub _create_comment {
		$dummy_tree ||= $html_parser->parse('<html>');
		$dummy_tree->createComment($_[0]);
	}
	
	sub _create_text_node {
		$dummy_tree ||= $html_parser->parse('<html>');
		$dummy_tree->createTextNode($_[0]);
	}
	
	sub _create_element {
		my ($tag, $attrs) = @_;
		$dummy_tree ||= $html_parser->parse('<html>');
		my $e = $dummy_tree->createElement($tag);
		$e->attr($attrs) if ref $attrs;
		$e;
	}
	
	sub _create_document {
		$html_parser ||= HTML5::DOM->new;
		$html_parser->parse('<html>')->document;
	}
	
	sub _create_tree {
		$html_parser ||= HTML5::DOM->new;
		$html_parser->parse('<html>');
	}
}

my $meta = __PACKAGE__->meta;

$meta->add_type(
	name      => 'XmlText',
	parent    => InstanceOf['XML::LibXML::Text'],
)->coercion->add_type_coercions(
	InstanceOf['HTML5::DOM::Text'] => \&html_to_xml,
	Str()                          => q{ XML::LibXML::Text->new($_) },
);

$meta->add_type(
	name      => 'XmlComment',
	parent    => InstanceOf['XML::LibXML::Comment'],
)->coercion->add_type_coercions(
	InstanceOf['HTML5::DOM::Comment'] => \&html_to_xml,
	Str()                             => q{ XML::LibXML::Comment->new($_) },
);

$meta->add_type(
	name      => 'XmlElement',
	parent    => InstanceOf['XML::LibXML::Element'],
)->coercion->add_type_coercions(
	InstanceOf['HTML5::DOM::Element'] => \&html_to_xml,
);

$meta->add_type(
	name      => 'XmlDocument',
	parent    => InstanceOf['XML::LibXML::Document'],
)->coercion->add_type_coercions(
	InstanceOf['HTML5::DOM::Tree']     => \&html_to_xml,
	InstanceOf['HTML5::DOM::Document'] => \&html_to_xml,
	InstanceOf['HTML5::DOM::Element']  => sub {
		my $old = shift;
		my $new = XML::LibXML::Document->new;
		$new->setDocumentElement(html_to_xml($old));
		$new;
	},
	Str()        => \&str_to_xml,
	File()       => sub { my $file = $_; str_to_xml($file->slurp_raw) },
	FileHandle() => sub { local $/; my $fh = $_; str_to_xml(<$fh>) },
);

$meta->add_type(
	name      => 'HtmlText',
	parent    => InstanceOf['HTML5::DOM::Text'],
)->coercion->add_type_coercions(
	InstanceOf['XML::LibXML::Text'] => \&xml_to_html,
	Str()                           => sub { die("TODO") },
);

$meta->add_type(
	name      => 'HtmlComment',
	parent    => InstanceOf['HTML5::DOM::Comment'],
)->coercion->add_type_coercions(
	InstanceOf['XML::LibXML::Comment'] => \&xml_to_html,
	Str()                              => sub { die("TODO") },
);

$meta->add_type(
	name      => 'HtmlElement',
	parent    => InstanceOf['HTML5::DOM::Element'],
)->coercion->add_type_coercions(
	InstanceOf['XML::LibXML::Element'] => \&xml_to_html,
	InstanceOf['XML::LibXML::Tree']    => q{ $_->root },
);

$meta->add_type(
	name      => 'HtmlTree',
	parent    => InstanceOf['HTML5::DOM::Tree'],
)->coercion->add_type_coercions(
	InstanceOf['XML::LibXML::Document'] => \&xml_to_html,
	InstanceOf(['HTML5::DOM::Document']) | InstanceOf(['HTML5::DOM::Element']) => sub {
		my $tree = Types::HTML5::_create_tree();
		my $root = $tree->root;
		my $old  = (@_ ? shift : $_)->clone(1, $tree);
		for my $child (@{ $root->childNodes }) {
			$root->removeChild($child);
		}
		for my $child (@{ $old->childNodes->array }) {
			$root->appendChild($child);
		}
		$root->attr( $old->attr );
		$tree;
	},
	Str()        => \&str_to_html,
	File()       => q{ Types::HTML5::str_to_html($_->slurp_raw) },
	FileHandle() => q{ do { local $/; my $fh = $_; Types::HTML5::str_to_html(<$fh>) } },
);

my $HtmlTree = $meta->get_type('HtmlTree');
$meta->add_type(
	name      => 'HtmlDocument',
	parent    => InstanceOf['HTML5::DOM::Document'],
)->coercion->add_type_coercions(
	$HtmlTree->coercibles => sub {
		$HtmlTree->assert_coerce( @_ ? shift : $_ )->document;
	},
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::HTML5 - types for parsing strings of HTML into DOMs

=head1 SYNOPSIS

   package My::Page {
      use Moo;
      use Types::HTML5 -types;
      
      has template => (
         is      => 'ro',
         isa     => HtmlTree,
         coerce  => 1,
      );
      
      sub output_page {
         ...;
      }
   }

=head1 STATUS

This is still at a very early stage of development and has
I<< no test suite >> yet.

=head1 DESCRIPTION

This type library provides useful type constraints and coercions for working
with L<HTML5::DOM> and L<XML::LibXML>. 

=head2 Type Constraints

=over

=item C<HtmlTree>

A blessed L<HTML::DOM::Tree> object. Coercions from L<HTML5::DOM::Document>
objects, L<XML::LibXML::Document> objects, L<HTML5::DOM::Element> objects,
strings of HTML or XHTML, filehandles, and L<Path::Tiny> objects.

=item C<HtmlDocument>

A blessed L<HTML::DOM::Document> object. Coercions from L<HTML5::DOM::Tree>
objects, L<XML::LibXML::Document> objects, L<HTML5::DOM::Element> objects,
strings of HTML or XHTML, filehandles, and L<Path::Tiny> objects.

=item C<HtmlElement>

A blessed L<HTML5::DOM::Element> object. Can coerce from
L<XML::LibXML::Element> objects.

=item C<HtmlComment>

A blessed L<HTML5::DOM::Comment> object. Can coerce from
L<XML::LibXML::Comment> objects and plain strings.

=item C<HtmlText>

A blessed L<HTML5::DOM::Text> object. Can coerce from
L<XML::LibXML::Text> objects and plain strings.

=item C<XmlDocument>

A blessed L<XML::LibXML::Document> object. Coercions from L<HTML5::DOM::Tree>
objects, L<HTML5::DOM::Document> objects, L<HTML5::DOM::Element> objects,
strings of HTML or XHTML, filehandles, and L<Path::Tiny> objects.

=item C<XmlElement>

A blessed L<XML::LibXML::Element> object. Can coerce from
L<HTML5::DOM::Element> objects.

=item C<XmlComment>

A blessed L<XML::LibXML::Comment> object. Can coerce from
L<HTML5::DOM::Comment> objects and plain strings.

=item C<XmlText>

A blessed L<XML::LibXML::Text> object. Can coerce from
L<HTML5::DOM::Text> objects and plain strings.

=back

=head2 Convenience Functions

=over 

=item C<< str_to_html($str) >>

Converts a string of HTML to an L<HTML5::DOM::Tree>.

=item C<< str_to_xml($str) >>

Converts a string of HTML to an L<XML::LibXML::Document>.

=item C<< html_to_xml($node) >>

Converts from an HTML5::DOM node to an XML::LibXML node. Supports
text nodes, comments, elements, documents, and trees.

=item C<< xml_to_html($node) >>

Converts from an XML::LibXML node to a HTML5::DOM node. Supports
text nodes, comments, elements, and documents. (XML::LibXML::Document
becomes HTML5::DOM::Tree, not HTML5::DOM::Document.)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-HTML5>.

=head1 SEE ALSO

L<HTML5::DOM>, L<XML::LibXML>, L<Path::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

