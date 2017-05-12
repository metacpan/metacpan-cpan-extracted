#-*-perl-*-
#####################################################################
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Author$
# $Id$
#
###########################################################################
#
###########################################################################


package Uplug::Data;

use strict;
use vars qw( @ISA @EXPORT $DEFAULTDELIMITER $DEFAULTROOTLABEL);
use Exporter;
use Data::Dumper;

use Uplug::Data::Node;
use Uplug::Encoding;
use Encode;


@ISA=qw( Exporter);
@EXPORT = qw( $DEFAULTDELIMITER $DEFAULTROOTLABEL);

$DEFAULTDELIMITER=' ';
$DEFAULTROOTLABEL='text';


sub DESTROY{
    my $self=shift;
    if (ref($self->{ROOT})){$self->{ROOT}->DESTROY();}
    delete $self->{ROOT};
}


sub new{
    my $class=shift;
    my $self={};
    bless $self,$class;
    $self->init(@_);
    return $self;
}

#---------------------------------
# init(label,attributes,option => value, ...)
#    label ..... data root label
#    attr ...... root node attributes
#    options:
#             


sub init{
    my $self=shift;
    my ($label,$attr,%options)=@_;
    if (defined $label){$self->setRoot($self->createNode($label,$attr));}
    else{$self->setRoot(undef);}
    foreach (keys %options){$self->{$_}=$options{$_};}
}

#---------------------------------------------

sub option{return $_[0]->{$_[1]};}      # get object-property
sub setOption{$_[0]->{$_[1]}=$_[2];}    # set object-property

#---------------------------------------------

sub root{return $_[0]->{ROOT};}                # get root node
sub getRootNode{return $_[0]->root();}         # get root node
sub setRoot{
    if (ref($_[0]->{ROOT})){                   # if there's a root node
	$_[0]->{ROOT}->DESTROY();              # destroy it!
    }
    delete $_[0]->{ROOT};
    $_[0]->{ROOT}=$_[1];                       # set the new root node
}

#----------------------------------------------

sub header{return $_[0]->{HEADER};}       # get data header (string)
sub setHeader{$_[0]->{HEADER}=$_[1];}     # set data header
sub addHeader{$_[0]->{HEADER}.=$_[1];}    # add string to data header

sub tail{return $_[0]->{TAIL};}           # data tail (string)
sub setTail{$_[0]->{TAIL}=$_[1];}
sub addTail{$_[0]->{TAIL}.=$_[1];}

#--------------------------------------------------
# parent($NODE) ............... return parent of node $NODE
# setParent($NODE,$PARENT) .... set parent of node $NODE

sub parent{if (ref($_[1])){return $_[1]->parent();}}
sub setParent{if (ref($_[1])){return $_[1]->setParent($_[2]);}}

#--------------------------------------------------------------------
# createNode
#   createNode(label,attr,content,parent)
#        label ..... data label
#        attr ...... optional reference to an attribute hash
#        content ... optional content string
#        parent .... optional reference to parent node
#

sub createNode{
    my ($self,$label,$attr,$content,$parent)=@_;
    my $node=Uplug::Data::Node->new($label,$attr,$parent);
    if (defined $content){$node->addTextNode($content);}
    return $node;
}

#--------------------------------------------------------------------
# createTextNode
#

sub createTextNode{
    my ($self,$content,$node)=@_;
    if (not ref($node)){$node=Uplug::Data::Node->new();}
    return $node->createTextNode($content);
}

#--------------------------------------------------------------------
# delNode .... detach a node from its parent

sub delNode{
    my $self=shift;
    my $node=shift;
    if (not ref($node)){return undef;}
    $node->detach();
}


#--------------------------------------------------------------------
# addNode
#   1) addNode(child) ................... add a child to the root node
#   2) addNode(parent,child) ............ add a child to parent
#   3) addNode(label,attr,content) ...... add a new child node to the root node
#   4) addNode(parent,label,attr,content) add a new child node to parent
#

sub addNode{
    my $self=shift;

    my $parent;
    if (ref($_[0]) and (@_==1)){$parent=$self->root();}      # 1) child to root
    elsif (not ref($_[0])){$parent=$self->root();}           # 3) get root
    else{$parent=shift;}                                     # 2) & 4)

    my @nodes=();
    if (ref($_[0])){@nodes=@_;}              # all arguments are children nodes
    else{$nodes[0]=$self->createNode(@_);}   # create a new child-node

    my @added=();
    if (not ref($parent)){                   # no parent? --> there is no root!
	$self->setRoot(shift(@nodes));       # --> set first node as root
	push (@added,$self->root());
    }
    foreach my $n (@nodes){                             # add all nodes
	push (@added,$parent->addContent($n));
	$self->setParent($n,$parent);                   # set parent
    }
    return wantarray ? @added : $added[-1];
}



