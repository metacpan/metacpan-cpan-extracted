package XML::Filter::DOMFilter::LibXML;

use 5.006;
use strict;
our $VERSION = '0.04';

use XML::LibXML::SAX::Builder;
use XML::LibXML::SAX::Parser;
use base qw(XML::LibXML::SAX::Builder);

sub _match {
  my ($self,$ctxt) = @_;
  my $p = $self->{Process};
  if ($self->{XPathContext}) {
    $self->{XPathContext}->setContextNode($ctxt);
    $ctxt=$self->{XPathContext};
  }
  return unless ref($p);
  for (my $i=0; $i<$#$p; $i+=2) {
    if ($ctxt->find($p->[$i])) {
      $self->{Matched}=$p->[$i+1];
      return 1;
    }
  }
}

sub start_document {
  my $self = shift;
  $self->SUPER::start_document(@_);
  $self->{Handler}->start_document(@_) if defined($self->{Handler});
}

sub xml_decl {
  my $self = shift;
  $self->SUPER::xml_decl(@_);
  $self->{Handler}->xml_decl(@_) if defined($self->{Handler});
}

sub end_document {
  my $self = shift;
  $self->SUPER::end_document(@_);
  $self->{Handler}->end_document(@_) if defined($self->{Handler});
}

sub start_prefix_mapping {
  my $self = shift;
  $self->SUPER::start_prefix_mapping(@_);
  $self->{Handler}->start_prefix_mapping(@_) unless (!defined($self->{Handler}) ||
						     $self->{FULL_TREE});
}

sub end_prefix_mapping {
  my $self = shift;
  $self->SUPER::end_prefix_mapping(@_);
  $self->{Handler}->end_prefix_mapping(@_) unless (!defined($self->{Handler}) ||
						   $self->{FULL_TREE});
}

sub start_dtd {
  my $self = shift;
#  $self->SUPER::start_dtd(@_); # not implemented by Builder
  $self->{Handler}->start_dtd(@_) if defined($self->{Handler});
}

sub end_dtd {
  my $self = shift;
#  $self->SUPER::end_dtd(@_); # not implemented by Builder
  $self->{Handler}->end_dtd(@_) if defined($self->{Handler});
}

sub start_cdata {
  my $self = shift;
  $self->SUPER::start_cdata(@_);
  $self->{Handler}->start_cdata(@_) unless (!defined($self->{Handler}) ||
					    $self->{FULL_TREE});
}

sub end_cdata {
  my $self = shift;
  $self->SUPER::end_cdata(@_);
  $self->{Handler}->end_cdata(@_) unless (!defined($self->{Handler}) ||
					  $self->{FULL_TREE});
}


sub start_entity {
  my $self = shift;
  $self->SUPER::start_entity(@_);
  $self->{Handler}->start_entity(@_) unless (!defined($self->{Handler}) ||
					     $self->{FULL_TREE});
}

sub end_entity {
  my $self = shift;
  $self->SUPER::end_entity(@_);
  $self->{Handler}->end_entity(@_) unless (!defined($self->{Handler}) ||
					   $self->{FULL_TREE});
}


sub start_element {
  my ($self, $el) = @_;
  my $parent = $self->{Parent};

#  if ($self->{FULL_TREE}==0 and defined($parent)) {
#    foreach ($parent->childNodes()) {
#      $_->unbindNode();
#    }
#  }
  $self->SUPER::start_element($el);
  if ($self->{FULL_TREE}) {
    $self->{FULL_TREE}++;
  } else {
    if (defined($self->{DOM}) and
	$self->_match($parent || $self->{DOM})) {
      $self->{FULL_TREE}=1;
    } else {
      $self->{Handler}->start_element($el) if defined($self->{Handler});
    }
  }
}

