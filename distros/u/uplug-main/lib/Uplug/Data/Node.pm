###########################################################################
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
#

package Uplug::Data::Node;

use strict;

use vars qw($DEBUG %CREATED %DESTROYED %CHILDREN %ALIVE);

$DEBUG=0;
%CREATED;
%DESTROYED;
%CHILDREN;
%ALIVE;

sub new{
    my $class=shift;
    my $self={};
    bless $self,$class;
    $self->init(@_);
    if ($DEBUG){
	$CREATED{$self}=1;
	$ALIVE{$self}=1;
	if (not ((scalar keys %CREATED) % 100)){
	    print STDERR scalar keys %DESTROYED;
	    print STDERR '/';
	    print STDERR scalar keys %CREATED;
	    print STDERR ' - ';
	    print STDERR scalar keys %CHILDREN;
	    print STDERR ' - ';
	    print STDERR scalar keys %ALIVE;
	    print STDERR "\n";
	}
    }
    return $self;
}

sub init{
    my $self=shift;
    my $label=shift;
    my $attr=shift;
    my $parent=shift;

    $self->{LABEL}=$label;
    if (ref($attr) eq 'HASH'){
	%{$self->{ATTR}}=%{$attr};
    }
    else{
	$self->{ATTR}={};
    }
    $self->{PARENT}=$parent;
    $self->delContent();
    @{$self->{CONTENT}}=@_;        # text or children-nodes
}

sub root{
    return $_[0];
}

sub parent{
    my $self=shift;
    return $self->{PARENT};
}

sub setParent{
    my $self=shift;
    $self->{PARENT}=$_[0];
}

sub label{
    my $self=shift;
    return $self->{LABEL};
}

sub setLabel{
    my $self=shift;
    $self->{LABEL}=$_[0];
}

sub attributes{
    my $self=shift;
    return $self->{ATTR};
}

sub attribute{
    my $self=shift;
    return $self->{ATTR}->{$_[0]};
}

sub setAttribute{
    my $self=shift;
    while(@_){
	my $key=shift;
	$self->{ATTR}->{$key}=shift;
    }
}

sub delAttribute{
    my $self=shift;
    delete $self->{ATTR}->{$_[0]};
}

sub children{
    my $self=shift;
    if (ref($self->{CONTENT}) ne 'ARRAY'){$self->{CONTENT}=[];}
    return wantarray ? @{$self->{CONTENT}} : $self->{CONTENT};
}

sub nrChildren{
    my $self=shift;
    return $#{$self->{CONTENT}};
}