#--------------------------------------------------------------------
# findNodes .... find nodes with certain labels and attributes
#
#       1) @nodes = $data->findNodes()
#       2) @nodes = $data->findNodes($labelRE)
#       3) @nodes = $data->findNodes($labelRE,\%attr)
#
#
#   $labelRE: label pattern                               (regular expression)
#   %attr:    attribute value pairs for matching a node   (hash)
#
#   @nodes:   array of nodes
#


sub findNodes{
    my $self=shift;
    my ($labelRE,$attr,$node,$match)=@_;

    if (not defined $labelRE){$labelRE='.*';}        # default: match all!
    if (not defined $node){$node=$self->root();}     # start at root
    if (not defined $node){return undef;}            # no root node found!
    if (not defined $match){$match=[];}              # initialize return-array

    my $label=$node->label();                        # get the node-label
    if ($label=~/^$labelRE$/){                       # and check it
	if ((ref($attr) ne 'HASH') or                # if the attribute-pattern
	    ($node->matchAttr($attr))){              #    is set --> try to 
	    push (@{$match},$node);                  #    match it
	}
    }
    foreach my $c ($node->children()){               # check all children nodes
	if (not ref($c)){next;}                      # (only if not scalar)
	$self->findNodes($labelRE,$attr,$c,$match);
    }
    return @{$match};
}

#--------------------------------------------------------------------
# delNodes ..... delete nodes
#
# 1) delNodes(@NODES) .......... delete all nodes in @NODES
# 2) delNodes(labelRE,$attr).... delete all nodes which match labelRE & attr
#                                (uses findNodes)
#

sub delNodes{
    my $self=shift;

    my @nodes=();
    if (ref($_[0])){@nodes=@_;}
    else{@nodes=$self->findNodes(@_);}
    foreach my $n (@nodes){$self->delNode($n);}
}

#--------------------------------------------------------------------
# contentNodes .... return all content nodes
#
#       @nodes = $data->contentNodes()
#
#

sub contentNodes{
    my $self=shift;
    my ($node,$match)=@_;

    if (not ref($node)){$node=$self->root();}        # no node --> root node
    if (not ref($node)){return undef;}               # no root node --> return
    if (not defined $match){$match=[];}              # initialize return-array
    if ($node->isTextNode()){                        # check if the current
	push (@{$match},$node);                      # node is a text node
    }
    foreach my $c ($node->children()){               # check all children nodes
	if (not ref($c)){next;}                      # (only if not scalar)
	$self->contentNodes($c,$match);
    }
    return @{$match};
}

#--------------------------------------------------------------------
# contentElements .... return all nodes that contain a text-node!
#
#       @nodes = $data->contentElements()
#
#

sub contentElements{
    my $self=shift;

    my @nodes=$self->contentNodes(@_);
    my @elements=();
    foreach my $n (@nodes){
	if (not ref($n)){next;}
	my $parent=$n->parent();
	if ($parent){push (@elements,$parent);}
    }
    return @elements;
}


sub contentNodesEncoded{
    my $data     = shift;
    my $encoding = shift;
    my $tokens   = shift;

    my @nodes=$data->contentElements;
#    my @nodes=$data->findNodes('w');

    unless ($encoding=~/utf-?8/i){
	my @content = ();
	$tokens = [] unless (ref($tokens) eq 'ARRAY');
	foreach my $c (@nodes){
	    next unless (ref($c));
	    my $str = decode($encoding, encode($encoding, $c->content,sub{ return '' }) );
	    if ( $str=~/\S/ ){
		push(@content,$c);
		push(@{$tokens},$str);
	    }
	}
	return @content;
    }
    @{$tokens}=$data->content(\@nodes) if (ref($tokens) eq 'ARRAY');
    return @nodes;
}



#--------------------------------------------------------------------
# attribute .... return value of a node attribute
#
# 1) attribute(node,key) ..... return value of attribute 'key' in node
# 2) attribute(key) .......... return value of attribute 'key' in root-node
# 3) attribute(\@nodes,key) .. return values of attribute 'key' in all nodes
#
# if key is undefined ---> return reference to attribute-value hash!


