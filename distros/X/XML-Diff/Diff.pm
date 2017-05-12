=pod

=head1 NAME

XML::Diff -- XML DOM-Tree based Diff & Patch Module

=head1 SYNOPSIS

  my $diff = XML::Diff->new();

  # to generate a diffgram of two XML files, use compare.
  # $old and $new can be filepaths, XML as a string,
  # XML::LibXML::Document or XML::LibXML::Element objects.
  # The diffgram is a XML::LibXML::Document by default.
  my $diffgram = $diff->compare(
                                -old => $old_xml,
                                -new => $new_xml,
                               );

  # To patch an XML document, an patch. $old and $diffgram
  # follow the same formatting rules as compare.
  # The resulting XML is a XML::LibXML::Document by default.
  my $patched = $diff->patch(
                             -old      => $old,
                             -diffgram => $diffgram,
                            );

=head1 DESCRIPTION

This module provides methods for generating and applying an XML
diffgram of two related XML files. The basis of the algorithm
is tree-wise comparison using the DOM model as provided by
XML::LibXML.

The Diffgram is well-formed XML in the XVCS namespance and
supports update, insert, delete and move operations. It is
meant to be human and machine readable. It uses XPath expressions
for locating the nodes to operate on. See the below B<DIFFGRAM>
section for the exact syntax.

The motivation and alogrithm used by this module is discussed in
B<MOTIVATION> below.

=cut
package XML::Diff;

use XML::LibXML;
use Digest::MD5;
use Algorithm::Diff qw( traverse_sequences );

#debug aid
use Data::Dumper;

use strict;

# match constants
use constant HARD_MATCH      => 1;
use constant SOFT_MATCH      => 2;
use constant BRANCH_MATCH    => 3;
use constant STRUCTURE_MATCH => 4;

# action constants
use constant TREE_MOVE  => 0;
use constant LOCAL_MOVE => 1;
use constant INSERT     => 2;
use constant DELETE     => 3;
use constant UPDATE     => 4;
use constant NOOP       => 5;

# Module mode constants
use constant NONE    => 0;
use constant COMPARE => 1;
use constant PATCH   => 2;

use vars qw($VERSION $DEBUG);

$VERSION = "0.05";

=head1 PUBLIC METHODS

=head2 new (Constructor)

The Constructor takes no arguments. It merely creates the object
for using the B<compare> and B<patch> methods on.

=cut
# _________________________________________________________
sub new {
  my $pkg = shift;
  my %in  = @_;

  my $self = {
              parser => XML::LibXML->new(),
              pkg    => $pkg,
              ns     => ['http://www.xvcs.org/','xvcs',0],
             };

  bless($self,$pkg);

  if( $XML::Diff::DEBUG ) {
    require Data::Dumper;
  }

  $self->{parser}->keep_blanks(0);

  return $self;
}

=pod

=head2 compare

Compares two XML DOM trees and returns a diffgram for converting one
into the other. The default output method is a XML::LibXML::Document
object. However there are number of switches to alter this behavior.

=over 4

=item -old

The old document to compare. Can be XML in a string, path to an
XML document, a XML::LibXML::Document or XML::LibXML::Element object

=item -new

The new document to compare. Can be XML in a string, path to an
XML document, a XML::LibXML::Document or XML::LibXML::Element object

=item -asString

If provided, the diffgram is returned via the toString(1) method
of XML::LibXML

=item -asFile

Must provide the filepath to write the diffgram to.

=back

=cut
# _________________________________________________________
sub compare {
  my $self = shift;
  my %in   = @_;

  # init
  $self->{ID} = 0;
  $self->{_MODE} = COMPARE;
  $self->{old}->{lookup} = {};
  $self->{new}->{lookup} = {};

  # get DOM objects
  $self->_getDoc( 'old', $in{-old} );
  $self->_getDoc( 'new', $in{-new} );

  # diffgram we will return
  $self->{diffgram} = $self->{parser}->createDocument();
  $self->{diffroot} = $self->{diffgram}->createElement('xvcs:diffgram' );
  $self->{diffroot}->setNamespace(@{$self->{ns}});
  $self->{diffgram}->setDocumentElement( $self->{diffroot} );

  # generate the Diff
  $self->_debug( "-- Phase I: ID Matching (unimplemented) --" );

  $self->_debug( "-- Phase II: Compute Hashes & Weights  --" );

  $self->_debug( "old ------" );
  $self->_buildTree($self->{old}->{root},$self->{old}->{lookup},1);

  $self->_debug( "new ------" );
  $self->_buildTree($self->{new}->{root},$self->{new}->{lookup});

  $self->_debug( "-- Phase III: Match by weight --" );

  $self->_weightmatch(HARD_MATCH);
  $self->_weightmatch();

  if( $XML::Diff::DEBUG ) {
    $self->_debug( "   MATCH_STATS ---------------------------------" );
    $self->_debug( "Hard Matches:      $self->{MATCH_COUNT}->{1}" );
    $self->_debug( "Structure Matches: $self->{MATCH_COUNT}->{4}" );
#    exit;
  }

  $self->_debug( "-- Phase IV: Propagate Matchings by structure (unimplemented) --" );

  $self->_debug( "-- Phase V: Generate Diffgram --" );

  $self->_markChanges($self->{new}->{root});
  $self->_markChanges($self->{old}->{root},1);

  if( $XML::Diff::DEBUG ) {
    $self->_debug( "   OLD ---------------------------------" );
    $self->_debug( $self->{old}->{root}->toString(1) );
    $self->_debug();
    $self->_debug( "\n   CMP ----------------------------------" );
    $self->_debug( $self->{new}->{root}->toString(1) );
    $self->_debug();
  }

  foreach my $ref ( sort { $a->{rank} <=> $b->{rank} } values %{$self->{change}} ) {
    $self->_processChange( $ref );
  }

  my $return; 
  if( $in{-asString} ) {
    $return = $self->{diffgram}->toString(1);
  } elsif( $in{-asFile} ) {
    $return = $self->{diffgram}->toFile($in{-asFile}, 1);
  } else {
    $return = $self->{diffgram};
  }

  # clean-up
  undef $self->{old};
  undef $self->{new};
  undef $self->{diffgram};
  undef $self->{diffroot};
  undef $self->{clone_lookup};
  undef $self->{change_rank};
  undef $self->{change};
  undef $self->{change_registry};

  $self->{_MODE} = NONE;

  return $return;
}

=pod

=head2 patch

Applies a diffgram to an XML document to generate a new XML document.
The default output method is a XML::LibXML::Document object. However
there are number of switches to alter this behavior.

=over 4

=item -old

The old document to compare. Can be XML in a string, path to an
XML document, a XML::LibXML::Document or XML::LibXML::Element object

=item -diffgram

The diffgram to apply. Can be XML in a string, path to an
XML document, a XML::LibXML::Document or XML::LibXML::Element object

=item -asString

If provided, the new document is returned via the toString(1) method
of XML::LibXML

=item -asFile

Must provide the filepath to write the new document to.

=back

