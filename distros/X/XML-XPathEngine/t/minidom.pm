#!/usr/bin/perl -w

use strict;
use warnings;

my $dom= minidom::document->new( '<root att1="1" id="r-1">
    <kid att1="1" att2="vv" id="k-1">
        <gkid1 att2="vv" id="gk1-1">vgkid1-1</gkid1>
        <gkid2 att2="vx" id="gk2-1">vgkid2-1</gkid2>
    </kid>
    <kid att1="2" att2="vv" id="k-2">
        <gkid1 att2="vv" id="gk1-2">vgkid1-2</gkid1>
        <gkid2 att2="vx" id="gk2-2">vgkid2-2</gkid2>
    </kid>
    <kid att1="3" att2="vv" id="k-3">
        <gkid1 att2="vv" id="gk1-3">vgkid1-3</gkid1>
        <gkid2 att2="vx" id="gk2-3">vgkid2-3</gkid2>
    </kid>
    <kid att1="4" att2="vv" id="k-4">
        <gkid1 att2="vv" id="gk1-4">vgkid1-4</gkid1>
        <gkid2 att2="vx" id="gk2-4">vgkid2-4</gkid2>
    </kid>
    <!-- a comment -->
    <kid att1="5" att2="vv" id="k-5">
        <gkid1 att2="vv" id="gk1-5">vg <!-- an other comment -->kid1-5</gkid1>
        <gkid2 att2="vx" id="gk2-5">vgkid2-5</gkid2>
    </kid>
</root>');

use Data::Dumper;
print Dumper $dom;

package minidom::node;

my $parent=0;
my $pos=1;
my $rank=2;

sub isElementNode {}
sub isAttributeNode {}
sub isNamespaceNode {}
sub isTextNode {}
sub isProcessingInstructionNode {}
sub isPINode {}
sub isCommentNode {}
  
sub getParentNode { return  $_[0]->[$parent]; }
sub pos           { return $_[0]->[$pos]; }
sub getRootNode {
    my $self = shift;
    while (my $parent = $self->getParentNode) {
        $self = $parent;
    }
    return $self;
}
sub getChildNodes {
    return wantarray ? () : [];
}
sub getAttributes {
    return wantarray ? () : [];
}

sub getPreviousSibling {
    my $self = shift;
    my $rank = $self->[$rank];
    return unless $self->[$parent];
    return $rank ? $self->[$parent]->getChildNode($rank-1) : undef;
}

sub getNextSibling {
    my $self = shift;
    my $rank = $self->[$rank];
    return unless $self->[$parent];
    return $self->[$parent]->getChildNode($rank+1);
}

sub getChildNode { return }

1;

package minidom::document;
use base 'minidom::node';

sub new
  { my( $class, $string)= @_;
    ( my $base_class= $class)=~ s{::[^:]*$}{};
    my $i=0;
    $string=~ s{<!--(.*?)-->}{[[ bless( [ '$1'], '${base_class}::comment') ]]}sg;
    $string=~ s{<\?(\w+)(.*?)\?>}{[[ bless( [ '$1', '$2'], '${base_class}::pi') ]]}sg;
    while( $string=~ m{^<})
      { $string=~ s{<([^/>]*)>([^<]*)</([^>]*)>}
                   { parse_elt( $base_class, $1, $2, $3); }eg;
      }
    $string=~ s{\[\[}{\[}g;  # remove marker before root
    $string=~ s{\]\]}{\],}g; #               after

    my $data= eval( $string);
    my $self= bless $data, $class;
    $self->add_pos_parent();
    return $self;
  }

{ my $pos;
sub add_pos_parent
  { my( $self)= @_;
    unless( $pos) { unshift @$self, undef, ++$pos, 0; }
    my @children= @$self; shift @children; shift @children; shift @children;
    my $rank=1;
    foreach my $child (@children)
      { if( UNIVERSAL::isa( $child, 'ARRAY'))
          { warn "adding pos ($pos) and parent for $child->[0] (", ref($child), ")\n";
            unshift @$child, $self, ++$pos, $rank++;
            add_pos_parent( $child)
          }
      }
  }
}

sub parse_elt
  { my( $base_class, $start_tag, $content, $end_tag)= @_;
    $start_tag=~ s{^}{'};
    $start_tag=~ s{ }{', [};         # after the first space, start the atts 
    $start_tag=~ s{([\w:-]+)\s*=\s*("[^"]*"|'[^']')}{bless( [ "$1", $2 ], '${base_class}::attribute'), }g;
    $start_tag=~ s{, $}{]};          # end the atts, ready for content
    my @content= split /(\[\[.*?\]\])/s, $content;
    foreach (@content)
      { if( m{^\[\[})                 # embedded elements
          {  s{^\[\[}{}; s{\]\]}{}; } # remove '[[' 
        else
          { s{^}{bless( ['}s, s{$}{'], '${base_class}::text')}s; }    # text, quote it
      }
    $content= join( ', ', @content);
    return "[[ bless(  [ $start_tag, $content ], '${base_class}::element') ]]";
  }
    
1;           

package minidom::element;
use base 'minidom::node';

my $attributes=3;
my $content=4;

sub getChildNode
  { my( $self, $rank)= @_;
    return $self->[$rank+$content];
  }

sub getChildNodes
  { my( $self, $rank)= @_;
    my @content= @$self;
    foreach( 1..$content) { shift @content; }
    return wantarray ? @content : \@content;
  }



1;