sub attribute{
    my $self=shift;

    if (ref($_[0]) eq 'ARRAY'){           # 3) first argument = node-array
	my $nodes=shift;my @attr=();      #    --> collect all attributes
	foreach my $n (@{$nodes}){        #        from all nodes
	    push (@attr,$self->attribute($n,@_));
	}
	return wantarray ? @attr : \@attr;
    }
    my $node;
    if (ref($_[0])){$node=shift;}         # 1) node is psecified
    else{$node=$self->root();}            # 2) node=root-node
    if (not ref($node)){return undef;}    # no node found -> return undef

    if (defined $_[0]){return $node->attribute($_[0]);} # return attr.-value
    else{return $node->attributes();}                   # return attr.-hash
    
}


#--------------------------------------------------------------------
# setAttribute .... set attribute value in a node
#
# 1) setAttribute(node,key,value,...) ..... set attributes in node 'node'
# 2) setAttribute(key,value,...) .......... set attributes in root-node
# 3) setAttribute($node,\%hash) ........... set attribute 'key' in 'node'
# 4) setAttribute(\%hash) ................. set attribute 'key' in root-node


sub setAttribute{
    my $self=shift;

    my $node;
    if (ref($_[0]) and (ref($_[0]) ne 'HASH')){$node=shift;} # 1) node as arg.
    else{$node=$self->root();}                               # 2) root-node

    if (not ref($node)){$node=$self->addNode();}# undefined node -> new root!
    if (not ref($node)){return undef;}          # still undefined? -> return
    my %attr=();
    if (ref($_[0]) eq 'HASH'){%attr=%{$_[0]};}  # first argument=hash-reference
    else{%attr=@_;}                             # arguments=attribute-hash
    return $node->setAttribute(%attr);          # set attributes of the node
}

#--------------------------------------------------------------------
# setAttributes .... set attributes in several nodes
#
#  setAttributes(\@nodes,@attr)
#
#   @nodes ..... array of nodes
#   @attr ...... array of attribute-value hashs

sub setAttributes{
    my $self=shift;

    my $nodes=shift;
    my $attr=shift;

    if (ref($nodes) ne 'ARRAY'){return;}
    if (ref($attr) ne 'ARRAY'){return;}

    foreach (0..$#{$nodes}){
	if (ref($attr->[$_]) ne 'HASH'){next;}
	$self->setAttribute($nodes->[$_],%{$attr->[$_]});
    }
}

#--------------------------------------------------------------------
# setContentAttribute .... set attribute value in content nodes
#
#  setContentAttribute($attr,@values)
#  setContentAttribute($attr,\@values)
#


sub setContentAttribute{
    my $self=shift;
    my $attr=shift;

    my @val=@_;
    if (ref($_[0]) eq 'ARRAY'){@val=@{$_[0]};}
    my @nodes=$self->contentElements();
    foreach my $n (@nodes){
	$self->setAttribute($n,$attr,shift(@val));
	if (not @val){last;}
    }
}

#--------------------------------------------------------------------
# delAttribute .... delete an attribute in a node
#
# 1) delAttribute(node,key) ..... delete attribute 'key' in node 'node'
# 2) delAttribute(key) .......... delete attribute 'key' in root-node


sub delAttribute{
    my $self=shift;

    my $node;
    if (ref($_[0])){$node=shift;}         # 1) node is psecified
    else{$node=$self->root();}            # 2) node=root-node
    if (not ref($node)){return undef;}    # 3) no node found -> return undef

    return $node->delAttribute(@_);       # set attribute-value of the node
}


#--------------------------------------------------------------------
# content ...... return content-string
#
#    1) content(@NODES) ........ return content of all nodes @NODES
#    2) content(\@NODES) ....... return content of all nodes @NODES
#
# if @NODES is undefined --> return content of root-node
#
# return value:
#     @content ..... 'array of content strings' in array context
#     $content ..... content-string for all nodes joined together
#                    (using CONTENTDELIMITER string)
#

sub content{
    my $self=shift;

    my @nodes=();
    if (ref($_[0]) eq 'ARRAY'){@nodes=@{$_[0]};}
    elsif (ref($_[0])){@nodes=@_;}
    else{$nodes[0]=$self->root();}

    my $del=$DEFAULTDELIMITER;
    my @content=();
    foreach my $n (@nodes){
	if (not ref($n)){next;}
	my @children=$n->content($del);
	push (@content,@children);
    }
    return wantarray ? @content : join ($del,@content);
}


