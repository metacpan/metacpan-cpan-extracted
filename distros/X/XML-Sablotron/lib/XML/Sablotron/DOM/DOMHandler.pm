# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron::DOM module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): Anselm Kruis, a.kruis@science-computing.de
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package XML::Sablotron::DOM::DOMHandler;

use strict;
use warnings;
use XML::Sablotron::SXP qw (:constants_sxp);
use XML::Sablotron::DOM qw (:all);


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Sablotron::DOM::DOMHandler ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.


# Preloaded methods go here.

sub import {
  my $pkg = shift;
  my %args = @_;

  if ($args{DO_INJECT}) {
    InjectDomHandler(%args);
  }
  1; 
}

sub InjectDomHandler {
  my %args = @_;
  $args{CLASS} = "XML::Sablotron::DOM::DOMHandler" unless $args{CLASS};
  $args{TARGET_CLASS} = "XML::Sablotron::DOM::Node" unless $args{TARGET_CLASS};
  $args{USE_UNIQUE_WRAPPERS} = 1 unless exists $args{USE_UNIQUE_WRAPPERS};

  $XML::Sablotron::DOM::useUniqueWrappers = $args{USE_UNIQUE_WRAPPERS} if 
    defined $args{USE_UNIQUE_WRAPPERS};
  {
    no strict 'refs';
    push @{$args{TARGET_CLASS} . "::ISA"}, ($args{CLASS}) ;
  }
}

sub _DHisNS {
  my $isNS = $_[0]->nodeName($_[1]) =~ /^xmlns(:.*)?$/ ;
  # printf STDERR ("DOMAdapter::_DHisNS: name=%s isNS %d\n", $_[0]->nodeName(), $isNS);
  return $isNS;
}

sub _DHdumpNode {}

sub _DHdumpNode_debug {
  my ($self,$sit,$caller) = @_;
  printf STDERR ("%s called on %s ", $caller, $self);
  my $name = $self->nodeName($sit);
  my $type = $self->nodeType($sit);
  printf STDERR ("%s(%d)\n", $name, $type);
}

sub DHGetNodeType {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNodeType");
  my $t = $self->nodeType($sit);
  $t = NAMESPACE_NODE if ($t == ATTRIBUTE_NODE && $self->_DHisNS($sit) );
  return $t;
}

sub DHGetNodeName {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNodeName");
  if ($self->nodeType($sit) == ATTRIBUTE_NODE && $self->_DHisNS($sit) ) {
    return $self->DHGetNodeNameLocal($sit);
  }
  return $self->nodeName($sit);
}  

sub DHGetNodeNameURI {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNodeNameURI");
  return $self->namespaceURI($sit);
}

sub DHGetNodeNameLocal {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNodeNameLocal");
  my $n = $self->localName($sit);
  $n = "" if ($n eq "xmlns" && $self->nodeType($sit) == ATTRIBUTE_NODE );
  return $n;
}

sub DHGetNodeValue {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNodeValue");
  return $self->nodeValue($sit)
}

sub DHGetNextSibling {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNextSibling");
  return $self->nextSibling($sit);
}

sub DHGetPreviousSibling {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetPreviousSibling");
  return $self->previousSibling($sit);
}

sub DHGetNextAttrNS {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNextAttrNS");
  return undef unless ( $self->nodeType($sit) == ATTRIBUTE_NODE );
  my $name = $self->nodeName($sit);
  my $isNS = $self->_DHisNS($sit);
  my $attrs = $self->ownerElement($sit)->attributes($sit);
  my $length = $attrs->length();
  my $i;
  for($i=0; $i < $length ; $i++ ) {
    last if $attrs->item($i)->name($sit) eq $name ;
  }
  for($i++; $i < $length ; $i++ ) {
    my $it = $attrs->item($i);
    return $it if $it->_DHisNS($sit) == $isNS;
  }
  return undef;
}

sub DHGetPreviousAttrNS {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetPreviousAttrNS");
  return undef unless ( $self->nodeType($sit) == ATTRIBUTE_NODE );
  my $name = $self->nodeName($sit);
  my $isNS = $self->_DHisNS($sit);
  my $attrs = $self->ownerElement($sit)->attributes($sit);
  my $i;
  my $length = $attrs->length();
  for($i=0; $i < $length ; $i++ ) {
    last if $attrs->item($i)->name($sit) eq $name ;
  }
  for($i--; $i >= 0 ; $i-- ) {
    my $it = $attrs->item($i);
    return $it if $it->_DHisNS($sit) == $isNS;
  }
  return undef;
}

