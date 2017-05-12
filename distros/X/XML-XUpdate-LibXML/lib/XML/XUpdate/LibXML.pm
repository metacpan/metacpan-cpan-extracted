# $Id: LibXML.pm,v 1.15 2005/05/12 15:04:58 pajas Exp $

package XML::XUpdate::LibXML;

use XML::LibXML;
use XML::LibXML::XPathContext;
use strict;
use vars qw(@ISA $debug $VERSION);

BEGIN {
  $debug=0;
  $VERSION = '0.6.0';
}

sub strip_space {
  my ($text)=@_;
  $text=~s/^\s*//;
  $text=~s/\s*$//;
  return $text;
}

sub new {
  my $class=(ref($_[0]) || $_[0]);
  my $var_pool = {};
  my $xpc = XML::LibXML::XPathContext->new();
  $xpc->registerVarLookupFunc(\&_get_var,$var_pool);
  return bless [$var_pool,
		"http://www.xmldb.org/xupdate",
		$xpc
	       ], $class;
}

sub registerNs {
  my ($self,$prefix, $uri)=@_;
  $self->[2]->registerNs($prefix,$uri);
}

sub init {
  my ($self,$doc)=@_;
  $self->[2]->setContextNode($doc);
}

sub _context {
  my ($self,$name,$value)=@_;
  return $self->[2];
}

sub _set_var {
  my ($self,$name,$value)=@_;
  print STDERR "DEBUG: Storing $name as ",ref($value),"\n" if $debug;
  $self->[0]->{$name}=$value;
}

sub _get_var {
  my ($data,$name)=@_;
  return $data->{$name};
}

sub set_namespace {
  my ($self,$URI)=@_;
  $self->[1]=$URI;
}

sub namespace {
  my ($self)=@_;
  return $self->[1];
}

sub process {
  my ($self,$dom,$updoc)=@_;
  return unless ref($self);

  $self->init($dom);
  print STDERR "DEBUG: Updating ",$dom->nodeName,"\n" if $debug;
  foreach my $command ($updoc->getDocumentElement()->childNodes()) {

    if ($command->nodeType == XML::LibXML::XML_ELEMENT_NODE) {
      if (lc($command->getNamespaceURI()) eq $self->namespace()) {
	print STDERR "DEBUG: applying ",$command->toString(),"\n" if $debug;
	$self->xupdate_command($dom,$command);
      } else {
	print STDERR "DEBUG: Ignorint element ",$command->toString(),"\n" if $debug;
      }
    }

  }
}

sub get_text {
  my ($self,$node)=@_;
  my $text="";
  foreach ($node->childNodes()) {
    if ($_->nodeType() == XML::LibXML::XML_TEXT_NODE ||
	$_->nodeType() == XML::LibXML::XML_CDATA_SECTION_NODE) {
      $text.=$_->getData();
    }
  }
  return strip_space($text);
}

sub add_attribute {
  my ($self, $node, $attr_node)=@_;
  $node->setAttributeNS($attr_node->getNamespaceURI,
			$attr_node->getName(),
			$attr_node->getValue);
}

sub append {
  my ($self,$node,$results)=@_;
  foreach (@$results) {
    if ($_->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE) {
      $self->add_attribute($node,$_);
    } else {
      $node->appendChild($_);
    }
  }
}

sub insert_after {
  my ($self,$node,$results)=@_;

  if ($node->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE) {
    $self->append($node->getOwnerElement(),$results);
  } else {
    foreach (reverse @$results) {
      if ($_->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE) {
	$self->add_attribute($node->parentNode(),$_);
      } else {
	$node->parentNode()->insertAfter($_,$node);
      }
    }
  }
}

sub insert_before {
  my ($self,$node,$results)=@_;
  if ($node->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE) {
    $self->append($node->getOwnerElement(),$results);
  } else {
    foreach (@$results) {
      if ($_->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE) {
	$self->add_attribute($node->parentNode(),$_);
      } else {
	$node->parentNode()->insertBefore($_,$node);
      }
    }
  }
}