#--------------------------------------------------------------------
# setContent
#
#    1) setContent($string,$label)  ........ set content in root node
#    2) setContent($node,$string,$label) ... set content in specific $node
#
# string ...... content string (create a text node as one and only child-node)
# label ....... optional! change label of the node


sub setContent{
    my $self=shift;

    my $node;
    if (ref($_[0])){$node=shift;}  # 1st argument = reference -> node-reference
    else{$node=$self->root();}     # else -> get root-node
    my $string=shift;

    if (not ref($node)){
	$node=$self->createNode($DEFAULTROOTLABEL);
	$self->setRoot($node);
    }

    # create a new text-node as the one and only content
    if (defined $string){$node->setContent($node->createTextNode($string));}

    # or delete all content
    else{$node->delContent();}

    # set a label if specified
    if (defined $_[0]){$node->setLabel($_[0]);}
}

#-------------------------------------------
# addContent

sub addContent{
    my $self=shift;
    my $node;
    if (ref($_[0])){$node=shift;}
    else{$node=$self->root();}
    if (not ref($node)){$node->addNode(@_);}  # no root node --> create new one
    if (defined $_[0]){$node->addTextNode($_[0]);}    # add a new text node
}



#--------------------------------------------------
# label ...... return data label of a node
#
#   1) label(node) ........ label of node
#   2) label() ............ label of root node
#

sub label{
    my $self=shift;
    my $node;
    if (ref($_[0])){$node=shift;}
    else{$node=$self->root;}
    if (ref($node)){$node->label($_[0]);}
}


#--------------------------------------------------
# setLabel ...... set label of a node
#
#   1) setLabel(node,label) ....... set label of node
#   2) setLabel(label) ............ set label of root node
#

sub setLabel{
    my $self=shift;
    my $node;
    if (ref($_[0])){$node=shift;}
    else{$node=$self->root;}
    if (ref($node)){$node->setLabel($_[0]);}
}





#--------------------------------------------------------------------
# taken from Object::Clone
# http://usr.bin.dk/~jonasbn/perl/ObjectClone.html
# 
# use Data::Dumper;
# sub clone {
#        my $self = shift;
#
#        my $VAR1;
#        my $copy_dump = Dumper $self;
#        eval $copy_dump; warn $@ if $@;
#        return $VAR1;
# }

sub clone{return Uplug::Data->new();}
#    return $_[0]->new();

#--------------------------------------------------------------------
# subData .... return a sub-data object
#
#      1) $subdata=subData($subData,$labelRE,\%attr)
#      2) $subdata=subData($labelRE,\%attr)
#
#  subdata is a clone of this object
#  the root of subdata is the first node that matches labelRE and attr
#  (using findNodes)
#


sub subData{
    my $self=shift;
    my $data;
    if (ref($_[0])){$data=shift;}
    else{$data=$self->clone();}
    if (not ref($data)){return undef;}   # could not clone myself
    my ($node)=$self->findNodes(@_);     # find first matching node
    $data->setRoot($node);               # set root-node
    return $data;                        # return subdata object
}










#--------------------------------------------------------------------
# splitContent
#
#  1) @NewNodes = $object->splitContent($node,$label,\@segments)
#  2) @NewNodes = $object->splitContent($labeRE,\%NodeAttr,$label,\@segments)
#
#      $node:     parent node
#      $label:    label for new children nodes                    (string)
#      @segments: array of strings to replace the former content  (array)
#      %NodeAttr: attribute-value pairs for finding a node        (hash)
#
#      @NewNodes: array of new nodes
#
# Note:
#   if splitContent finds more than one node that matches $labelRE and
#   %NodeAttr ---> splitContent splits only the first node!
#


