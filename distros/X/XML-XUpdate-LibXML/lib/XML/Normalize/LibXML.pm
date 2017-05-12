# $Id: LibXML.pm,v 1.8 2003/12/03 12:01:14 pajas Exp $

package XML::Normalize::LibXML;

use strict;
use Exporter;
use XML::LibXML;
use XML::LibXML::Iterator;

use vars qw(@ISA @EXPORT_OK $VERSION);

BEGIN {
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(trim xml_normalize xml_strip_whitespace xml_strip_element);
  $VERSION='0.2'
}

sub trim {
  my ($text)=@_;
  $text=~s/^\s*//;
  $text=~s/\s*$//;
  return $text;
}

sub xml_normalize {
  my ($node) = @_;
  my $prev = undef;	# previous Text node

  foreach my $node ($node->childNodes()) {
    my $type = $node->nodeType;
    if ($type == XML::LibXML::XML_TEXT_NODE) {
      if ($prev) {
	$prev->setData($prev->getData().$node->getData());
	$node->unbindNode();
      } else {
	$prev=$node;
      }
    } else {
      $prev = undef;
      if ($type == XML::LibXML::XML_ELEMENT_NODE) {
	xml_normalize($node);
      }
    }
  }
}

sub xml_strip_whitespace_text_node {
  my ($node)=@_;
  if ($node->nodeType() == XML::LibXML::XML_TEXT_NODE) {
    my $data=trim($node->getData());
    if ($data ne "") {
      $node->setData($data);
    } else {
      $node->unbindNode();
    }
  }
}

sub xml_strip_whitespace_attributes {
  my ($node)=@_;
  if ($node->nodeType() == XML::LibXML::XML_ELEMENT_NODE) {
    foreach my $attr ($node->attributes()) {
      $node->setValue(trim($node->getValue()));
    }
  }
}

sub xml_strip_whitespace {
  my ($dom, $strip_attributes)=@_;
  xml_normalize($dom);
  my $iter= XML::LibXML::Iterator->new( $dom );

  if ($strip_attributes) {
    $iter->iterate(sub {
		     xml_strip_whitespace_attributes($_[1]);
		     xml_strip_whitespace_text_node($_[1]);
		   });
  } else {
    $iter->iterate(sub {
		     xml_strip_whitespace_text_node($_[1]);
		   });
  }
}

sub xml_strip_element {
  my ($node)=@_;
  return unless $node->nodeType == XML::LibXML::XML_ELEMENT_NODE;

  my $f = $node->firstChild;
  while ($f and $f->nodeType == XML::LibXML::XML_TEXT_NODE and
	 $f->getData =~ /^\s/) {
    my $data=$f->getData();
    $data=~s/^\s+//;
    if ($data ne "") { 
      $f->setData($data);
      last;
    } else {
      $f->unbindNode();
      $f = $node->firstChild;
    }
  }

  my $f = $node->lastChild;
  while ($f and $f->nodeType == XML::LibXML::XML_TEXT_NODE and
	 $f->getData =~ /\s$/) {
    my $data=$f->getData();
    $data=~s/\s+$//;
    if ($data ne "") {
      $f->setData($data);
      last;
    } else {
      $f->unbindNode();
      $f = $node->lastChild;
    }
  }
}

1;

__END__

=pod

=head1 NAME

XML::Normalize::LibXML - simple whitespace striping functions

=head1 SYNOPSIS

use XML::Normalize::LibXML qw(trim xml_normalize xml_strip_whitespace);

$greeting=trim("   hallo world    ");  # returns "hallo world"
xml_normalize($dom->getDocumentElement());
xml_strip_whitespace($dom->getDocumentElement());

=head1 DESCRIPTION

This module provides simple whitespace striping and text-node
normalizing functions.

=head2 C<trim($string)>

Returns the string with any whitespace occuring at its beginning or
end removed.

=head2 C<xml_normalize($dom)>

Puts all Text nodes in the full depth of the sub-tree underneath this
Element into a normal form where only markup (e.g., tags,
comments, processing instructions, CDATA sections, and entity
references) separates Text nodes, i.e., there are no adjacent Text
nodes. This can be used to ensure that the DOM view of a document is
the same as if it were saved and re-loaded, and is useful when
operations (such as XPointer lookups) that depend on a particular
document tree structure are to be used.

=head2 C<xml_strip_whitespace($dom [,$include_attributes])>

Normalizes the subtree and trims whitespace from all Text nodes within
the subtree. If the optional argument $include_attributes is defined
and non-zero, this function trims whitespace also from all Attribute
nodes.

=head2 C<xml_strip_element($node)>

Removes leading and trailing whitespace from a given element.

=head1 AUTHOR

Petr Pajas, pajas@matfyz.cz

=head1 COPYRIGHT

Copyright 2002-2003 Petr Pajas, All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::LibXML>

=cut