=cut
# _________________________________________________________
sub patch {
  my $self = shift;
  my %in   = @_;

  $self->{_MODE} = PATCH;

  $self->_getDoc( 'old', $in{-old} );
  $self->_getDoc( 'diff', $in{-diffgram} );

  # gotta find the nodes to be moved before we do any of the actual actions,
  # otherwise our xpath's are off

  #$self->_debug( "original:\n".$self->{old}->{doc}->toString(1) );
  foreach my $patch ( $self->{diff}->{root}->childNodes ) {
    my $name = $patch->nodeName();
    $self->_debug( "applying:\n".$patch->toString(1) );
    for($name) {
      /xvcs:insert/ && do { $self->_applyInsert( $patch ); last; };
      /xvcs:update/ && do { $self->_applyUpdate( $patch ); last; };
      /xvcs:delete/ && do { $self->_applyDelete( $patch ); last; };
      /xvcs:move/   && do { $self->_applyMove( $patch ); last; };
      last;
    }
    #$self->_debug( "intermediate:\n".$self->{old}->{doc}->toString(1) );
  }

  my $return;
  if( $in{-asString} ) {
    $return = $self->{old}->{doc}->toString(1);
  } elsif( $in{-asFile} ) {
    $return = $self->{old}->{doc}->toFile($in{-asFile}, 1);
  } else {
    $return = $self->{old}->{doc};
  }

  undef $self->{old};
  undef $self->{diff};

  $self->{_MODE} = NONE;

  return $return;
}

=pod

=head1 DIFFGRAM

The diffgram is an XML document in the xvcs namespace. It's root is always
I<e<xvcs:diffgram xmlns:xvcs="http://www.xvcs.org/">>. Below diff operations
are attached in order of application. Order I<is> significant, since the
way that nodes are idenitified in the default version of the diffgram is by
an XPath expression, i.e. the diffgram may change the XML document in such
a way that XPath expressions are either not yet valid or will not be anymore
at a later point the diffgram (see B<KNOWN PROBLEMS> for a discussion of this
limitation).

The supported diffgram operations are:

=head2 xcvs:update

Update operations covers a number of sub-operations, i.e. it can be used
for Text node changes, attribute add, delete and modification. An example
of a Text Node change is:

  <xvcs:update id="18" first-child-of="/root/block[2]/list/item[2]">
    <xvcs:old-value>Old Value</xvcs:old-value>
    <xvcs:new-value>New Value</xvcs:new-value>
  </xvcs:update>

Attribute updates are:

  <xvcs:update id="31" first-child-of="/root/block[5]">
    <xvcs:attr-insert name="some_attribute" value="new value"/>
  </xvcs:update>
  <xvcs:update id="32" first-child-of="/root/block[6]">
    <xvcs:attr-insert name="some_attribute2" value="old value"/>
  </xvcs:update>
  <xvcs:update id="33" first-child-of="/root/block[6]">
    <xvcs:attr-update name="some_attribute3" 
      old-value="old value" new-value="new value/>
  </xvcs:update>

=head2 xcvs:delete

  <xvcs:delete id="29" follows="/root/block[3]">
    <block>
      <node>value</node>
    </block>
  </xvcs:delete>

=head2 xcvs:move

  <xvcs:move id="11" follows="/root/block[1]">
    <xvcs:source first-child-of="/root"/>
  </xvcs:move>

=head2 xcvs:insert

  <xvcs:insert id="34" follows="/root/block[1]">
    <block>
      <node>value</node>
    </block>
  </xvcs:insert>

All operations share the same attributes to identify the operation

=over 4

=item id

The xvcs:id of the node affected (currently serves only internal uses)

=item follows

The XPath to the prior sibling of the node affected. We use relative
identification since insert and move destination do not affect an
existing node location. The rest of the operations follow this methodology
for consistency and to allow simple reversing of an operation

=item first-child-of

If the XPath for the node does not have a prior sibling, we use the
XPath to the parent and note that our operation affects the first child
of that parent

=item text

Since XPath does not have an expression for locating a text node,
Nodes following Text nodes are identified by the XPath to the prior
sibling that is an Element and the text attribute to tell it to
skip the next text node before starting the operation

=back

=head1 KNOWN PROBLEMS

=over 4

=item * Does not handle any Node Types Other than Element, Attribute and Text

=item * Diffgram operations are not guaranteed to be atomic

=item * Delete Operations on Nodes between two Text nodes are not reversable

=back

=head1 MOTIVATIONS

The Algorithm used in this Module is loosely based on the one described
by Gregory Cobena in his Doctoral Dissertation on XyDiff. The decision to
create a new implementation of this Algorithm rather than just create an
XS interface to the existing XyDiff algorithm was based on wanting a perl
implementation with less external dependencies and greater flexibility to
add divergent features (such as using XPath for node identitication rather
than XIDs).


=head1 PRIVATE METHODS

This section is mostly for reference if you are going through the code,
it serves no purpose if you are just wanting to use the exposed interface

=head2 _getDoc

=cut
# _________________________________________________________
sub _getDoc {
  my $self   = shift;
  my $type   = shift;
  my $source = shift;
  my $doc;

  if( ref $source ) {
    if( $source->isa( 'XML::LibXML::Document' ) ) {
      # since we're likely to mess around with the object, we clone it
      # for our internal use
      $self->{$type}->{root} = $source->documentElement()->cloneNode(1);
    } elsif( $source->isa( 'XML::LibXML::Element' ) ) {
      # since we're likely to mess around with the object, we clone it
      # for our internal use
      $self->_debug( "source was libXML element" );
      $self->{$type}->{root} = $source->cloneNode(1);
    } else {
      return undef;
    }

    $self->{$type}->{doc} = $self->{parser}->createDocument();
    $self->{$type}->{doc}->setDocumentElement( $source );

  } else {
    if( $source !~ /\n/ && -e $source ) {
      $self->{$type}->{doc}  = $self->{parser}->parse_file( $source );
    } else {
      $self->{$type}->{doc} = $self->{parser}->parse_string( $source );
    }
    $self->{$type}->{root} = $self->{$type}->{doc}->documentElement();
  }

  #$self->{$type}->{doc}->indexElements();

  return 1;

}

=pod

=head2 _buildTree