sub splitContent{
    my $self=shift;

    my $node=shift;
    if (not ref($node)){
	my $labelRE=$node;
	my $attr=shift;
	($node)=$self->findNodes($labelRE,$attr);
    }
    if (not ref($node)){return ();}
    my $label=shift;
    my $segments=shift;
    if (ref($segments) ne 'ARRAY'){return ();}

#------------------------------------------------------------------------

    my @contentNodes=$self->contentNodes();      # get all content nodes
    my @content=$self->content(@contentNodes);   # and their content
    my @children=();

#------------------------------------------------------------------------

    foreach my $s (@{$segments}){                # foreach text-segment:
	my @chunk=(shift @contentNodes);         # - take the next text-node
	my @chunkContent=(shift @content);       # - save its content
	my $text=$chunkContent[-1];              # - the text
	my $pat=quotemeta($s);                   # - pattern of the segment
	while ($text!~/$pat/s){                  # - add more text nodes
	    if (not @contentNodes){last;}        #   as long as the segment
	    push(@chunkContent,shift @content);  #   is not completely
	    push(@chunk,shift @contentNodes);    #   included in the text
	    $text.=$DEFAULTDELIMITER;            #   (text-node deilimiter!)
	    $text.=$chunkContent[-1];            #   (append new text)
	}
	if (not @chunk){next;}                   # - no nodes -> next segment
#------------------------------------------------------------------------
	if ($text=~/($pat)(.*)$/s){          # - there's something behind
	    my $str1=$1;                         #   the text-segment which
	    my $str2=$2;                         #   has to be removed from
	    my $pat2=quotemeta($str2);           #   the last text-node
	    my $this=$chunkContent[-1];          # * this is the last text-node
#	    if ($this=~/^(.*)$pat2$/s){          #   which has to be split
#		$str1=$1;                        #   between $str1 and $str2
#	    }
	    if ($this=~/(.*)$pat2$/s){           #   which has to be split
		$str1=$1;                        #   between $str1 and $str2
	    }
#------------------------------------------------------------------------
	    my ($before,$after)=                     # split the last text-node
		$self->splitContentNode($chunk[-1],  # between str1 and str2
					$str1,       # before and after are the
					$str2);      # new text-nodes!
	    $chunk[-1]=$before;                      # last node in the chunk
	    $chunkContent[-1]=
		$self->content($chunk[-1]);          # and its content
#------------------------------------------------------------------------
	    if (defined $after){                     # if there is something
		my $afterStr=$self->content($after); # behind it
		unshift(@contentNodes,$after);       # push it into the
		unshift(@content,$afterStr);         # text-node array
	    }
#------------------------------------------------------------------------
	    $text=join ($DEFAULTDELIMITER,@chunkContent); # check the text of
	    my $this=quotemeta($chunkContent[0]);         # the current chunk!
	    while ($text=~/$this$pat$/){                  # - remove all
		shift(@chunk);                            #   initial nodes
		shift(@chunkContent);                     #   before the text-
		if (not @chunk){last;}                    #   segment
		$text=join ($DEFAULTDELIMITER,@chunkContent);
		$this=quotemeta($chunkContent[0]);
	    }
#------------------------------------------------------------------------
	    if (not @chunk){next;}               # no node left -> next segment
	    if ($text=~/^(.+)$pat$/s){           # there's something in front
		my $str1=$1;                     # of the text segment
		my $pat=quotemeta($str1);        # --> split the first text-
		my $this=$chunkContent[0];       #     node into two nodes
		if ($this=~/^($pat)(.*)$/s){     #     and remove the prefix-
		    my $str2=$2;                 #     node from the chunk
		    my ($before,$after)=
			$self->splitContentNode($chunk[0],$str1,$str2);
		    $chunk[0]=$after;
		}
	    }

#------------------------------------------------------------------------
# finally: add the parent-label around all nodes in the chunk
#          if possible (check addParent)
#
	    push(@children,$self->addParent(\@chunk,$label));
	}
    }
    return @children;
}

#------------------------------------------------------------------------

sub splitContentNode{
    my $self=shift;
    my ($node,$before,$after)=@_;
    if (not ref($node)){return $node;}
    my $parent=$node->parent();
    if (not ref($parent)){return $node;}
    if ((defined $before) and (defined $after)){
	my $child=$parent->createTextNode($before);
	my $child=$self->createTextNode($before);
	$child=$parent->insertBefore($child,$node);
	$node->setNodeValue($after);
	return ($child,$node);
    }
    return $node;
}



#--------------------------------------------------------------------
# addParent
#
#  1) insertParent(\@children,$label,\%attr)
#  2) insertParent($label,\%attr,$childLabelRE,$childrenAttr,$label,\%attr)
#
#       $label ........ label for the new parent
#       %attr ......... attribute-value-hash for the new parent
#       @children ..... list of nodes to be the children of the new parent
#       $childLabelRE . regular expression to match labels of nodes (=children)
#       $childrenAttr . attributes to be matched with nodes (=>children)
#