sub append_child {
  my ($self,$node,$results,$child)=@_;
  return unless @$results;
  if ($child ne "") {
    # XUpdate WD is weird:
      # child=1 should mean make the new node 1st child
      # child=last() should mean make new node last child
      # but if there are n children before insertion,
      # last() evaluates to n but they want the new node
      # to be (n+1)th.

      # so we must add it first, then calculate the position:
    my $ctxt = $self->_context();
    $self->append($node,$results);
    my ($ref)=$ctxt->findnodes("node()[$child]",$node);
    return unless $ref;
    # check whether we should move results before $ref node
    foreach (@$results) {
      return if $ref->isSameNode($_);
    }
    # now move them
    foreach (@$results) {
      $_->unbindNode();
      $node->insertBefore($_,$ref);
    }
 } else {
    $self->append($node,$results);
  }
}

sub update {
  my ($self,$node,$results)=@_;

  if ($node->nodeType == XML::LibXML::XML_TEXT_NODE ||
      $node->nodeType == XML::LibXML::XML_CDATA_SECTION_NODE) {
    $self->insert_after($node,$results);
    $node->unbindNode();
  } elsif ($node->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE ||
	   $node->nodeType == XML::LibXML::XML_PI_NODE) {
    $node->setValue(strip_space(join "", map { $_->to_literal() } @$results));
  } elsif ($node->nodeType == XML::LibXML::XML_ELEMENT_NODE) {
    foreach ($node->childNodes()){
      $_->unbindNode();
    }
    $self->append($node,$results);
  }
}

sub remove {
  my ($self, $node)=@_;
  $node->unbindNode();
}

sub rename {
  my ($self,$node,$name)=@_;
  $node->setName($name);
}

sub process_instructions {
  my ($self, $dom, $command)=@_;

  my @result=();
  foreach my $inst ($command->childNodes()) {
    print STDERR "DEBUG: Instruction ",$command->toString(),"\n" if $debug;
    if ( $inst->nodeType == XML::LibXML::XML_ELEMENT_NODE ) {
      if ( $inst->getLocalName() eq 'element' ) {
	my $new;
	if ($inst->hasAttribute('namespace') and
	    $inst->getAttribute('name')=~/:/) {
	  $new=$dom->getOwnerDocument()->createElementNS(
							 $inst->getAttribute('namespace'),
							 $inst->getAttribute('name')
							);
	} else {
	  $new=$dom->getOwnerDocument()->createElement($inst->getAttribute('name'));
	}
	$self->append($new,$self->process_instructions($dom,$inst));
	push @result,$new;
      } elsif ( $inst->getLocalName() eq 'attribute' ) {
	if ($inst->hasAttribute('namespace') and
	    $inst->getAttribute('name')=~/:/) {
	  my $att=
	    $dom->getOwnerDocument()->
	      createAttributeNS(
				$inst->getAttribute('namespace'),
				$inst->getAttribute('name')
			       );
	  $att->setValue($self->get_text($inst));
	  push @result,$att;
	} else {
	  my $att=
	    $dom->getOwnerDocument()->
	      createAttribute(
			      $inst->getAttribute('name')
			     );
	  $att->setValue($self->get_text($inst));
	  push @result,$att;
	}
      } elsif (  $inst->getLocalName() eq 'text' ) {
	push @result,$dom->getOwnerDocument()->createTextNode($self->get_text($inst));
      } elsif ( $inst->getLocalName() eq 'processing-instruction' ) {
	push @result,$dom->getOwnerDocument()->createProcessingInstruction(
						       $inst->getAttribute('name'),
						       $self->get_text($inst)
						      );
      } elsif ( $inst->getLocalName() eq 'comment' ) {
	push @result,$dom->getOwnerDocument()->createComment($self->get_text($inst));
      } elsif ( $inst->getLocalName() eq 'value-of' ) {
	my $value=$self->get_select($dom,$inst);
	if ($value->isa('XML::LibXML::NodeList')) {
	  push @result, map { $_->cloneNode(1) }$value->get_nodelist;
	} else {
	  push @result,$dom->getOwnerDocument()->createTextNode($value->to_literal());
	}
      } else {
	# not in XUpdate DTD but in examples of XUpdate WD
	push @result,$dom->getOwnerDocument()->importNode($inst) 
	  unless (lc($inst->getNamespaceURI) eq $self->namespace());
      }
    } elsif ( $inst->nodeType == XML::LibXML::XML_CDATA_SECTION_NODE ||
	      $inst->nodeType == XML::LibXML::XML_TEXT_NODE) {
      push @result,$dom->getOwnerDocument()->importNode($inst);
    }
  }
  return \@result;
}