=cut
# _________________________________________________________
sub _buildTree {
  my $self     = shift;
  my $node     = shift;
  my $lookup   = shift;
  my $old      = shift;
  my $position = shift || 0;
  my $signature;
  my $thumbprint;
  my $weight;

  # currently we only look at Element and Text nodes (Attribute nodes
  # we handle as a known sub-element of Element nodes)
  #next unless( $node->nodeType == 3 || $node->nodeType == 1 );

  # need to consider full, content and structure matches for better diffs
  # but that's for the future.. right now we just do structure
  my $nodeType = $node->nodeType;
  if( $node->nodeType == 1 ) {
    #$self->_debug( "- element node -" );
    #     XML_ELEMENT_NODE=           1,
    #     XML_ATTRIBUTE_NODE=         2,
    $signature = $node->nodeName();
    $thumbprint = $signature;
    my $p;
    foreach my $child ( $node->childNodes() ) {
      my($thumbprint2,$signature2) = $self->_buildTree( $child, $lookup, $old, $p );
      $thumbprint .= $thumbprint2;
      $signature  .= $signature2;
      $p++;
    }

    foreach my $attr ( sort {$a->nodeName cmp $b->nodeName } $node->attributes() ) {
      $weight += length($attr->nodeName);
      $thumbprint .= $attr->nodeName();
    }

  } elsif( $nodeType == 3 ) {
    #$self->_debug( "- text node -" );
    #     XML_TEXT_NODE=              3,
    # text node hashes are their text value
    $signature = 'TEXT';
    $thumbprint = $signature.$node->textContent();
    $weight    = length($thumbprint);

  } elsif( $nodeType == 4 ) {
    #$self->_debug( "- cdata section -" );
    #     XML_CDATA_SECTION_NODE=     4,
    # cdata section
    $signature  = 'CDATA';
    $thumbprint = $signature.$node->textContent();
    $weight     = length($thumbprint);

  } elsif( $nodeType == 7 ) {
    #$self->_debug( "- processing instruction -" );
    #     XML_PI_NODE=                7,
    # processing instruction
    $signature = 'PI';
    $thumbprint = $signature;
    $weight    = 5;

  } elsif( $nodeType == 8 ) {
    #$self->_debug( "- comment node -" );
    #     XML_COMMENT_NODE=           8,
    # comment node
    $signature = 'COMMENT';
    $thumbprint = $signature.$node->textContent();
    $weight     = length($thumbprint);


  } else {
    #$self->_debug( "- UNHANDLED NODE TYPE -" );

    # unhandled
    #     XML_ENTITY_REF_NODE=        5,
    #     XML_ENTITY_NODE=            6,
    #     XML_DOCUMENT_NODE=          9,
    #     XML_DOCUMENT_TYPE_NODE=     10,
    #     XML_DOCUMENT_FRAG_NODE=     11,
    #     XML_NOTATION_NODE=          12,
    #     XML_HTML_DOCUMENT_NODE=     13,
    #     XML_DTD_NODE=               14,
    #     XML_ELEMENT_DECL=           15,
    #     XML_ATTRIBUTE_DECL=         16,
    #     XML_ENTITY_DECL=            17,
    #     XML_NAMESPACE_DECL=         18,
    #     XML_XINCLUDE_START=         19,
    #     XML_XINCLUDE_END=           20
    next;
  }

  my $md5 = Digest::MD5->new();
  $md5->add($signature);
  my $hash  = $md5->b64digest();
  my $node_id = $$node;

  my $md5_2 = Digest::MD5->new();
  $md5_2->add($thumbprint);
  $thumbprint = $md5_2->b64digest();
  #$self->_debug( "$node_id\t$weight\t$hash" );

  my $id;
  push(@{$lookup->{hash}->{$hash}->{$position}},$node);
  if( !$lookup->{hash}->{$hash}->{max} || $lookup->{hash}->{$hash}->{max} <= $position ) {
    $lookup->{hash}->{$hash}->{max} = $position;
  }

  #if( !$self->{_HARD_MATCH} && @{$lookup->{hash}->{$hash}} > 100 ) {
  #  $self->{_HARD_MATCH} = 1;
  #  $self->_debug( "need to consider hard match.." );
  #}

  if( $old ) {
    $id = ++$self->{ID};
    if( $nodeType == 1 ) {
      $node->setAttribute('xvcs:id',$id );
    }
    $lookup->{id}->{$id} = $node;
    push(@{$lookup->{thumbprint}->{$thumbprint}->{$position}},$node);
    if( !$lookup->{thumbprint}->{$thumbprint}->{max} || $lookup->{thumbprint}->{$thumbprint}->{max} <= $position ) {
      $lookup->{thumbprint}->{$thumbprint}->{max} = $position;
    }
  } else {
    $weight += length($signature);
  }

  $lookup->{nodes}->{$node_id} = [$hash,$weight,$id,$position,$thumbprint];
  return($thumbprint,$hash);
}

=pod

=head2 _weightmatch

=cut
# _________________________________________________________
sub _weightmatch {
  my $self       = shift;
  my $match_type = shift || STRUCTURE_MATCH;
  my @queue = ($self->{new}->{root});
  my $lookup    = $self->{old}->{lookup};
  my $newlookup = $self->{new}->{lookup};
  while ( my $node = shift @queue ) {
    my($hash,$weight,$id,$position,$thumbprint) = @{$newlookup->{nodes}->{$$node}};
    if( $XML::Diff::DEBUG ) {
      my $node_name = $node->nodeName() || '';
      $self->_debug( "$$node\t$weight\t$node_name\t$hash" );
    }
    if ( $newlookup->{match_type}->{$$node} ) {
      $self->_debug( "  already matched this node.. WTF!" );
      next;
    }
    #my $hard_match = $lookup->{thumbprint}->{$thumbprint};
    #if( $hard_match ) {
    #  my $count = @$hard_match;
    #  $self->_debug( "  got $count hard matches for $thumbprint" );
    #  if( $count > 1 ) {
    #    $self->_debug( $node->toString(1) );
    #    exit;
    #  }
    #}
    my $candidates;
    if( $match_type == HARD_MATCH ) {
      $candidates = $lookup->{thumbprint}->{$thumbprint};
    } else {
      $candidates = $lookup->{hash}->{$hash};
    }
    my $candidate;
    if( $candidates ) {

      # need to find the best candidate
      # first consider position in parent, so that we avoid moves

      my $likely;
      my $distance = 0;
      my $max = $candidates->{max};
      $self->_debug( "  max position => $max" );

      while( !$likely ) {
        my @likely;
        my $forward = $position + $distance;
        my $back    = $position - $distance;
        $self->_debug( "  checking $forward and $back" );
        my $check;
        if( $forward != $back && $forward <= $max ) {
          # first time we hit this loop forward and back are the same, so we don't
          # want to pull the same set twice
          # we also don't want to push beyond our bounds
          $check++;

          if( exists( $candidates->{$forward} ) ) {
            # while we're looking at candidates, prune the ones already matched
            my @l;
            foreach my $node (@{$candidates->{$forward}}) {
              # check that this node hasn't been matched already
              if( $lookup->{nodes}->{$$node} &&
                  $lookup->{nodes}->{$$node}->[0] ) {
                push( @l, $node );
              } else {
                $self->_debug( "removing previously matched node from set" );
              }
            }
            if( @l ) {
              $candidates->{$forward} = \@l;
              push( @likely, @l );
            } else {
              delete $candidates->{$forward};
            }
          }
        }

        if( $back >= 0 ) {
          # once, we get into negative territory, we don't check

          $check++;

          if( exists( $candidates->{$back} ) ) {
            # while we're looking at candidates, prune the ones already matched
            my @l;
            foreach my $node (@{$candidates->{$back}}) {
              # check that this node hasn't been matched already
              if( $lookup->{nodes}->{$$node} &&
                  $lookup->{nodes}->{$$node}->[0] ) {
                push( @l, $node );
              } else {
                $self->_debug( "removing previously matched node from set" );
              }
            }
            if( @l ) {
              $candidates->{$back} = \@l;
              push( @likely, @l );
            } else {
              delete $candidates->{$back};
            }
          }
        }

        if( !$check ) {
          $self->_debug( "we give up: ".join(',',keys %$candidates));
          # neither forward nor back had possible matches, we are done trying
          last;
        }

        # check if we end up with any likely set
        if( @likely ) {
          $likely = \@likely;
        }

        # ready for another round?
        $distance++;
      }

      # then consider closests weight as an approximation of content and/or
      # position in tree

      if( $likely ) {
        my @likely = sort
          {
            return abs($lookup->{nodes}->{$$a}->[1]-$weight) <=> abs($lookup->{nodes}->{$$b}->[1]-$weight);
          } @$likely;

        if( $node->nodeType == 3 ) {
          # if our comparison is among text nodes, let's go the extra mile and
          # see if there is a direct match first
          my $text = $node->textContent();
          # generally speaking white-space is insignificant in XML, so at least
          # for matching purposes, we want to consider it as such
          $self->_debug( "comparing text nodes: $text" );
          foreach my $c ( @likely ) {
            my $compare = $c->textContent();
            $compare =~ s/\s*$//;
            $compare =~ s/^\s*//;
            $self->_debug( " => $compare" );
            if( $compare eq $text ) {
              $candidate = $c;
              $lookup->{nodes}->{$$candidate}->[0] = undef;
              last;
            }
          }
        }

        while ( !$candidate ) {
          # we use pop until we have criteria, so that we at least preserve order
          $candidate = shift @likely;
          # gotta catch the case of not having anything in the array
          last unless( $candidate );
          if( ! $lookup->{nodes}->{$$candidate} ||
              ! $lookup->{nodes}->{$$candidate}->[0] ) {
            # the node is no longer in the node set with a hashvalue,
            # i.e. it's been matched already
            $self->_debug( "  WTF!! this candidate's already been matched" );
            undef $candidate;
          }
        }
      }
    }

    if( $candidate ) {
      # got a match on this subtree, need to remove the children from the set of
      # matchable nodes
      $self->_propagateMatch( $node,$candidate, $match_type );

      # we will still have to check the nodes and children for
      # attribute and content changes

      # need to match as many parent nodes by structure as possible
      $self->_matchParents( $node, $candidate );

      # _matchParents does the bottom up portion of our match propagation,
      # but for better quality diffgrams we need to also do the lazy down
      # where we consider our siblings and match them by structure, in case
      # they don't match by hash.. But that's for the future


    } else {
      $self->_debug( "no match, adding children to queue" );
      push( @queue, $node->childNodes() );
      my @sorted = 
        sort {
          $newlookup->{nodes}->{$$b}->[1] <=> $newlookup->{nodes}->{$$a}->[1]
        } @queue;
      @queue = @sorted;
    }
  }

  return 1;
}