sub addParent{
    my $self=shift;

    my $children;
    my $parentLabel;              # label of the new parent
    my $parentAttr;               # attribute-value hash for the parent
    if (not ref($_[0])){
	$parentLabel=shift;
	$parentAttr=shift;

	#---------------------------------------
        # childLabelRE:
        #   label of the node (reg exp)
	# childrenAttr:
        #   array of attribute-value hashs OR
	#     hash of attribute-value pairs
	#     (for matching children-nodes)
        #     - optional!
	#---------------------------------------
	my ($childLabelRE,$childrenAttr)=@_;

	$children=[];
	@{$children}=$self->findNodes($childLabelRE,$childrenAttr);
    }
    else{
	$children=shift;
	$parentLabel=shift;
	$parentAttr=shift;         
    }
                           
    if (not @{$children}){return undef;}
    if (not defined $children->[0]){return undef;}

    my $text=$self->content($children);

    my $root=$children->[0]->parent();
    foreach my $i (1..$#{$children}){
	if (not defined $children->[$i]){next;}
	if (not defined $children->[$i-1]){next;}

	my $child1=$children->[$i-1];
	my $child2=$children->[$i];

	($root,$children->[$i-1],$children->[$i])=
	    $self->findCommonParent($children->[$i-1],$children->[$i]);
	if (($child1 ne $children->[$i-1]) or 
	    ($child2 ne $children->[$i])){

	    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    # here should be some test if the common parent
	    # does not take to much content
	    # (content before <=> after ...)
	    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    # something like this: ...

	    my ($before,$after);
	    if ($child1 ne $children->[$i-1]){
		$before=$self->content($child1);
		$after=$self->content($children->[$i-1]);
	    }
	    else{
		$before=$self->content($child2);
		$after=$self->content($children->[$i]);
	    }
	    if ($before ne $after){return undef;}

	    # (addParent fails)
	    # could maybe split the parent-node ....
	    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	    return $self->addParent($children,$parentLabel,$parentAttr);
	}
	if (not defined $root){last;}
    }
    my @childNodes=();
    foreach my $i (0..$#{$children}){
	if (ref($children->[$i])){
	    push(@childNodes,$children->[$i]);
	}
    }
    if (defined $root){
	return $self->insertParent($root,\@childNodes,
				   $parentLabel,$parentAttr);
#	return $self->insertParent($root,$children,$parentLabel,$parentAttr);
    }
}

sub findCommonParent{
    my $self=shift;
    my ($node1,$node2)=@_;

    my $parent1=$node1->parent();
    if (not defined $parent1){return undef;}
    my $parent2=$node2->parent();
    if (not defined $parent2){return undef;}

    if ($parent1 eq $parent2){
	return ($parent1,$node1,$node2);
    }
    if ($parent2->isAncestor($parent1)){       # this is NOT (!!!) DOM
	my $child=$parent1;
	my $parent=$child->parent();
	while ($parent ne $parent2){
	    $child=$parent;
	    if (not ref($child)){last;}
	    $parent=$child->parent();
	}
	return ($parent,$child,$node2);
    }
    if ($parent1->isAncestor($parent2)){       # this is NOT (!!!) DOM
	my $child=$parent2;
	my $parent=$child->parent();
	while ($parent ne $parent1){
	    $child=$parent;
	    if (not ref($child)){last;}
	    $parent=$child->parent();
	}
	return ($parent,$node1,$child);
    }
    return $self->findCommonParent($parent1,$parent2);
    return undef;
}

#--------------------------------------------------------------------
# insertParent
#

sub insertParent{
    my $self=shift;
    my ($oldParent,$children,$parentLabel,$parentAttr)=@_;

    my $newParent=$self->createNode($parentLabel,$parentAttr);
#    $self->createNode(\$newParent,$parentLabel,$parentAttr);

    if (ref($children) eq 'ARRAY'){
	if ($children->[0]->parent() eq $oldParent){
	    $oldParent->insertBefore($newParent,$children->[0]);
	}
	else{
	    $oldParent->insertBefore($newParent);
	}
	foreach (0..$#{$children}){
#	    if (not ref($children->[$_]->getParentNode())){next;}
	    if (not ref($children->[$_])){next;}
	    if ($children->[$_]->parent eq $oldParent){
		$children->[$_]=$oldParent->removeChild($children->[$_]);
		$newParent->appendChild($children->[$_]);
	    }
	}
    }
    else{
	$children=$oldParent->replaceChild($newParent,$children);
	$newParent->appendChild($children);
    }
    return $newParent;
}