sub get_select {
  my ($self,$dom,$node)=@_;
  my $xpath=$node->getAttribute('select');
  if ($xpath eq "") {
    die "Error: Required attribute select is missing or empty at:\n".
      $node->toString()."\nAborting!\n";
  }
  return $self->_context->find($xpath);
}

sub get_test {
  my ($self,$dom,$node)=@_;
  my $xpath=$node->getAttribute('test');
  if ($xpath eq "") {
    die "Error: Required attribute test is missing or empty at:\n".
      $node->toString()."\nAborting!\n";
  }
  return $self->_context->find($xpath);
}

sub xupdate_command {
  my ($self,$dom,$command)=@_;
  return unless ($command->getType == XML::LibXML::XML_ELEMENT_NODE);
  if ($command->getLocalName() eq 'variable') {
    my $select=$self->get_select($dom,$command);
    $self->_set_var($command->getAttribute('name'), $select);
  } elsif ($command->getLocalName() eq 'if') {
    # xu:if
    my $test=$self->get_test($dom,$command);
    if ($test) {
      print STDERR "DEBUG: Conditional execution of ",$dom->nodeName,"\n" if $debug;
      foreach my $subcommand ($command->childNodes()) {
	
	if ($subcommand->nodeType == XML::LibXML::XML_ELEMENT_NODE) {
	  if (lc($subcommand->getNamespaceURI()) eq $self->namespace()) {
	    print STDERR "DEBUG: Applying ",$subcommand->toString(),"\n" if $debug;
	    $self->xupdate_command($dom,$subcommand);
	  } else {
	    print STDERR "DEBUG: Ignoring element ",$subcommand->toString(),"\n" if $debug;
	  }
	}
	
      }
    }
  } else {
    my $select=$self->get_select($dom,$command);
    if ($select->isa('XML::LibXML::NodeList')) {
      my @refnodes=$select->get_nodelist();
      if (@refnodes) {
	
	# xu:insert-after
	if ($command->getLocalName eq 'insert-after') {

	  foreach (@refnodes) {
	    $self->insert_after($_,
				$self->process_instructions($dom,$command));
	  }

	# xu:insert-before
	} elsif ($command->getLocalName eq 'insert-before') {

	  foreach (@refnodes) {
	    $self->insert_before($_,
				$self->process_instructions($dom,$command));
	  }

	# xu:append
	} elsif ($command->getLocalName eq 'append') {

	  foreach (@refnodes) {
	    my $results=$self->process_instructions($dom,$command);
	    my $child=$command->getAttribute('child');
	    $self->append_child($_,$results,$child);
	  }

	# xu:update
	} elsif ($command->getLocalName eq 'update') {

	  foreach (@refnodes) {
	    my $results=$self->process_instructions($dom,$command);
	    # Well, XUpdate WD is not very specific about this.
	    # The content of this element should be PCDATA only.
	    # I'm extending WD by allowing instruction list.
	    $self->update($_,$results);
	  }

	# xu:remove
	} elsif ($command->getLocalName eq 'remove') {

	  foreach (@refnodes) {
	    $self->remove($_);
	  }

	# xu:rename
	} elsif ($command->getLocalName eq 'rename') {

	  foreach (@refnodes) {
	    $self->rename($_,$self->get_text($command));
	  }

	}
      }
    } else {
      die "XPath does not lead to a nodelist: ",$command->getAttribute('select'),"\n";
    }
  }
}