=pod

=head2 _propagateMatch

=cut
# _________________________________________________________
sub _propagateMatch {
  my $self       = shift;
  my $new        = shift;
  my $old        = shift;
  my $match_type = shift;
  my $lookup     = $self->{old}->{lookup};
  my $newlookup  = $self->{new}->{lookup};
  my $id         = $lookup->{nodes}->{$$old}->[2];

  $self->_debug( "  propagate xvcs:id: $id" );
  $self->{MATCH_COUNT}->{$match_type}++;

  if( $old->nodeType == 3 ) {
    $self->_debug( $old->textContent." => ".$new->textContent );
  }

  if( $old->nodeType == 1 ) {
    $new->setAttribute('xvcs:id',$id);
  }

  # not sure if we need this guy
  $newlookup->{id}->{$id} = $new;

  # register the ID of the node
  $newlookup->{nodes}->{$$new}->[2] = $id;
  # wipe hash of the new node, so we can't match it again (prolly not needed)
  $newlookup->{nodes}->{$$new}->[0] = undef;
  # wipe hash of the old node, so we can't match it again
  $lookup->{nodes}->{$$old}->[0] = undef;

  # register the nodes as matched so we know not to try to add/delete them
  # and we map the old to the new for later update/move analysis
  $lookup->{match}->{$$old}         = $new;
  $lookup->{match_type}->{$$old}    = $match_type;#STRUCTURE_MATCH;
  $newlookup->{match_type}->{$$new} = $match_type;#STRUCTURE_MATCH;

  # propagate to children
  my(@new) = $new->childNodes();
  my(@old) = $old->childNodes();
  while( my $cnew = shift @new ) {
    my $cold = shift @old;
    $self->_propagateMatch( $cnew,$cold,$match_type );
  }

  return 1;
}

=pod

=head2 _matchParents

=cut
# _________________________________________________________
sub _matchParents {
  my $self  = shift;
  my $new   = shift;
  my $old   = shift;

  my $match     = 1;
  my $lookup    = $self->{old}->{lookup};
  my $newlookup = $self->{new}->{lookup};
  while ( $match ) {
    my $oldparent = $old->parentNode();
    my $newparent = $new->parentNode();

    # we check for XML::LibXML::Document to make sure we haven't
    # reached the root
    if ( ref $oldparent ne 'XML::LibXML::Document' &&
         ref $newparent ne 'XML::LibXML::Document' &&
         $oldparent->nodeName eq $newparent->nodeName() ) {
      $self->_debug( "  branch matched parents" );
      # register the nodes as matched so we know not to try to add/delete them
      # and we map the old to the new for later update/move analysis
      $lookup->{match}->{$$oldparent}         = $newparent;
      $lookup->{match_type}->{$$oldparent}    = BRANCH_MATCH;
      $newlookup->{match_type}->{$$newparent} = BRANCH_MATCH;

      #$newparent->setAttribute('xvcs:match','BRANCH');
      #$oldparent->setAttribute('xvcs:match','BRANCH');

      my $id = $lookup->{nodes}->{$$oldparent}->[2];
      #my $id = $oldparent->getAttribute('xvcs:id');

      # not sure if we need this guy
      $newlookup->{id}->{$id} = $newparent;
      $newlookup->{nodes}->{$$newparent}->[2] = $id;
      $newparent->setAttribute('xvcs:id',$id);

      # now do a lazy down matching of our children by position
      #$self->_matchSiblings( $old, $new, PRIOR );
      #$self->_matchSiblings( $old, $new, NEXT );
      $old = $oldparent;
      $new = $newparent;
    } else {
      $match = undef;
    }
  }

  return 1;
}

=pod

=head2 _markChanges