#....... end of insertParent!!!!!!!!!!!!!!!!!!!!!!!!



#--------------------------
# walk the tree ...
#    make all steps in a path!
#    a path is a sequence of steps which makeStep understands
#    (all steps have to be joined with ':' as delimiter symbol!)
#

sub moveTo{
    my $self=shift;
    my $node=shift;
    my $path=shift;

    my @steps=split(/\:/,$path);
    foreach (@steps){
	$node=$self->makeStep($node,$_);
    }
    return $node;
}


#--------------------------
# walk the tree ...
#
#           up: one step up
#         down: one step down (left-most = first child)
#    downright: one step down (right-most = last child)
#          top: go to the top (root node)
#       bottom: do 'down' as often as possible (go the first leaf)
#  bottomright: do 'downright' as often as possible (last leaf)
#         $tag: go up until a node with the tag $tag is reached
#         left: go the left neighbour
#               if no neighbour exists: do 'up-left-downright'
#   left($tag): go the left neighbour with the tag $tag
#        right: go the right neighbour
#               if no neighbour exists: do 'up-right-down'
#  right($tag): go the left neighbour with the tag $tag
#
# makeSteps returns the start-node if no appropriate node is found!
# (exception: left($tag) & right($tag): returns undef if nothing found)
#


sub makeStep{
    my $self=shift;
    my $node=shift;
    my $step=shift;
#    print STDERR "$step:";

    if (not ref($node)){return $node;}

    if ($step=~/up/i){
	return $node->getParentNode();
    }
    elsif ($step=~/top/i){
	return $self->getRootNode();
    }
    elsif ($step=~/downright/i){
        my $down=$node->getLastChild();
        if (not ref($down)){return $down;}     # this return undef!!!
        if ($self->isEmptyNode($down)){
#           print STDERR "empty:";
            return $self->makeStep($down,'left');
        }
        return $down;
    }
    elsif ($step=~/down/i){
        my $down=$node->getFirstChild();
        if (not ref($down)){return $down;}    # this return undef!!!
        if ($self->isEmptyNode($down)){
#           print STDERR "empty:";
            return $self->makeStep($down,'right');
        }
        return $down;
    }
    elsif ($step=~/bottomright/i){
        while ($node->hasChildNodes()){
            my $down=$self->makeStep($node,'downright');
            if (ref($down)){$node=$down;}
        }
        return $node;
    }
    elsif ($step=~/bottom/i){
	while ($node->hasChildNodes()){
	    my $down=$self->makeStep($node,'down');
	    if (ref($down)){$node=$down;}
	}
	return $node;
    }
    elsif ($step=~/left$/i){
	my $left=$node->getPreviousSibling();
	if (not ref($left)){
	    return $self->moveTo($node,'up:left:downright');
	}
	if ($self->isEmptyNode($left)){
#	    print STDERR "empty:";
	    return $self->makeStep($left,$step);
	}
	return $left;
    }
    elsif ($step=~/left\((.*)\)/i){             # left neighbour with tag $tag!
	my $tag=$1;
	my $left=$node->getPreviousSibling();
	if (ref($left)){
	    if ($left->getNodeName() eq $tag){
		return $left;
	    }
	}
	my @nodes=$self->findNodes($tag);
	foreach (0..$#nodes){
	    if ($node==$nodes[$_]){
		if ($_){return $nodes[$_-1];}
		else{return undef;}
	    }
	}
    }
    elsif ($step=~/right$/i){
	my $right=$node->getNextSibling();
	if (not ref($right)){
	    return $self->moveTo($node,'up:right:down');
	}
	if ($self->isEmptyNode($right)){
#	    print STDERR "empty:";
	    return $self->makeStep($right,$step);
	}
	return $right;
    }
    elsif ($step=~/right\((.*)\)/i){           # right neighbour with tag $tag!
	my $tag=$1;
	my $left=$node->getNextSibling();
	if (ref($left)){
	    if ($left->getNodeName() eq $tag){
		return $left;
	    }
	}
	my @nodes=$self->findNodes($tag);
	foreach (0..$#nodes){
	    if ($node==$nodes[$_]){
		return $nodes[$_+1];
	    }
	}
    }

    my $current=$node;
    while (ref($current)){                       # $step is a tag name!
	$current=$current->getParentNode();      # go up the tree until we find
	if (not ref($current)){last;}
	my $name=$current->getNodeName();
	if ($name=~/$step/){                     # the element or we reach
	    return $current;                     # the root node
	}
    }

    return $node           # nothing happened! return the $node
}