sub DHGetChildCount {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetChildCount");
  my $t = $self->nodeType($sit);
  return 0 unless ( $t == ELEMENT_NODE || $t == DOCUMENT_NODE );
  return $self->childNodes($sit)->length();
}

sub DHGetAttributeCount {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetAttributeCount");
  return 0 unless ( $self->nodeType($sit) == ELEMENT_NODE );
  my $attrs = $self->attributes($sit);
  my $length = $attrs->length();
  my $cnt = 0;
  for(my $i=0; $i < $length ; $i++ ) {
    $cnt++ unless $attrs->item($i)->_DHisNS($sit);
  }
  return $cnt;
}

sub DHGetNamespaceCount {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNamespaceCount");
  return 0 unless ( $self->nodeType($sit) == ELEMENT_NODE );
  my $attrs = $self->attributes($sit);
  my $length = $attrs->length();
  my $cnt = 0;
  for(my $i=0; $i < $length ; $i++ ) {
    $cnt++ if $attrs->item($i)->_DHisNS($sit);
  }
  return $cnt;
}

sub DHGetChildNo {
  my ($self,$index,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetChildNo");
  # printf STDERR ("DHGetChildNo %d/%d\n",$index,$self->childNodes->length());
  return $self->childNodes($sit)->item($index);
}

sub DHGetAttributeNo {
  my ($self,$index,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetAttributeNo");
  # printf STDERR ("DHGetAttributeNo %d\n",$index);
  my $attrs = $self->attributes($sit);
  my $length = $attrs->length();
  my $cnt = 0;
  for(my $i=0; $i < $length ; $i++ ) {
    my $it = $attrs->item($i);
    next if $it->_DHisNS($sit);
    return $it if ( $index == $cnt );
    $cnt++;
  }
  return undef;
}

sub DHGetNamespaceNo {
  my ($self,$index,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNamespaceNo");
  # printf STDERR ("DHGetNamespaceNo %d\n",$index);
  my $attrs = $self->attributes($sit);
  my $length = $attrs->length();
  my $cnt = 0;
  for(my $i=0; $i < $length ; $i++ ) {
    my $it = $attrs->item($i);
    next unless $it->_DHisNS($sit);
    return $it if ( $index == $cnt );
    $cnt++;
  }
  return undef;
}

sub DHGetParent {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetParent");
  return $self->ownerElement($sit) if ( $self->nodeType($sit) == ATTRIBUTE_NODE );
  return $self->parentNode($sit);
}

sub DHGetOwnerDocument {
  my ($self,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetOwnerDocument");
  return $self->ownerDocument($sit);
}

sub DHCompareNodes {
  my ($self,$node2,$sit) = @_;
  $self->_DHdumpNode($sit,"DHCompareNodes");
  return $self->compareNodes($node2,$sit);
}

sub DHGetNodeWithID {
  my ($self,$id,$sit) = @_;
  $self->_DHdumpNode($sit,"DHGetNodeWithID");
  # sablotron doesn't support getElementById for now.
  return $self->getElementById($id,$sit) if $self->can("getElementById");
  return undef;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Sablotron::DOM::DOMHandler - A Perl extention of the XML::Sablotron::DOM class,
that implements the sablotron DOMHandler callback functions.

=head1 SYNOPSIS

  use XML::Sablotron::DOM;
  use XML::Sablotron::DOM::DOMHandler DO_INJECT => 1;

=head1 DESCRIPTION

This module adds methods to the XML::Sablotron::DOM module, which
provide an implementation of the sablotron DOMHandler callback
functions on top of the XML::Sablotron::DOM module.

=head2 EXPORT

None at all. However this module has an import function. The import
function is used to inject this module into the list of bases (@ISA)
of the @XML::Sablotron::DOM module.

=head1 AUTHOR

Anselm Kruis, E<lt>a.kruis@science-computing.deE<gt>

=head1 SEE ALSO

L<perl>.

=cut