=cut
# _________________________________________________________
sub _markChanges {
  my $self       = shift;
  my $node       = shift;
  my $old        = shift;
  my $parent     = shift;
  my $lookup;
  my $match_type;
  my $pid;

  # currently we only look at Element and Text nodes (Attribute nodes
  # we handle as a known sub-element of Element nodes)
  next unless( $node->nodeType == 3 || $node->nodeType == 1 );

  #$self->_debug( "old: $old" );
  if( $old ) {
    $lookup     = $self->{old}->{lookup};
    $match_type = $lookup->{match_type}->{$$node};
  } else {
    $lookup     = $self->{new}->{lookup};
    $match_type = $lookup->{match_type}->{$$node};
  }

  if( $parent ) {
    $pid = $lookup->{nodes}->{$$parent}->[2];
    #$self->_debug( "PID:$pid" );
  }

  my $p_clone;
  if( $parent ) {
    $p_clone = $self->{clone_lookup}->{$$parent};
  }
  # we got a special case, where our node is a match, but the parent is not
  # and our node is pure text. In this case the text gets lost since we
  # don't do pure text node moves. To avoid this, we treat this matched text
  # as non-matching
  if( $node->nodeType == 3 && $match_type && $p_clone ) {
    $match_type = undef;
  }

  if( !$match_type ) {
    # we're in add/delete mode
    my $action;

    my $clone;
    if( $node->nodeType == 1 ) {
      my $doc = ($old)?'old':'new';
      $clone = $self->{$doc}->{doc}->createElement( $node->nodeName );
    } elsif( $node->nodeType == 3 ) {
      $clone = $node->cloneNode();
    }

    if( $old ) {
      $action     = DELETE;
    } else {
      $action     = INSERT;
      my $id = ++$self->{ID};

      # do we really need to track this?
      if( $node->nodeType == 1 ) {
        $node->setAttribute('xvcs:id',$id );
      }
      #$self->_debug( "$lookup->{id}->{$id} = $node" );
      $lookup->{id}->{$id} = $node;
      #$self->_debug( "$lookup->{id}->{$id} = $node" );
      $lookup->{nodes}->{$$node}->[2] = $id;
      $self->_debug( "INSERT: $pid:$id" );
      $lookup->{inserts}->{$$clone} = $id;
    }

    if( $node->nodeType == 1 ) {
      foreach my $attr ( $node->attributes() ) {
        next if( $attr->nodeName eq 'xvcs:id' );
        $clone->setAttribute($attr->nodeName,$attr->value);
      }
    }

    $self->{clone_lookup}->{$$node} = $clone;

    if( $p_clone ) {
      $p_clone->appendChild( $clone );
    } else {
      my $node_name = ($action == DELETE)?'delete':'insert';
      my $diff = $self->{diffgram}->createElement("xvcs:$node_name");
      my $id = $lookup->{nodes}->{$$node}->[2];
      $self->_registerChange($action,$pid,$diff,$id);
      $diff->appendChild( $clone );
    }
  } elsif( $old ) {
    # we got a match_type, but we only care about matches, when we are
    # traversing our own tree

    # we're in update/move mode
    my $match_node = $self->{old}->{lookup}->{match}->{$$node};
    my @update;
    if($node->nodeType == 3) {
      # TEXT node, no more children, no attributes, just text
      if( $match_node->textContent ne $node->textContent) {
        # we got a text change... For future efficiency, we should be running
        # LCS diff on that text as well.. or maybe even just plain old 'diff'
        my $old = $self->{diffgram}->createElement("xvcs:old-value");
        my $new = $self->{diffgram}->createElement("xvcs:new-value");
        $old->appendText( $node->textContent() );
        $new->appendText( $match_node->textContent() );
        push(@update,$old,$new);
      }
    } elsif( $node->nodeType == 1) {
      if( $parent && !$self->{old}->{lookup}->{match_type}->{$$parent} ) {
        # can only consider moves, if we have a parent
        # (is that a valid assumption, not just a most likely case assumption?)

        # if parents aren't matched, we've got a move
        # there's also the move within a parent scenario, but that's handled by
        # the change re-org that comes later
        my $diff     = $self->{diffgram}->createElement("xvcs:move");
        my $id       = $lookup->{nodes}->{$$node}->[2];
        my $id2      = $self->{new}->{lookup}->{nodes}->{$$match_node}->[2];
        my $m_parent = $match_node->parentNode();
        my $m_pid    = $self->{new}->{lookup}->{nodes}->{$$m_parent}->[2];

        $self->_debug( "MOVE: $pid:$id ?= $m_pid:$id2" );

        $self->_registerChange(TREE_MOVE,$pid,$diff,$id,$m_pid);

      } else {
        # parent's match, but what about position?
        my $position = $lookup->{nodes}->{$$node}->[3];
        my $match_position = $self->{new}->{lookup}->{nodes}->{$$match_node}->[3];
        if( $position != $match_position ) {
          my $id2 = $self->{new}->{lookup}->{nodes}->{$$match_node}->[2];
          my $id = $lookup->{nodes}->{$$node}->[2];
          $self->_debug( "position: $id/$position ?= $id2/$match_position" );
          $self->_registerChange(LOCAL_MOVE,$pid);
        }
      }

      # compare attributes
      my %new = map { $_->nodeName() => $_->value } $match_node->attributes();
      foreach my $attr ( $node->attributes() ) {
        my $name = $attr->nodeName();
        my $value = $attr->value();
        if( defined $new{$name} ) {
          # got the attribute
          if( $value eq $new{$name} ) {
            # same value too, leave it alone
          } else {
            # got an attribute change
            my $diff = $self->{diffgram}->createElement("xvcs:attr-update");
            $diff->setAttribute('name',$name);
            $diff->setAttribute('old-value',$value);
            $diff->setAttribute('new-value',$new{$name});
            push(@update,$diff);
          }
          # we're done with this one
          delete $new{$name};
        } else {
          # attribute delete
          my $diff = $self->{diffgram}->createElement("xvcs:attr-delete");
          $diff->setAttribute('name',$name);
          $diff->setAttribute('value',$value);
          push(@update,$diff);
        }
      }
      while(my($name,$value) = each %new ) {
        # got some attribute adds
        my $diff = $self->{diffgram}->createElement("xvcs:attr-insert");
        $diff->setAttribute('name',$name);
        $diff->setAttribute('value',$value);
        push(@update,$diff);
      }
    }
    if( @update ) {
      # updates do not affect the structure and an element could have
      # an update and then a structure changing action, so we go
      # ahead and add the updates to the diffgram now, so they don't get
      # in the way of re-ordering the actions later
      my $diff = $self->{diffgram}->createElement("xvcs:update");
      my $id = $lookup->{nodes}->{$$node}->[2];

      foreach my $update ( @update ) {
        $diff->appendChild($update);
      }
      $self->_setDiff( $pid, UPDATE,$id,$diff );
    }
  }

  foreach my $child ( $node->childNodes() ) {
    $self->_markChanges( $child, $old, $node );
  }

}

=pod

=head2 _registerChange

=cut
# _________________________________________________________
sub _registerChange {
  my $self   = shift;
  my $action = shift;
  my $pid    = shift;
  my $diff   = shift;
  my $id     = shift;
  my $m_pid  = shift;

  $self->{change_rank}++;

  my $ref = $self->{change}->{$pid};
  unless( $ref ) {
    my $source = $self->{old}->{lookup}->{id}->{$pid};
    my $target = $self->{new}->{lookup}->{id}->{$pid};
    #$self->_debug( "REG\t$action\t$pid\t$source\t$target" );
    $ref = $self->{change}->{$pid} = {
                                      rank   => $self->{change_rank},
                                      pid    => $pid,
                                      source => $source,
                                      target => $target,
                                     };
  }
  # LOCAL_MOVE just registers the parent as having changes below it,
  # but not what nodes. The LCS algorithm decides the local moves
  # so it doesn't pass $diff
  if( $action == LOCAL_MOVE ) {
    $ref->{actions}->[LOCAL_MOVE]++;
  } else {
    my $info = [$action,$id,$diff,$m_pid];
    $self->{change_registry}->{$id} = $info;
    $self->_debug( "registering change for $id" );
    push(@{$ref->{actions}->[$action]}, $info );
  }
  return 1;
}

=pod

=head2 _processChange

