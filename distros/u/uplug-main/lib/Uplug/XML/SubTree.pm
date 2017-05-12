
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#####################################################################
#
# 
#
#####################################################################
# $Author$
# $Id$
#
#

package Uplug::XML::SubTree;



use strict;
use XML::Parser;


our $DOCROOT='document';
our $SUBTREEROOT='.*';
our $IGNOREWARNINGS=1;


sub new{
    my $class=shift;
    my $self={};
    bless $self,$class;
    $self->init(@_);
    return $self;
}


sub init{
    my $self=shift;
    my ($SubTreeRoot,$DocRoot,$DocBody)=@_;

    if (not ref($self->{XmlParser})){
	$self->{XmlParser}=
	    new XML::Parser(Handlers => {Start => \&XmlTreeStart,
					 End => \&XmlTreeEnd,
					 Default => \&XmlTreeChar,
					 XMLDecl => \&XmlDecl,
#					 Doctype => \&XmlDoctype
					 },);
    }
    $self->{XmlHandle}=$self->{XmlParser}->parse_start;
    $self->setTags($SubTreeRoot,$DocRoot,$DocBody);
    $self->{XmlHandle}->{XmlProlog}='';
}

sub parser{return $_[0]->{XmlParser};}
sub handle{return $_[0]->{XmlHandle};}

#----------------------------------------------
# get handles and set handles for XML::Parser

sub starthandle{return \&XmlTreeStart;}
sub endhandle{return \&XmlTreeEnd;}
sub charhandle{return \&XmlTreeChar;}
sub declhandle{return \&XmlTreeDecl;}

sub setStarthandle{$_[0]->{XmlParser}->setHandlers('Start',$_[1]);}
sub setEndhandle{$_[0]->{XmlParser}->setHandlers('End',$_[1]);}
sub setCharhandle{$_[0]->{XmlParser}->setHandlers('Default',$_[1]);}
sub setDeclhandle{$_[0]->{XmlParser}->setHandlers('XMLDecl',$_[1]);}

#---------------------------------------------------------------------------
# set document-specific XML tags for the XML::Parser 
# and compile regular expressions

sub setTags{
    my $self=shift;
    my ($SubTreeRoot,$DocRoot,$DocBody)=@_;

    if (not $SubTreeRoot){$SubTreeRoot=$SUBTREEROOT;}
    $self->{XmlHandle}->{SubTreeRoot}=$SubTreeRoot;
    $self->{XmlHandle}->{DocRootTag}=$DocRoot if ($DocRoot);
    $self->{XmlHandle}->{DocBodyTag}=$DocBody if ($DocBody);
    $self->CompileTagREs();
}


#--------------------------------------------------
# compile regular expressions for matching XML-tags

sub CompileTagREs{
    my $self=shift;
    foreach my $t ('DocRootTag','SubTreeRoot','DocBodyTag'){
	$self->{XmlHandle}->{$t.'RE'}=qr/^($self->{XmlHandle}->{$t})$/;
    }
}

#-----------------------------------------------------
# parse XML-strings and return the next XML-sub-tree
#    - uses XML::Parser
#
# next($root)
#            $root ---> root tag of the XML sub-tree

sub parse{
    my $self=shift;
    my $xml=shift;
    my $root=shift;
    if (($root) and ($root ne $self->SubTreeRoot)){
	$self->setTags($root);
    }

    my $header=undef;
    my $tail=undef;

    eval { $self->{XmlHandle}->parse_more($xml); };

    if ($@){
	if (not $IGNOREWARNINGS){
	    warn $@;
	    print STDERR $_;
	}
	$header=$self->{XmlHandle}->{BeforeSubTree}.$_;
	$self->{XmlHandle}->{SubTreeEnded}=undef;
	$self->{XmlHandle}=$self->{XmlParser}->parse_start;  # re-start
	my $ParseStr=$self->{XmlHandle}->{XmlProlog};        # XML parsern!
	eval { $self->{XmlHandle}->parse_more($ParseStr); };
	return 2;
    }
    $self->{BeforeSubTree}=$self->{XmlHandle}->{BeforeSubTree};  # header
    $self->{SubTreeRoot}=$self->{XmlHandle}->{SubTreeEnded};     # root-tag
    if ($self->{XmlHandle}->{SubTreeEnded}){
	my $subtree=$self->{XmlHandle}->{SubTreeString};
	$self->{XmlHandle}->{BeforeSubTree}=undef;
	$self->{XmlHandle}->{SubTreeString}=undef;
	$self->{XmlHandle}->{SubTreeEnded}=undef;
	return $subtree;
    }
    return undef;
}

