package XML::LibXML::Debugging;

use 5.008;
use parent qw(XML::LibXML);
use strict;

use HTML::HTML5::Entities qw(encode_entities_numeric);
use XML::LibXML qw(:all);

BEGIN {
	$XML::LibXML::Debugging::AUTHORITY = 'cpan:TOBYINK';
	$XML::LibXML::Debugging::VERSION   = '0.103';
}

sub XML::LibXML::Document::toDebuggingHash
{
	my $n = shift;
	
	return {
		'type'   => 'Document',
		'root'   => $n->documentElement->toDebuggingHash,
		};
}

sub XML::LibXML::Document::toClarkML
{
	my $n = shift;
	$n->documentElement->toClarkML;
}

sub XML::LibXML::Element::toDebuggingHash
{
	my $n = shift;
	
	my $rv = {
		'type'    => 'Element',
		'qname'   => $n->nodeName,
		'prefix'  => $n->prefix,
		'suffix'  => $n->localname,
		'nsuri'   => $n->namespaceURI,
		'attributes' => [],
		'children'   => [],
		};
	
	foreach my $attr ($n->attributes)
	{
		my $x = $attr->toDebuggingHash;
		push @{ $rv->{'attributes'} }, $x if $x;
	}
	
	foreach my $kid ($n->childNodes)
	{
		if ($kid->nodeType == XML_TEXT_NODE
		||  $kid->nodeType == XML_CDATA_SECTION_NODE)
		{
			push @{ $rv->{'children'} }, $kid->nodeValue;
		}
		elsif ($kid->nodeType == XML_COMMENT_NODE)
		{
			push @{ $rv->{'children'} }, $kid->toDebuggingHash;
		}
		elsif ($kid->nodeType == XML_ELEMENT_NODE)
		{
			push @{ $rv->{'children'} }, $kid->toDebuggingHash;
		}
	}
	
	return $rv;
}

sub XML::LibXML::Element::toClarkML
{
	my $n = shift;
	
	my $rv;
	
	if (defined $n->namespaceURI)
	{
		$rv = sprintf("<{%s}%s", $n->namespaceURI, $n->localname);
	}
	else
	{
		$rv = sprintf("<%s", $n->localname);
	}
	
	foreach my $attr ($n->attributes)
	{
		my $x = $attr->toClarkML;
		$rv .= " $x" if $x;
	}
	
	if (! $n->childNodes)
	{
		return $rv . "/>";
	}
	
	$rv .= ">";
	
	foreach my $kid ($n->childNodes)
	{
		if ($kid->nodeType == XML_TEXT_NODE
		||  $kid->nodeType == XML_CDATA_SECTION_NODE)
		{
			$rv .= encode_entities_numeric($kid->nodeValue);
		}
		elsif ($kid->nodeType == XML_COMMENT_NODE)
		{
			$rv .= "<!--" . $kid->nodeValue . "-->";
		}
		elsif ($kid->nodeType == XML_ELEMENT_NODE)
		{
			$rv .= $kid->toClarkML;
		}
	}
	
	if (defined $n->namespaceURI)
	{
		$rv .= sprintf("</{%s}%s>", $n->namespaceURI, $n->localname);
	}
	else
	{
		$rv .= sprintf("</%s>", $n->localname);
	}
	
	return $rv;
}

sub XML::LibXML::Comment::toDebuggingHash
{
	my $n = shift;
	
	return {
		'type'    => 'Comment',
		'comment' => $n->nodeValue,
		};
}

sub XML::LibXML::Comment::toClarkML
{
	my $n = shift;
	return "<!--" . $n->nodeValue . "-->";
}

sub XML::LibXML::Attr::toDebuggingHash
{
	my $n = shift;
	
	if ($n->nodeType == XML_NAMESPACE_DECL)
	{
		return {
			'type'    => 'Namespace Declaration',
			'qname'   => $n->nodeName,
			'prefix'  => $n->prefix,
			'suffix'  => $n->getLocalName,
			'nsuri'   => $n->getNamespaceURI,
			'value'   => $n->getData,
		};
	}
	
	return {
		'type'    => 'Attribute',
		'qname'   => $n->nodeName,
		'prefix'  => $n->prefix,
		'suffix'  => $n->localname,
		'nsuri'   => $n->namespaceURI,
		'value'   => $n->nodeValue,
		};
}

sub XML::LibXML::Attr::toClarkML
{
	my $n = shift;

	if ($n->nodeType == XML_NAMESPACE_DECL)
	{
		if (defined $n->getLocalName)
		{
			return sprintf("{%s}%s=\"%s\"",
				$n->getNamespaceURI, $n->getLocalName, $n->getData);
		}
		return sprintf("{%s}xmlns=\"%s\"",
			$n->getNamespaceURI, $n->getData);
	}
	
	if (defined $n->namespaceURI)
	{
		return sprintf("{%s}%s=\"%s\"",
			$n->namespaceURI, $n->localname, $n->nodeValue);
	}
	else
	{
		return sprintf("%s=\"%s\"",
			$n->localname, $n->nodeValue);
	}
}

sub XML::LibXML::Node::toClarkML
{
	return '';
}

sub XML::LibXML::Node::toDebuggingHash
{
	return {type=>'Node'};
}

sub XML::LibXML::Namespace::toClarkML
{
	return XML::LibXML::Attr::toClarkML(@_);
}

sub XML::LibXML::Namespace::toDebuggingHash
{
	return XML::LibXML::Attr::toDebuggingHash(@_);
}

1;

__END__

=head1 NAME

XML::LibXML::Debugging - get debugging information from XML::LibXML nodes

=head1 SYNOPSIS

  use XML::LibXML::Debugging;

  my $parser = XML::LibXML->new;
  my $doc    = $parser->parse_file('input.xml');
  print $doc->toClarkML;

=head1 DESCRIPTION

This module adds a couple of additional methods to XML::LibXML::Node
objects which are mostly aimed at helping figure out what's going on
with the DOM's namespaces and structure. C<toClarkML> produces a
string of XML-like markup with explicit namespaces. The following XML:

  <foo xmlns="http://example.com/1"
       xmlns:bar="http://example.com/2"
       bar:baz="quux" />

Might be represented as:

  <{http://example.com/1}foo
       {http://www.w3.org/2000/xmlns/}xmlns="http://example.com/1"
       {http://www.w3.org/2000/xmlns/}bar="http://example.com/2"
       {http://example.com/2}baz="quux" />

Another method C<toDebuggingHash> returns a hashref suitable for
dumping using Data::Dumper.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<XML::LibXML>,
L<XML::LibXML::Debugging>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