=cut
# _________________________________________________________
sub _processChange {
  my $self  = shift;
  my $ref   = shift;
  my $pid   = $ref->{pid};

  $self->_debug( "processing $ref->{pid}" );

  if( $ref->{done} ) {
    #$self->_debug( "already done" );
    return;
  }

  # process deletes
  if( defined $ref->{actions}->[DELETE] ) {
    foreach my $rec ( reverse @{$ref->{actions}->[DELETE]} ) {
      $self->_debug( "DELETE" );
      $self->_setDiff( $pid, @$rec );
    }
  }

  # process tree moves
  foreach my $rec ( @{$ref->{actions}->[TREE_MOVE]} ) {
    $self->_debug( "TREE MOVE" );
    $self->_setDiff( $pid, @$rec );
  }

  # process local moves
  # need to to an LCS diff on the present nodes.. This is a comparison
  # of the set as it looks post tree move and delete but pre inserts
  if( $ref->{actions}->[LOCAL_MOVE] ) {
    $self->_debug( "LOCAL MOVE" );
    $self->_local_move( $pid );
  }

  # process inserts
  if( defined $ref->{actions}->[INSERT] ) {
    foreach my $rec ( reverse @{$ref->{actions}->[INSERT]} ) {
      $self->_debug( "INSERT" );
      $self->_setDiff( $pid, @$rec );
    }
  }

  $ref->{done} = 1;
}

=pod

=head2 _local_move

=cut
# _________________________________________________________
sub _local_move {
  my $self   = shift;
  my $pid    = shift;
  my $n1 = $self->{old}->{lookup}->{id}->{$pid};
  my $n2 = $self->{new}->{lookup}->{id}->{$pid};

  if( $n1 && $n2 ) {
    my @l1;
    my @l2;
    foreach my $c1 ( $n1->childNodes() ) {
      my $id = $self->{old}->{lookup}->{nodes}->{$$c1}->[2];
      push( @l1,$id);
    }
    foreach my $c2 ( $n2->childNodes() ) {
      my $id = $self->{new}->{lookup}->{nodes}->{$$c2}->[2];
      if( defined $self->{change_registry}->{$id} ) {
        if( $self->{change_registry}->{$id}->[2]) {
          # this change hasn't been applied yet, so it's not part of
          # our LCS set
          # this presumes that all updates have already been completed
          next;
        }
      }
      push( @l2,$id);
    }
    my $move;
    traverse_sequences( \@l1, \@l2,
                        {
                         DISCARD_A => sub { $move->{$l1[$_[0]]}->[0] = $_[0]; },
                         DISCARD_B => sub { $move->{$l2[$_[1]]}->[1] = $_[1]; },
                        } );

    foreach my $id ( sort { $a <=> $b } keys %$move ) {
      my $m_ref = $move->{$id};
      if( !defined $m_ref->[0] || !defined $m_ref->[1] ) {
        # both the source and destination need to be defined.
        # theoretically we should never hit this since our algorithm
        # should guarantee that local move comparisons go only against
        # balanced sets
        $self->_debug( "$id doesn't appear in before and after, so we don't consider it a move" );
        next;
      }
      $self->_debug( "moving $id from $m_ref->[0] to $m_ref->[1]" );

      my $diff  = $self->{diffgram}->createElement("xvcs:move");
      my $source_diff  = $self->{diffgram}->createElement("xvcs:source");
      $diff->appendChild( $source_diff );
      my $destination = $self->{new}->{lookup}->{id}->{$id};
      my $source = $self->{old}->{lookup}->{id}->{$id};

      # since we're adjusting the source tree, we can blindly ask for the
      # sources previous sibling
      my $source_prior = $source->previousSibling();
      # but we do have to check if it's an element node
      my $skip = 1;
      while(1) {
        if( defined $source_prior && $source_prior->nodeType != 1) {
          # if it's not an element node, make a note of it in the diff and start the
          # loop over
          $self->_debug( "source_prior is not an element node" );
          $source_diff->setAttribute('skip',$skip);
          $skip++;
          $source_prior = $source_prior->previousSibling();
        } else {
          last;
        }
      }

      $self->_attachInstructions( $source_diff, $source, $source_prior, LOCAL_MOVE );
      my $node_to_move = $self->_applyMoveUnbind( $source_diff );

      # for the destination, we have to do a while loop, since there are
      # nodes in there that we don't recognizing as existing yet
      my $destination_prior;
      my $start = $destination;

      $skip = 1;

      while(1) {
        $destination_prior = $start->previousSibling();
        # no node, we bail
        last unless( $destination_prior );

        my $prior_id = $self->{new}->{lookup}->{nodes}->{$$destination_prior}->[2];
        if( defined $self->{change_registry}->{$prior_id} &&
            $self->{change_registry}->{$prior_id}->[2] ) {
          # this change hasn't been applied yet, so it's not part of
          # our LCS set
          $self->_debug( "prior was applied, ignore it" );
          $start = $destination_prior;
          next;
        }
        # we get here, the prior was good, but we need to check if it's a text
        # node
        if( $destination_prior->nodeType != 1) {
          # if it's not an element node, make a note of it in the diff and start the
          # loop over
          $self->_debug( "prior was text, ignore it" );
          $diff->setAttribute('skip',$skip);
          $skip++;
          $start = $destination_prior;
          next;
        }
        # if we get here, we can safely bail from the loop
        last;
      }
      $self->_attachInstructions( $diff, $destination, $destination_prior, LOCAL_MOVE, $id );

      $diff->setAttribute('id',$id);

      $self->_debug( "moved $id" );
      $self->_debug( $diff->toString(1) );

      $self->_applyMoveBind( $diff, $node_to_move );

      $self->{diffroot}->appendChild( $diff );
    }
  }
}


=pod

=head2 _setDiff

=cut
# _________________________________________________________
sub _setDiff {
  my $self   = shift;
  my $pid    = shift;
  my $action = shift;
  my $id     = shift;
  my $diff   = shift;
  my $m_pid  = shift;
  my $lookup = $self->{old}->{lookup};
  my $source;
  my $node;
  #$self->_debug( "setting $id ($action) $pid/$m_pid" );

  if( !$diff ) {#$action == NOOP ) {
    #$self->_debug( " already set" );
    return;
  } elsif( $action == DELETE ) {
    # process ourselves as a parent first
    if( $self->{change}->{$id} ) {
      $self->_debug( "  processing children of $id due to delete" );
      $self->_processChange( $self->{change}->{$id} );
      $self->_debug( "  returning from $id" );
    }
  } elsif( $m_pid ) {
    # check new parent for processing action before proceeding
    if( $self->{change_registry}->{$m_pid} ) {
      $self->_debug( "  parent $m_pid needs to be handled" );
      $self->_setDiff( $pid, @{$self->{change_registry}->{$m_pid}} );
      $self->_debug( "  done handling $m_pid" );
    }
    $lookup = $self->{new}->{lookup};
    $source = $self->{old}->{lookup}->{id}->{$id};
  }

  $node = $lookup->{id}->{$id};

  my $prior;
  my $node_to_move;
  if( $source ) {
    my $source_diff  = $self->{diffgram}->createElement("xvcs:source");
    $diff->appendChild( $source_diff );
    my $source_prior = $source->previousSibling();
    # we do have to check if it's a text node
    my $skip = 1;
    while(1) {
      if( defined $source_prior && $source_prior->nodeType != 1 ) {
        # if it's not an element node, make a note of it in the diff
        $source_diff->setAttribute('skip',$skip);
        $skip++;
        $source_prior = $source_prior->previousSibling();
      } else {
        last;
      }
    }

    $self->_attachInstructions( $source_diff, $source, $source_prior, $action );
    $node_to_move = $self->_applyMoveUnbind( $source_diff );
  }

  if( $action == UPDATE || $action == DELETE ) {
    $node = $lookup->{id}->{$id};
    $prior = $node->previousSibling();
    my $skip = 1;
    while(1) {
      if( defined $prior && $prior->nodeType != 1 ) {
        # if it's not an element node, make a note of it in the diff
        $diff->setAttribute('skip',$skip);
        $skip++;
        $prior = $prior->previousSibling();
      } else {
        last;
      }
    }
  } else {
    # INSERTs and MOVE destinations still need to ignore nodes that
    # don't yet exist in the document being modified
    my $skip = 1;
    my $prior_action;
    $lookup = $self->{new}->{lookup};
    $node = $lookup->{id}->{$id};
    my $start = $node;
    while(1) {
      $prior_action = undef;
      $prior = $start->previousSibling();
      # no node, we bail
      last unless( $prior );

      my $prior_id = $lookup->{nodes}->{$$prior}->[2];
      if( defined $self->{change_registry}->{$prior_id} &&
          $self->{change_registry}->{$prior_id}->[2] ) {
        # this change hasn't been applied yet
        $prior_action = $self->{change_registry}->{$prior_id}->[0];
        if( defined $prior_action && $prior_action <= INSERT ) {
          $start = $prior;
          next;
        }
      }
      # we get here, the prior was good, but we need to check if it's
      # an element node
      if( $prior->nodeType != 1 ) {
        # if it's not an element node, make a node of it in the diff and start the
        # loop over
        $diff->setAttribute('skip',$skip);
        $skip++;
        $start = $prior;
        next;
      }
      # if we get here, we can safely bail from the loop
      last;
    }
  }

  $self->_debug( "  attaching instructions" );
  $self->_attachInstructions( $diff, $node, $prior, $action, $id );

  if( $action == TREE_MOVE ) {
    # move's are special, they have to happen as two separate actions
    # so we can't just call the appropriate patch method and be done
    $self->_debug( "  doing bind action of move" );
    $self->_applyMoveBind( $diff, $node_to_move );
  } else {
    # find the appropriate patch method and let it manipulate ourselves
    $self->_debug( "  now apply our action" );
    $self->_applyAction( $action, $diff );
  }

  $self->{diffroot}->appendChild( $diff );
}

