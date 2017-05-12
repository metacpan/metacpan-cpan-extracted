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
# Contributor(s): Anselm Kruis a.kruis@science-computing.de
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

package XML::Sablotron::Situation::DOMHandlerDispatcher;

use strict;
use warnings;

require Exporter;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $_debug_ret );
use fields qw(retrieveDocHandler);

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Sablotron::Situation::DOMHandlerDispatcher ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);


# Preloaded methods go here.

$_debug_ret=0;

use XML::Sablotron::SXP qw (:constants_sxp);
# use Devel::Peek;

sub new {
  my $class = shift;
  my $self = fields::new($class);
  $self->{retrieveDocHandler} = undef;
  return $self;
}

sub PostRegDOMHandler {
  my ($self,$sit) = @_;
  $sit->setSXPOptions( $sit->getSXPOptions() | 
		       SXPF_DISPOSE_NAMES | SXPF_DISPOSE_VALUES );
}

sub setRetrieveDocumentHandler {
  $_[0]->{retrieveDocHandler} = $_[1];
}

sub getRetrieveDocumentHandler {
  return $_[0]->{retrieveDocHandler};
}

sub R {
  return $_[1] unless $_debug_ret;

  my ($self,$ret) = @_;
  my ($pack,$file,$line,$subname,$hasargs,$wantarray) = caller(1);
  if (defined $ret) {
    printf STDERR ("DOMHandlerDispatcher::R: from %s dump of ret %s\n", $subname, $ret);
    # Dump($ret);
  } else {
    printf STDERR ("DOMHandlerDispatcher::R: from %s ret undefined\n", $subname);
  }
  return $ret;
}

sub S {
  return $_[1] unless $_debug_ret;

  my ($self,$ret) = @_;
  my ($pack,$file,$line,$subname,$hasargs,$wantarray) = caller(1);
  if (defined $ret) {
    printf STDERR ("DOMHandlerDispatcher::S: from %s ret = %s\n", $subname, $ret);
  } else {
    printf STDERR ("DOMHandlerDispatcher::S: from %s ret undefined\n", $subname);
  }
  return $ret;
}

sub DHGetNodeType {
  my ($self,$sit,$node) = @_;
  return $self->S( SXP_NONE ) unless ref $node;
  return $self->S( $node->DHGetNodeType($sit) );
}
sub DHGetNodeName {
  my ($self,$sit,$node) = @_;
  return $self->S( undef ) unless ref $node;
  return $self->S( $node->DHGetNodeName($sit) );
}  
sub DHGetNodeNameURI {
  my ($self,$sit,$node) = @_;
  return $self->S( undef ) unless ref $node;
  return $self->S( $node->DHGetNodeNameURI($sit) );
}
sub DHGetNodeNameLocal {
  my ($self,$sit,$node) = @_;
  return $self->S( undef ) unless ref $node;
  return $self->S( $node->DHGetNodeNameLocal($sit) );
}
sub DHGetNodeValue {
  my ($self,$sit,$node) = @_;
  return $self->S( undef ) unless ref $node;
  return $self->S( $node->DHGetNodeValue($sit) );
}
sub DHGetNextSibling {
  my ($self,$sit,$node) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetNextSibling($sit) );
}
sub DHGetPreviousSibling {
  my ($self,$sit,$node) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetPreviousSibling($sit) );
}
sub DHGetNextAttrNS {
  my ($self,$sit,$node) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetNextAttrNS($sit) );
}
sub DHGetPreviousAttrNS {
  my ($self,$sit,$node) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetPreviousAttrNS($sit) );
}
sub DHGetChildCount {
  my ($self,$sit,$node) = @_;
  return $self->S( 0 ) unless ref $node;
  return $self->S( $node->DHGetChildCount($sit) );
}
sub DHGetAttributeCount {
  my ($self,$sit,$node) = @_;
  return $self->S( 0 ) unless ref $node;
  return $self->S( $node->DHGetAttributeCount($sit) );
}
sub DHGetNamespaceCount {
  my ($self,$sit,$node) = @_;
  return $self->S( 0 ) unless ref $node;
  return $self->S( $node->DHGetNamespaceCount($sit) );
}
sub DHGetChildNo {
  my ($self,$sit,$node,$index) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetChildNo($index,$sit) );
}
sub DHGetAttributeNo {
  my ($self,$sit,$node,$index) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetAttributeNo($index,$sit) );
}
sub DHGetNamespaceNo {
  my ($self,$sit,$node,$index) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetNamespaceNo($index,$sit) );
}
sub DHGetParent {
  my ($self,$sit,$node) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetParent($sit) );
}
sub DHGetOwnerDocument {
  my ($self,$sit,$node) = @_;
  return $self->R( undef ) unless ref $node;
  return $self->R( $node->DHGetOwnerDocument($sit) );
}
sub DHCompareNodes {
  my ($self,$sit,$node1,$node2) = @_;
  return $self->S( 2 ) unless ref $node1;
  return $self->S( -2 ) unless ref $node2;
  return $self->S( $node1->DHCompareNodes($node2,$sit) );
}
sub DHGetNodeWithID {
  my ($self,$sit,$doc,$id) = @_;
  return $self->R( undef ) unless ref $doc;
  return $self->R( $doc->DHGetNodeWithID($id,$sit) );
}

sub DHRetrieveDocument {
  my ($self,$sit,$uri,$baseUri) = @_;
  # printf STDERR ("DOMHandlerDispatcher::DHRetrieveDocument: uri '%s'\n",$uri);
  return $self->R( &{$self->{retrieveDocHandler}}($uri,$baseUri,$sit) ) 
    if defined $self->{retrieveDocHandler};
  return $self->R( undef );
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Sablotron::Situation::DOMHandlerDispatcher - Perl sample
implementation of the Sablotron DOMHandler callback interface

=head1 SYNOPSIS

  use XML::Sablotron;
  use XML::Sablotron::Situation::DOMHandlerDispatcher;
  
  my $sit = new XML::Sablotron::Situation();
  $sit->regDOMHandler( new XML::Sablotron::Situation::DOMHandlerDispatcher() );
  my $sab = new XML::Sablotron( $sit );


=head1 DESCRIPTION

The class C<XML::Sablotron::Situation::DOMHandlerDispatcher> is a sample
implementation of the callback methods of the Sablotron SXP DOMHandler
interface.

=head1 XML::Sablotron::Situation::DOMHandlerDispatcher

=head2 new

The constructor of the XML::Sablotron::Situation::DOMHandlerDispatcher
object takes no arguments, so you can create new instance simply like
this:

  $dhdisp = new XML::Sablotron::Situation::DOMHandlerDispatcher();

=head2 setRetrieveDocumentHandler

Set a handler function for the retrieveDocument callback. 

  $dhdisp->setRetrieveDocumentHandler(&retrieveDocument);

=over 4

=item &retrieveDocument

The handler function. It must look like this:
  
  sub retrieveDocument( $uri, $baseUri, $sit )

=back

=head2 getRetrieveDocumentHandler

Get the handler function for the retrieveDocument callback.

  $handler = $dhdisp->getRetrieveDocumentHandler();

=head2 EXPORT

None at all.


=head1 AUTHOR

Anselm Kruis, E<lt>a.kruis@science-computing.deE<gt>

=head1 SEE ALSO

L<perl>.

=cut