sub end_element {
  my $self = shift;
  my $node=$self->{Parent};
  my $parent=$node->parentNode || $self->{DOM};
  $self->SUPER::end_element(@_);
  if ($self->{FULL_TREE} == 1) {
    if ($self->{Matched}) {
      # pass the result to Handler as SAX events
      if (ref($self->{Matched}) eq 'ARRAY') {
	# with parameters
	&{$self->{Matched}[0]}($node,@{$self->{Matched}}[1..$#{$self->{Matched}}]);
      } else {
	# simple callback
	&{$self->{Matched}}($node);
      }
      if ($self->{Handler}) {
	my $process=XML::LibXML::SAX::Parser->new(Handler => $self->{Handler});
	foreach my $n ($parent->childNodes) {
	  $process->process_node($n);
	  $n->unbindNode();
	}
      } else {
          $parent->removeChildNodes;
      }
    }
  }
  if ($self->{FULL_TREE}) {
    $self->{FULL_TREE}--;
  } else {
    $self->{Handler}->end_element(@_) if defined($self->{Handler});
  }
}

sub characters {
  my $self = shift;
  if ($self->{FULL_TREE}) {
    $self->SUPER::characters(@_);
  } else {
    $self->{Handler}->characters(@_) if defined($self->{Handler});
  }
}

sub comment {
  my $self = shift;
  if ($self->{FULL_TREE}) {
    $self->SUPER::comment(@_);
  } else {
    $self->{Handler}->comment(@_) if defined($self->{Handler});
  }
}

sub processing_instruction {
  my $self = shift;
  if ($self->{FULL_TREE}) {
    $self->SUPER::processing_instruction(@_);
  } else {
    $self->{Handler}->processing_instruction(@_) if defined($self->{Handler});
  }
}

1;
__END__

=head1 NAME

XML::Filter::DOMFilter::LibXML - SAX Filter allowing DOM processing of selected subtrees

=head1 SYNOPSIS

  use XML::LibXML;
  use XML::Filter::DOMFilter::LibXML;

  my $filter = XML::Filter::DOMFilter::LibXML->new(
        Handler => $handler,
	XPathContext => XML::LibXML::XPathContext->new(),
	Process => [
		    '/foo[@A='aaa']/*/bar'    => \&process_bar,
		    'baz[parent::*/@B='bbb']' => \&process_baz
		   ]
      );

  my $parser = XML::SAX::YourFavoriteDriver->new( Handler => $filter );

  # Some DOM processing

  sub process_bar {
    my ($node)=@_;
    my $doc=$node->ownerDocument;
    $node->appendTextChild("note","hallo world!");
    $node->parentNode->insertAfter($doc->createElement("foo"),$node);
  }

  sub process_baz {
    my ($node)=@_;
    $node->unbindNode;
  }

=head1 DESCRIPTION

This module provides a compromise between SAX and DOM processing by
allowing to use DOM API to process only reasonably small parts of an
XML document. It works as a SAX filter temporarily building small DOM
trees around parts selected by given XPath expressions (with some
limitations, see L</"LIMITATIONS">).

The filter has two states which will be refered to as A and B
here. The initial state of the filter is A.

In the state A, only a limited vertical portion of the DOM tree is
built. All SAX events other than start_element are immediatelly passed
to Handler.  On start_element event, a new element node is created in
the DOM tree. All possible existing siblings of the newly created node
are removed. Thus, while in state A, there is exactly one node on
every level of the tree. Now all the XPath expressions are checked in
the context of the newly created node. If none of the expressions
matches, the parser remains in state A and passes the start_element
event to Handler. Otherwise, the callback associated with the first
expression that matched is remembered and the parser changes its state
to B.

In state B the filter builds a complete DOM subtree of the new element
according to the incomming events.  No events are passed to Handler at
this stage. When the subtree is complete (i.e. the corresponding
end-tag is encountered), the callback associated with the XPath
expression that matched is executed.  The root element of the subtree
is passed to the callback subroutine as the only argument.

The callback is allowed to do any DOM operations on the DOM subtree,
even to replace it with one or more new subtrees. The callack must,
however, preserve the element's parent node as well as all its
ancestor nodes intact. Failing to do so can result in an error or
unpredictable results.

When the callback returns, all subtrees that now appear in the
DOM tree under the original element parent are serialized to SAX events
and passed to Handler. After that, they are deleted from the DOM tree
and the filter returns to state A.

=head1 LIMITATIONS

Note that this type of processing highly limits the amount of
information the XPath engine can use. Most notably, elements cannot be
selected by their content. The only information present in the tree at
the time of the XPath evaluation is the element's name and attributes
and the same information for all its ancestors. There is nothing known
about possible child nodes of the element as well as of its position
within its siblings at the time the XPath expressions are evaluated.

=head1 METHODS

This filter is built upon
L<XML::LibXML::SAX::Builder|XML::LibXML::SAX::Builder> module.

=over 4

=item B<new>

This is the constructor for this object. It takes a several
parameters, some of which are optional.

    XML::Filter::DOMFilter::LibXML->new(
         Handler => $handler,
         XPathContext => $xpath_context,
         Process => [ XPath => Code, XPath => Code, ... ]
       );


B<Handler> - Optional output SAX handler.

B<XPathContext> - Optional L<XML::LibXML::XPathContext|XML::LibXML::XPathContext> object
to be used for XPath queries. In some cases it might be useful as it
allows registering namespace prefixes etc.

B<Process> - Required. An array reference of the form C<[ XPath =E<gt>
Code, XPath =E<gt> Code, ...]> where XPath is a string containing an
XPath expression and Code is a callback CODE reference.

=item

=back


=head2 EXPORT

None.

=head1 AUTHOR

Petr Pajas, E<lt>pajas@ufal.ms.mff.cuni.czE<gt>

=head1 SEE ALSO

L<XML::LibXML>, L<XML::LibXML::SAX>, L<XML::LibXML::XPathContext>.

=cut