=pod

=head2 _attachInstructions

=cut
# _________________________________________________________
sub _attachInstructions {
  my $self   = shift;
  my $diff   = shift;
  my $node   = shift;
  my $prior  = shift;
  my $action = shift;
  my $id     = shift;
  my $parent = $node->parentNode;

  if( $id ) {
    $diff->setAttribute('id',$id);
  }

  $self->_debug( $self->{old}->{lookup}->{id}->{12} );
  $self->_debug( $self->{old}->{lookup}->{id}->{13} );

  if( $prior ) {
    if( $action == INSERT ||
        ( $action <= LOCAL_MOVE && $id )
      ) {
      # if its an insert or the insert portion of a move
      # we need to find the matching node in our current document to 
      # apply this to
      my $prior_id   = $self->{new}->{lookup}->{nodes}->{$$prior}->[2];

      $prior  = $self->{old}->{lookup}->{id}->{$prior_id};

      $self->_debug( "sibling action ($prior_id)" );
    }

    $diff->setAttribute('follows',$prior->nodePath());

  } else {
    if( $action == INSERT ||
        ( $action <= LOCAL_MOVE && $id )
      ) {
      # if its an insert or the insert portion of a move
      # we need to find the matching node in our current document to 
      # apply this to
      my $pid = $self->{new}->{lookup}->{nodes}->{$$parent}->[2];

      $parent = $self->{old}->{lookup}->{id}->{$pid};

      $self->_debug( "first child action ($pid)" );
    }

    $diff->setAttribute('first-child-of',$parent->nodePath());
  }

  if( $id && defined $self->{change_registry}->{$id} ) {
    $self->_debug( "marking $id as done" );
    $self->{change_registry}->{$id}->[2] = undef;
  }

  if( $XML::Diff::DEBUG ) {
    $self->_debug( "state ---\n".$self->{old}->{root}->toString(1)."\n" );
  }

  return 1;
}

=pod

=head2 _applyAction

=cut
# _________________________________________________________
sub _applyAction {
  my $self   = shift;
  my $action = shift;
  my $diff   = shift;

  if( $action == INSERT ) {
    $self->_applyInsert( $diff );
  } elsif( $action == UPDATE ) {
    $self->_applyUpdate( $diff );
  } else {
    $self->_applyDelete( $diff );
  }

}

=pod

=head2 _applyInsert

=cut
# _________________________________________________________
sub _applyInsert {
  my $self    = shift;
  my $patch   = shift;

  $self->_debug( 'apply insert' );

  my $follows = $patch->getAttribute('follows');
  my $skip    = $patch->getAttribute('skip');
  my $before;
  my $node ;

  if( $self->{_MODE} == COMPARE ) {
    # if we're calling this in the compare phase, we gotta do some node swapping
    # on the patch since we use the nodes object IDs to do lookups on, i.e. the
    # set attached to the diffgram is the physical one we have to insert, while
    # the diffgram gest rewritten with a clone
    ($node)   = $patch->childNodes();
    my $clone = $node->cloneNode(1);
    $patch->removeChild( $node );
    $patch->appendChild( $clone );
  } else {
    # in the patch phase we don't have to play the above tricks and can insert
    # a clone directly
    my($child) = $patch->childNodes();
    $node      = $child->cloneNode(1);
  }

  $self->_debug( $node->toString(1) );
  my $sibling;
  if( !$follows ) {
    my $parent_path = $patch->getAttribute('first-child-of');
    my($parent)  = $self->{old}->{root}->findnodes( $parent_path );
    return undef unless( defined $parent );
    $sibling = $parent->firstChild();
    $self->_debug( "not follows - sibling: ".$sibling->toString(1) );
    if( !$sibling ) {
      $parent->appendChild( $node );
      return 1;
    } elsif( $skip ) {
      for(my$i=1;$i<$skip;$i++) {
        $self->_debug( '..skipping node' );
        $sibling = $sibling->nextSibling();
        return undef unless( defined $sibling );
      }
    } else {
      # we really are the first child, so we need to do an insert before
      $before = 1;
    }
  } else {
    ($sibling) = $self->{old}->{root}->findnodes( $follows );
    $self->_debug( "sibling: ".$sibling->toString(1) );
    return undef unless( defined $sibling );
    if( $skip ) {
      for(my$i=0;$i<$skip;$i++) {
        $self->_debug( '..skipping node' );
        $sibling = $sibling->nextSibling();
        return undef unless( defined $sibling );
      }
    }
  }

  my $n = $node->nodeName();
  my $s = $sibling->nodeName();

  if( $before ) {
    $self->_debug( "first child, therefore insert before" );
    $sibling->parentNode->insertBefore( $node, $sibling );
  } else {
    $self->_debug( "insert $n after $s" );
    $sibling->parentNode->insertAfter( $node, $sibling );
  }

  $self->_debug( "MODE: $self->{_MODE}" );
  if( $self->{_MODE} == COMPARE ) {
    # if we're applying in COMPARE node, we need to register this node
    # in our lookup

    $self->_debug( "patch:\n".$patch->toString(1) );
    $self->_insertRegister( $node );
    # first get it's ID
    #my $id = $patch->getAttribute( 'id' );

    # and now we need to put this node in the lookup
    #$self->{old}->{lookup}->{id}->{$id} = $node;
    #$self->{old}->{lookup}->{nodes}->{$$node} = [undef,undef,$id];

    #$self->_debug( "registering new node $id" );
  }

  return 1;
}