1;

__END__

=pod

=head1 NAME

XML::XUpdate::LibXML - Simple implementation of XUpdate format

=head1 SYNOPSIS

use XML::LibXML;
use XML::XUpdate::LibXML;

$parser  = XML::LibXML->new();
$dom     = $parser->parse_file("mydoc.xml");
$actions = $parser->parse_file("update.xml");

$xupdate = XML::XUpdate::LibXML->new();
$xupdate->process($dom->getDocumentElement(), $actions);
print $dom->toString(),"\n";

=head1 DESCRIPTION

This module implements the XUpdate format described in XUpdate Working
Draft from 2000-09-14 (http://www.xmldb.org/xupdate/xupdate-wd.html).
The implementation is based on XML::LibXML DOM API.


=head2 C<new>

    my $xupdate = XML::XUpdate::LibXML->new();

Creates a new XUpdate object. You may use this object to update
several different DOM trees using several different XUpdate
descriptions. The advantage of it is that an xupdate object remembers
values all variables declared in XUpdate documents.

=head2 C<$xupdate-E<gt>registerNs($prefix,$uri)>

Tell the XPath engine to resolve given namespace prefix as
the given namespace URI. This is particularly useful
to bind a default namespace to a prefix because
XPath doesn't honour default namespaces.

=head2 C<$xupdate-E<gt>process($document_dom,$xupdate_dom)>

This function takes two DOM trees as its arguments. It works by
updating the first tree according to all XUpdate commands included in
the second one. All XUpdate commands must be children of the root
element of the second tree and must all belong to XUpdate namespace
"http://www.xmldb.org/xupdate". The namespace URI may be changed
with set_namespace method.

=head2 C<$xupdate-E<gt>set_namespace($URI)>

You may use this method to change the namespace of XUpdate elements.
The default namespace is "http://www.xmldb.org/xupdate".

=head2 C<$xupdate-E<gt>namespace()>

Returns XUpdate namespace URI used by XUpdate processor to identify
XUpdate commands.

=head2 EXPORT

None.

=head1 DIFFERENCES BETWEEN 0.2.x and 0.3.x

In 0.3.x different implementation of XUpdate variables is used. Now
variables contain the actual objects resulting from an XPath query,
and not their textual content as in versions 0.2.x of
XML::XUpdate::LibXML.

Also, value-of instruction results in copies of the actual objects it
selects rather than their textual content as in 0.2.x.

I hope the new implementation is more conformant with the (not very
clear) XUpdate Working Draft and therefore more compatible with other
XUpdate implementations.

=head1 DIFFERENCES BETWEEN 0.3.x and 0.4.x

Commands are applied to all nodes of the select nodeset, not just the
first one.

=head1 DIFFERENCES BETWEEN 0.4.x and 0.5.x

XML::LibXML::XPathContext is used for variable code providing more
flexible and powerfull implementation. New and hopefully correct
implementation of the problematic child attribute of update command
has been introduced.

Support for registrering namespace prefix with the XPath engine
(allows binding document's default namespace to a prefix).

Several bug fixes.

=head1 DIFFERENCES BETWEEN 0.5.x and 0.6.x

xu:if command implementation contributed by Amir Guindehi.

=head1 AUTHOR

Petr Pajas, pajas@matfyz.cz

=head1 COPYRIGHT

Copyright 2002-2005 Petr Pajas, All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::LibXML> L<XML::LibXML::XPathContext>

=cut