sub child{
    my $self=shift;
    my $nr=shift;
    if (not defined $nr){$nr=0;}                    # no nr --> first child!
    if ($nr>$#{$self->{CONTENT}}){return undef;}    # nr > number of children
    return $self->{CONTENT}->[$nr];
}

sub hasChildren{
    my $self=shift;
    return scalar @{$self->{CONTENT}};
}


#----------------------------------------------------------
# setData ..... read a complex data structure (produced by self->data)
#               and build a node-tree
#----------------------------------------------------------

sub setData{
    my $self=shift;
    my $data=shift;
    if (ref($data) ne 'HASH'){return;}
    my %attr=();
    foreach (keys %{$data}){
	if ($_!~/^\#/){$attr{$_}=$data->{$_};}
    }
    $self->delContent();                                  # delete old children
    $self->setLabel($data->{'#label'}) if ($data->{'#label'}); # set label
    $self->setAttribute(%attr);                                # set attributes
    $self->addTextNode($data->{'#text'}) if ($data->{'#text'});# add text
    if (ref($data->{'#children'}) eq 'ARRAY'){                 # add children
	foreach my $c (@{$data->{'#children'}}){
	    my $n=$self->addContent($self->createNode());
	    $n->setData($c);
	}
    }
}

#----------------------------------------------------------
# data ..... put all data in one complex data-structure
#----------------------------------------------------------
#
# for example:
#
# %returndata = (
#   '#label' => 'align',                     # root label
#   'id' => '1',                             # attribute of root
#   '#children' => [                         # children array
#         {'#label' => 'source',             # label of first child
#          '#children' => [                  # children of first child
#               {'#label' => 's',            # label
#                'id' => 's1.1',             # attribute
#                'lang' => 'swedish'         # attribute
#                '#children' => [
#                  {
#                     '#label' => 'w',                   # label
#                     '#text' => 'REGERINGSF?RKLARING',  # text-children only!
#                     'id' => 'w1.1.1',                  # attribute
#                  },
#                  {
#                     '#label' => 'w',
#                     '#text' => '.',
#                     'id' => 'w1.1.2',
#                  },
#                ],
#               }
#         ]                                   # end of children of first child
#         }                                   # end of first child
#   ]                                         # end of children array
# }                                           # end of root


sub data{
    my $self=shift;
    my $attr=$self->attributes();
    my $label=$self->label();
    my %hash=%{$attr};
    if ($label){$hash{'#label'}=$label;}
    if ($self->hasChildren()){
	$hash{'#children'}=[];
	my $idx=0;                                    # children index
	my $textonly=1;                               # text-only flag
	foreach my $c ($self->children()){
	    if ($c->isTextNode()){$hash{'#children'}[$idx]=$c->text();}
	    else{$textonly=0;%{$hash{'#children'}[$idx]}=$c->data();}
	    $idx++;
	}
	if ($textonly){
	    $hash{'#text'}=join '',@{$hash{'#children'}};
	    delete $hash{'#children'};
	}
    }
    return wantarray ? %hash : \%hash;
}

# end of data
#----------------------------------------------------------


sub index{
    my $self=shift;
    my $child=shift;
    my $idx=0;
    foreach ($self->children){
	if ($_ eq $child){return $idx;}
	$idx++;
    }
    return -1;
}


sub setContent{
    my $self=shift;
    $self->delContent();
    return $self->addContent(@_);
}

sub delContent{
    my $self=shift;
#    my $level=shift;
    foreach my $c (@{$self->{CONTENT}}){
	if (not ref($c)){next;}
#	$c->setParent(undef);
#	$level++;
#	$c->DESTROY($level);
	$c->DESTROY();
	if ($DEBUG){$CHILDREN{$c}=1;}
    }
    $self->{CONTENT}=[];
}

sub lastNode{
    my $self=shift;
    if (ref($self->{CONTENT}) ne 'ARRAY'){return undef;}
    return $self->{CONTENT}->[-1];
}

sub addTextNode{
    my $self=shift;
    my $text=shift;
    my $last=$self->lastNode();
    if (ref($last) and $last->isTextNode){        # this is quite a hack!
	$last->setText($last->text().' '.$text);  # (adds spaces!!!!)
	return $last;
    }
    my $child=new Uplug::Data::Node('#text',{'#text' => $text},$self);
    return $self->addContent($child);
}

sub createTextNode{
    my $self=shift;
    my $text=shift;
    return new Uplug::Data::Node('#text',{'#text' => $text},$self);
}

sub isTextNode{
    my $self=shift;
    return ($self->label eq '#text');
}

sub text{
    my $self=shift;
    return $self->attribute('#text');
}

sub setNodeValue{
    my $self=shift;
    if ($self->isTextNode){
	return $self->setAttribute('#text',$_[0]);
    }
}

sub setText{
    my $self=shift;
    return $self->setAttribute('#text',$_[0]);
}


sub addElement{
    my $self=shift;
    my $label=shift;
    my $attr=shift;

    my $child=new Uplug::Data::Node($label,$attr,$self);
    return $self->addContent($child);
}

sub createElement{
    my $self=shift;
    return $self->createNode(@_);
}

sub createNode{
    my $self=shift;
    my $label=shift;
    my $attr=shift;

    return new Uplug::Data::Node($label,$attr,$self);
}


sub addContent{
    my $self=shift;

    foreach my $c (@_){
	if (not ref($c)){next;}
	push (@{$self->{CONTENT}},$c);      # --> push a new content element
	$c->setParent($self);
    }
    return $self->{CONTENT}->[-1];          # return last content-element!
}

sub appendChild{
    my $self=shift;
    return $self->addContent(@_);
}

sub insertBefore{
    my $self=shift;
    my $child=shift;
    my $node=shift;
    my @tmp=@{$self->{CONTENT}};
    my @new=();
    foreach (@tmp){
	if ($_ eq $node){
	    push (@new,$child);
	}
	push (@new,$_);
    }
    @{$self->{CONTENT}}=@new;
    $child->setParent($self);
    return $child;
}


sub content{
    my $self=shift;
    my $del=shift;
    if ($self->isTextNode){return $self->text;}
    my @content=();
    foreach my $c ($self->children){
	if (not ref($c)){next;}
	if ($c->isTextNode){push(@content,$c->text());}
	else{
	    my @children=$c->content($del);
	    push(@content,@children);
	}
    }
    return wantarray ? @content : join ($del,@content);
#    return join $del,@content;
}


sub normalize{
    my $self=shift;
# check children nodes and put contiguous text nodes together
}

sub isAncestor{
    my $self=shift;
    my $node=shift;

    my $parent=$self->parent;
    while (defined $parent){
	if ($parent eq $node){return 1;}
	$parent=$parent->parent;
    }
    return 0;
}


sub detach{
    my $self=shift;
    my $parent=$self->parent;
    if (ref($parent)){
	return $parent->removeChild($self);
    }
    return undef;
}

sub removeChild{
    my $self=shift;
    my $child=shift;
    if (ref($child) and (ref($self->{CONTENT}) eq 'ARRAY')){
	my $idx=$self->index($child);
	if ($idx>=0){
	    splice(@{$self->{CONTENT}},$self->index($child),1);
#	    print STDERR "remove ...\n";
	    $child->setParent(undef);
	    return $child;
	}
    }
    return undef;
}


sub replaceChild{
    my $self=shift;
    my $new=shift;
    my $old=shift;

    if (ref($old)){
	$self->{CONTENT}->[$self->index($old)]=$new;
#	print STDERR "replace ...\n";
	$new->setParent($self);
	$old->setParent(undef);
	return 1;
    }
    return 0;
}




sub matchAttr{
    my $self=shift;
    my $pattern=shift;

    my $attr=$self->attributes;
    if ((ref($attr) eq 'HASH') and (ref($pattern) eq 'HASH')){
	foreach my $k (keys %{$pattern}){
	    if (not defined $attr->{$k}){
		return 0;
	    }
	    if (defined $pattern->{$k}){
		my $p=quotemeta($pattern->{$k});
		if ($attr->{$k}!~/^$p$/){
		    return 0;
		}
	    }
	}
	return 1;
    }
    return 0;
}








sub DESTROY{
    my $self=shift;
#    my $level=shift;
#    if ($level){print STDERR "$level\n";}
    if ($DEBUG){
	$DESTROYED{$self}=1;
	delete $ALIVE{$self};
    }
#    $self->delContent($level);
    $self->delContent();
    %{$self->{ATTR}}=();
    delete $self->{CONTENT};
    delete $self->{ATTR};
    delete $self->{PARENT};
}



########################################################################
########################################################################
########################################################################
#
# DOM-like methods
#

#    getElementsByTagName
sub getElementsByTagName{
    my $self=shift;
    my ($label,$nodes)=@_;
    if (not ref($nodes)){$nodes=[];}
    if ($label eq '*'){push (@{$nodes},$self);}
    elsif ($self->label() eq $label){push (@{$nodes},$self);}
    foreach my $c ($self->children()){
	$c->getElementsByTagName($label,$nodes);
    }
    return @{$nodes};
}

sub getNodeValue{        # ... not really shure if this is correct ...
    my $self=shift;
    if ($self->isTextNode){return $self->text();}
}

sub getNodeName{return $_[0]->label();}
sub setTagName{return $_[0]->setLabel($_[1]);}   # not standard-DOM!
sub getParentNode{return $_[0]->parent();}
sub hasChildNodes{return $_[0]->hasChildren();}
sub getFirstChild{return $_[0]->child(0);}
sub getLastChild{return $_[0]->child(-1);}


sub getChildNodes{    # is that DOM?
    my $self=shift;
    return $self->children(@_);
}

sub getPreviousSibling{
    my $self=shift;
    my $parent=$self->parent();
    if (ref($parent)){
	my $idx=$parent->index($self);
	if ($idx>0){
	    return $parent->child($idx-1);
	}
    }
    return undef;
}

sub getNextSibling{
    my $self=shift;
    my $parent=$self->parent();
    if (ref($parent)){
	my $idx=$parent->index($self);
	if ($idx>=0){
	    return $parent->child($idx+1);
	}
    }
    return undef;
}





1;