=pod

=head2 _insertRegister

=cut
# _________________________________________________________
sub _insertRegister {
  my $self   = shift;
  my $node   = shift;

  my $id = $self->{new}->{lookup}->{inserts}->{$$node};

  $self->{old}->{lookup}->{id}->{$id} = $node;
  $self->{old}->{lookup}->{nodes}->{$$node} = [undef,undef,$id];

  $self->_debug( "registering new node $id" );
  foreach my $child ( $node->childNodes() ) {
    $self->_insertRegister( $child );
  }
}

=pod

=head2 _applyUpdate

=cut
# _________________________________________________________
sub _applyUpdate {
  my $self    = shift;
  my $patch   = shift;

  $self->_debug( 'apply update' );

  my $follows = $patch->getAttribute('follows');
  my $text    = $patch->getAttribute('skip');
  my $node;
  if( !$follows ) {
    my $parent_path = $patch->getAttribute('first-child-of');
    my($parent)  = $self->{old}->{root}->findnodes( $parent_path );
    return undef unless( defined $parent );
    $node = $parent->firstChild();
  } else {
    my($sibling) = $self->{old}->{root}->findnodes( $follows );
    return undef unless( defined $sibling );
    ($node) = $sibling->nextSibling();
  }
  return undef unless( defined $node );
  if(  $patch->getAttribute('skip') ) {
    $node = $node->nextSibling();
    return undef unless( defined $node );
  }
  foreach my $update ( $patch->childNodes() ) {
    my $name = $update->nodeName();
    for( $update->nodeName() ) {
      /xvcs:attr-delete/ &&
        do {
          $node->removeAttribute( $update->getAttribute('name') );
          last;
        };
      /xvcs:attr-insert/ &&
        do {
          $node->setAttribute( $update->getAttribute('name'),$update->getAttribute('value') );
          last;
        };
      /xvcs:attr-update/ &&
        do {
          $node->setAttribute( $update->getAttribute('name'),$update->getAttribute('new-value') );
          last;
        };
      /new-value/ &&
        do {
          $node->setData( $update->textContent );
          last;
        };
      last;
    }
  }

  return 1;
}

=pod

=head2 _applyDelete

=cut
# _________________________________________________________
sub _applyDelete {
  my $self    = shift;
  my $patch   = shift;

  $self->_debug( 'apply delete' );

  my $follows = $patch->getAttribute('follows');
  my $text    = $patch->getAttribute('skip');
  my $node;
  if( !$follows ) {
    my $parent_path = $patch->getAttribute('first-child-of');
    my($parent)  = $self->{old}->{root}->findnodes( $parent_path );
    return undef unless( defined $parent );
    $node = $parent->firstChild();
  } else {
    my($sibling) = $self->{old}->{root}->findnodes( $follows );
    return undef unless( defined $sibling );
    ($node) = $sibling->nextSibling();
  }
  return undef unless( defined $node );
  if(  $patch->getAttribute('skip') ) {
    $node = $node->nextSibling();
    return undef unless( defined $node );
  }
  my $n = $node->nodeName();
  #print STDERR "deleting $n\n";
  #print STDERR $patch->toString(1),"\n";
  $node->unbindNode();

  return 1;
}

=pod

=head2 _applyMove

=cut
# _________________________________________________________
sub _applyMove {
  my $self    = shift;
  my $patch   = shift;
  my($source) = $patch->childNodes();

  $self->_debug( 'apply move' );

  my $node = $self->_applyMoveUnbind( $source );

  if( defined $node && $self->_applyMoveBind( $patch, $node ) ) {

    return 1;

  } else {

    return undef;
  }
}

=pod

=head2 _applyMoveUnbind

=cut
# _________________________________________________________
sub _applyMoveUnbind {
  my $self    = shift;
  my $source  = shift;
  my $follows = $source->getAttribute('follows');
  my $node;

  $self->_debug( '  move unbind' );

  # find node to move
  if( !$follows ) {
    my $parent_path = $source->getAttribute('first-child-of');
    my($parent)  = $self->{old}->{root}->findnodes( $parent_path );
    return undef unless( defined $parent );
    $node = $parent->firstChild;
  } else {
    my($sibling) = $self->{old}->{root}->findnodes( $follows );
    return undef unless( defined $sibling );
    ($node) = $sibling->nextSibling();
  }

  return undef unless( defined $node );

  if( $source->getAttribute('skip') ) {
    $node = $node->nextSibling();
    return undef unless( defined $node );
  }

  # remove node from tree, so that our Xpaths are expressed properly
  $node->unbindNode();
  $self->_debug( "unbound:".$node->toString(1) );

  return $node;
}

=pod

=head2 _applyMoveBind

=cut
# _________________________________________________________
sub _applyMoveBind {
  my $self    = shift;
  my $patch   = shift;
  my $node    = shift;
  my $follows = $patch->getAttribute('follows');
  my $text    = $patch->getAttribute('skip');
  my $sibling;

  $self->_debug( '  move bind' );

  $self->_debug( $patch->toString(1) );
  $self->_debug( $node->toString(1) );

  my $n = $node->nodeName();

  if( !$follows ) {
    my $parent_path = $patch->getAttribute('first-child-of');
    $self->_debug( "looking for first child: $parent_path" );
    #$self->_debug( $self->{old}->{root}->toString(1) );
    my($parent)  = $self->{old}->{root}->findnodes( $parent_path );

    return undef unless( defined $parent );

    $sibling = $parent->firstChild();

    if( !$sibling ) {
      $parent->appendChild( $node );
      my $p = $parent->nodeName();
      $self->_debug( "move $n as first child of $p" );

      return 1;

    } elsif( $text ) {
      # this means we really are the next sibling
      # so we don't need to do anything further here
      $self->_debug( "first child was text:".$sibling->textContent() );

    } else {
      # we really are the first child, so we need to do an insert before
      $parent->insertBefore( $node, $sibling );
      my $s = $sibling->nodeName();
      $self->_debug( "move $n before $s" );
      return 1;
    }
  } else {

    ($sibling) = $self->{old}->{root}->findnodes( $follows );

    return undef unless( defined $sibling );

    # the multi-count after_text is a hack until we can order our
    # actions properly, since there really can't be two consecutive
    # text nodes in XML parsed from a file, they're just be read as one
    # node.
    while( $text ) {
      $sibling = $sibling->nextSibling();

      return undef unless( defined $sibling );

      $text--;
    }
  }

  my $s = $sibling->nodeName();

  $self->_debug( "move $n after $s" );
  my $parent = $sibling->parentNode();
  $parent->insertAfter( $node, $sibling );

  return 1;
}

=pod

=head2 _debug

=cut
# _________________________________________________________
sub _debug {
  return unless $XML::Diff::DEBUG;
  my $self = shift;
  my $msg  = shift;
  print STDERR    "$msg\n";
}

=pod

=head1 AUTHOR

Arne Claassen  <sdether@cpan.org>

=head1 MAINTAINER

Tim Meadowcroft  <timm@cpan.org>

=head1 VERSION

0.05

=head1 COPYRIGHT

2004, 2007 Arne F. Claassen, All rights reserved.

=cut


1;