sub isEmptyNode{
    my $self=shift;
    my $node=shift;
    if (not ref($node)){return undef;}
    if ($node->getNodeName eq '#text'){
	my $text=$node->getNodeValue();
	if ($text!~/\S/s){return 1;}
    }
    return 0;
}




######################################################################
######################################################################
######################################################################
# ..............
#
# should look through these functions some day
#
######################################################################

#----------------------------------------------
# return a complex data structure

sub data{
    my $self=shift;
    my $root=$self->root();
    if (not ref($root)){return undef;}
    return $root->data();
#    return $self->attribute();              # get all root attributes
}

#----------------------------------------------
# read a complex data structure into a Data-object

sub setData{
    my $self=shift;
    my $root=$self->root();
    if (not ref($root)){$root=$self->addNode();}
    if (not ref($root)){return undef;}
    return $root->setData(@_);
#     return $self->setAttribute(@_);
}


sub keepAttributes{
    my $self=shift;
    my $names=shift;
    if (ref($names) ne 'ARRAY'){return;}

    my $attr=$self->attribute();              # get all root attributes
    if (ref($attr) ne 'HASH'){return;}
    foreach my $a (keys %{$attr}){
	if (not grep (/^$a$/,@{$names})){     # delete matching attributes
	    $self->delAttribute($a);
	}
    }
}

sub delEmptyFields{                    # delete empty fields ('')
    my $self=shift;

# get attributes ... delete empty attributes... !!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ... this is just for right now ...

    my $data=$self->data;
    foreach (keys %{$data}){
	if (not defined $$data{$_}){delete $$data{$_};}
	if ($$data{$_} eq ''){delete $$data{$_};}
    }
}


#--------------------------------------------------
# matchData: does not really match all data in this object
#            matches only the root attributes with the select pattern

sub matchData{
    my $self=shift;
    my $pattern=shift;
    my $root=$self->root();
    if (not ref($root)){return 0;}
    return $root->matchAttr($pattern);
}


#-----------------------------------------
# experimental: convert to HTML-tables
                                                                                
sub toHTML{
    my $self=shift;
    my $dom=shift;
    my $indent=shift;

    my %colors=('default' => '#FFFFFF',
                's' => '#EEEEEE',
                'chunk' => '#E4EEFF',
                'c' => '#E4EEFF',
                'source' => '#FFFFEE',
                'target' => '#FFFFEE',
                'w' => '#FFEEDD');

    if (not defined $dom){
        $dom=$self->root();
    }

    my $html="$indent<table>";
    $html.="$indent<tr>";
    foreach my $n ($dom->getChildNodes()){
        my $name=$n->getNodeName;

        if (defined $colors{$name}){
            $html.="$indent<td bgcolor='$colors{$name}'>";
        }
        else{
            $html.="$indent<td bgcolor='$colors{default}'>";
            if ($name!~/^\#/){
                $html.="<b>$name</b><br>";
            }
        }
        if ($name eq '#text'){
            my $str=$n->getNodeValue;
            if ($str=~/\S/){
                $html.="<i>$str</i>";
            }
        }
        elsif ($name eq '#comment'){
            my $str=$n->getNodeValue;
            if ($str=~/\S/){
                $html.='<!-- '.$str.' -->';
            }
        }
        else{
            my $attr=$n->attributes();
#           $html.="<b>$name</b>";
            if (ref($attr) eq 'HASH'){
#               $html.='<font size="-3">';
                delete $$attr{id};                    # skip ID and byte-spans!
                delete $$attr{span};
                $html.=join '<br>',values %{$attr};
#               foreach (sort keys %{$attr}){
#                   $html.="<br>$_='$attr->{$_}'";
#               }
#               $html.='</font>';
            }
        }
        $html.=$indent.'</td>';
    }

    $html.="$indent</tr>$indent<tr>";

    #--------------------
    # process children

    foreach my $n ($dom->getChildNodes()){
        $html.="$indent<td>";
#       $indent.='    ';
        $indent='';
        $html.=$self->toHTML($n,$indent);
        $html.="$indent</td>";
    }

    $html.="$indent</tr>$indent</table>\n";
    return $html;
}


######################################################################
######################################################################
######################################################################
######################################################################






#--------------------------------------------------------------------
# finally: return a true value
# 

1;