sub XmlProlog{
    my $self=shift;
    return $self->{XmlHandle}->{XmlProlog};
}

sub SubTreeRoot{
    my $self=shift;
    return $self->{XmlHandle}->{SubTreeRoot};
}

sub DocRootTag{
    my $self=shift;
    return $self->{XmlHandle}->{DocRootTag};
}

sub DocBodyTag{
    my $self=shift;
    return $self->{XmlHandle}->{DocBodyTag};
}

sub DocRoot{
    my $self=shift;
    return $self->{XmlHandle}->{DocRoot};
}

sub DocBody{
    my $self=shift;
    return $self->{XmlHandle}->{DocBody};
}

sub NewDoc{
    my $self=shift;
    if ($self->{XmlHandle}->{NewDoc}){
	$self->{XmlHandle}->{NewDoc}=0;
	return 1;
    }
    return 0;
}

sub NewBody{
    my $self=shift;
    if ($self->{XmlHandle}->{NewBody}){
	$self->{XmlHandle}->{NewBody}=0;
	return 1;
    }
    return 0;
}



sub header{
    my $self=shift;
    return $self->{BeforeSubTree};
}

sub root{
    my $self=shift;
    return $self->{SubTreeRoot};
}


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
# subroutines for the XML-parser
#

sub XmlTreeStart{
    my $p=shift;
    my $e=shift;

    #--------------------------------------------------
    # document root tags are parsed ... but ignored
    #--------------------------------------------------
    if ((defined $p->{DocRootTagRE}) and ($e=~/$p->{DocRootTagRE}/)){
	$p->{BeforeSubTree}='';
	$p->{DocRootTag}=$e;
	$p->{DocRootTagRE}=qr/^($p->{DocRootTag})$/;
	$p->{NewDoc}=1;
	%{$p->{DocRoot}}=@_;
	return;
    }

    #--------------------------------------------------
    # a new subtree starts!
    #--------------------------------------------------
    if ($e=~/$p->{SubTreeRootRE}/){
	if ($p->{SubTreeString}){
	    $p->{BeforeSubTree}.=$p->{SubTreeString}
	}
	$p->{SubTreeStarted}=$1;
	$p->{SubTreeEnded}=0;
	$p->{SubTreeString}=$p->original_string;
    }
    #--------------------------------------------------
    # we are inside a valid subtree!
    #--------------------------------------------------
    elsif($p->{SubTreeStarted}){
	$p->{SubTreeString}.=$p->original_string;
    }
    #--------------------------------------------------
    # ... neither inside nor at the beginning of a new one
    #--------------------------------------------------
    else{
	if ((defined $p->{DocBodyTagRE}) and ($e=~/$p->{DocBodyTagRE}/)){
	    $p->{DocBodyTag}=$e;
	    $p->{DocBodyTagRE}=qr/^($p->{DocBodyTag})$/;
	    $p->{NewBody}=1;
	    %{$p->{DocBody}}=@_;
	}
	$p->{BeforeSubTree}.=$p->original_string;
    }
}

sub XmlTreeEnd{
    my ($p,$e)=@_;

    #--------------------------------------------------
    # the subtree ended!
    #--------------------------------------------------
    if (($e=~/$p->{SubTreeRootRE}/) and 
	($p->{SubTreeStarted} eq $1)){
	$p->{SubTreeStarted}=0;
	$p->{SubTreeEnded}=$1;
#	$p->{BeforeSubTree}=~s/\s*$/\n/s;
#	$p->{BeforeSubTree}=~s/^\s*//s;
	$p->{SubTreeString}.=$p->original_string;
    }
    #--------------------------------------------------
    # still inside ...
    #--------------------------------------------------
    elsif($p->{SubTreeStarted}){
	$p->{SubTreeString}.=$p->original_string;
    }
    #--------------------------------------------------
    # neither inside nor at the end
    #--------------------------------------------------
    else{
	$p->{BeforeSubTree}.=$p->original_string;
    }
}
sub XmlTreeChar{
    my ($p,$e)=@_;

    #--------------------------------------------------
    # inside a subtree -> save the string
    #--------------------------------------------------
    if ($p->{SubTreeStarted}){
	$p->{SubTreeString}.=$p->original_string;
    }
    #--------------------------------------------------
    # not inside?! -> save string as header
    #--------------------------------------------------
    else{
	$p->{BeforeSubTree}.=$p->original_string;
    }
}

sub XmlDecl{
    my ($p,$v,$e,$s)=@_;

    $p->{XmlProlog}=$p->original_string;
    $p->{XmlEncoding}=$e;
    $p->{XmlVersion}=$v;
}

sub XmlDoctype{
    my ($p,$name,$sysid,$publid,$internal)=@_;
}

