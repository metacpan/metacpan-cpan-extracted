####################################################################
# Copyright (C) 2004 Jörg Tiedemann
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
# Uplug::Data::Align
#
#
#
###########################################################################


package Uplug::Data::Align;

use strict;
use vars qw( @ISA );

use Uplug::Data;
use Uplug::Data::Lang;

@ISA = qw( Uplug::Data );

sub init{
    my $self=shift;
    my $srclang=shift;
    my $trglang=shift;

    if (not defined $self->{source}){
	$self->{source}=Uplug::Data::Lang->new($srclang);
	$self->setOption('SRCLANG',$srclang);
    }
    elsif ((defined $srclang) and ($self->{SRCLANG} ne $srclang)){
	$self->{source}=Uplug::Data::Lang->init($srclang);
	$self->setOption('SRCLANG',$srclang);
    }
    else{$self->{source}->init();}
    if (not defined $self->{target}){
	$self->{target}=Uplug::Data::Lang->new($trglang);
	$self->setOption('TRGLANG',$trglang);
    }
    elsif ((defined $trglang) and ($self->{TRGLANG} ne $trglang)){
	$self->{target}=Uplug::Data::Lang->new($trglang);
	$self->setOption('TRGLANG',$trglang);
    }
    else{$self->{target}->init();}
#    $self->{SRCSUBNEW}=1;             # flag for creating new source sub-trees
#    $self->{TRGSUBNEW}=1;             # flag for creating new target sub-trees
    return $self->SUPER::init(@_);
}

sub clone{return Uplug::Data::Align->new();}


sub makeLangSubData{
    my $self=shift;
    $self->subData($self->{'source'},'source');
    $self->subData($self->{'target'},'target');
}

sub sourceData{return $_[0]->{source};}
sub targetData{return $_[0]->{target};}
sub linkData{return $_[0]->{link};}


sub getTokens{
    my $self=shift;
    my $lang=shift;
    my $param=shift;
    if (not defined $lang){$lang='source'};
    if (not ref($self->{$lang})){return undef;}
#     $self->subData($self->{$lang},$lang);
#    $self->{$lang}=$self->subData($lang);
    $self->makeParameter($param,$lang);
    return $self->{$lang}->getTokens($param,@_);
}

sub getSrcTokens{my $self=shift;return $self->getTokens('source',@_);}
sub getTrgTokens{my $self=shift;return $self->getTokens('target',@_);}

sub getNgrams{
    my $self=shift;
    my $lang=shift;
    my $param=shift;
    if (not defined $lang){$lang='source'};
    if (not ref($self->{$lang})){return undef;}
#     $self->subData($self->{$lang},$lang);
#    $self->{$lang}=$self->subData($lang);
    $self->makeParameter($param,$lang);
    return $self->{$lang}->getNgrams($param,@_);
}

sub getSrcNgrams{my $self=shift;return $self->getNgrams('source',@_);}
sub getTrgNgrams{my $self=shift;return $self->getNgrams('target',@_);}

sub getChunks{
    my $self=shift;
    my $lang=shift;
    my $param=shift;
    if (not defined $lang){$lang='source'};
    if (not ref($self->{$lang})){return undef;}
#    $self->subData($self->{$lang},$lang);
#    $self->{$lang}=$self->subData($lang);
    $self->makeParameter($param,$lang);
    return $self->{$lang}->getChunks($param,@_);
}

sub getSrcChunks{my $self=shift;return $self->getChunks('source',@_);}
sub getTrgChunks{my $self=shift;return $self->getChunks('target',@_);}

sub getPhrases{
    my $self=shift;
    my $lang=shift;
    my $param=shift;
    if (not defined $lang){$lang='source'};
    if (not ref($self->{$lang})){return undef;}
#    $self->subData($self->{$lang},$lang);
#    $self->{$lang}=$self->subData($lang);
    $self->makeParameter($param,$lang);
    return $self->{$lang}->getPhrases($param,@_);
}

sub getSrcPhrases{my $self=shift;return $self->getPhrases('source',@_);}
sub getTrgPhrases{my $self=shift;return $self->getPhrases('target',@_);}


sub getPhrasePos{
    my $self=shift;
    my ($phraseNodes,$tokenNodes)=@_;
    my @idx=();
    foreach my $p (0..$#{$phraseNodes}){
	my $lastIdx=0;
	foreach my $t ($lastIdx..$#{$tokenNodes}){
	    if ($$phraseNodes[$p]==$$tokenNodes[$t]){
		push(@idx,$t);
		$lastIdx=$t+1;
	    }
	}
    }
    return join ":",@idx;
}


sub getRelativePosition{
    my $self=shift;
    my ($srcPhr,$trgPhr)=@_;

    my $srcPos=$self->{source}->getPhrasePosition($srcPhr);
    my $trgPos=$self->{target}->getPhrasePosition($trgPhr);

    if (not defined $srcPos){return 0;}
    if (not defined $trgPos){return 0;}

    return $trgPos-$srcPos;
}

sub getFeaturePairs{
    my $self=shift;
    return getAlignPhrases(@_);
}

sub getAlignPhrases{
    my $self=shift;
    my ($param,$src,$trg,$token,$attr)=@_;
    if (ref($param) ne 'HASH'){$param={};}

    #----------------------------------------------------------------------
    my @srcTokNodes=();          # 1) get all tokens
    my @trgTokNodes=();
    my @srcTok=$self->getSrcTokens($param,\@srcTokNodes);
    my @trgTok=$self->getTrgTokens($param,\@trgTokNodes);

    #----------------------------------------------------------------------
    my $srcNodes=[];             # 2) get all possible phrases
    my $trgNodes=[];
    my @srcPhr=$self->getSrcPhrases($param,$srcNodes,
				    \@srcTokNodes,\@srcTok);
    my @trgPhr=$self->getTrgPhrases($param,$trgNodes,
				    \@trgTokNodes,\@trgTok);

    #----------------------------------------------------------------------
    my @srcIdx=();               # 3) get token positions for each phrase
    my @trgIdx=();
    foreach (0..$#srcPhr){
	push (@srcIdx,$self->getPhrasePos($$srcNodes[$_],\@srcTokNodes));
    }
    foreach (0..$#trgPhr){
	push (@trgIdx,$self->getPhrasePos($$trgNodes[$_],\@trgTokNodes));
    }

    #----------------------------------------------------------------------

    $self->makeParameter($param,'source');  #    get source feature
    foreach (0..$#{$srcNodes}){
	$$src{$srcIdx[$_]}=
	    $self->{source}->getPhraseFeature(\@{$$srcNodes[$_]},
					      $param);
	if (defined $$param{'relative position'}){
	    my $srcPos=$self->{source}->getPhrasePosition($$srcNodes[$_]);
	    if ($$src{$srcIdx[$_]}=~/\S/){
		$$src{$srcIdx[$_]}.=":pos($srcPos)";
	    }
	    else{
		$$src{$srcIdx[$_]}="pos($srcPos)";
	    }
	}
    }
    $self->makeParameter($param,'target');  #    and generate feature
    foreach (0..$#{$trgNodes}){
	$$trg{$trgIdx[$_]}=
	    $self->{target}->getPhraseFeature(\@{$$trgNodes[$_]},
					      $param);
	if (defined $$param{'relative position'}){
	    my $trgPos=$self->{target}->getPhrasePosition($$trgNodes[$_]);
	    if ($$trg{$trgIdx[$_]}=~/\S/){
		$$trg{$trgIdx[$_]}.=":pos($trgPos)";
	    }
	    else{
		$$trg{$trgIdx[$_]}="pos($trgPos)";
	    }
	}
    }
    if (ref($token) eq 'HASH'){
	@{$$token{source}}=@srcTok;
	@{$$token{target}}=@trgTok;

	if (ref($attr) eq 'HASH'){
	    @{$$attr{source}}=$self->{source}->attribute(\@srcTokNodes);
	    @{$$attr{target}}=$self->{target}->attribute(\@trgTokNodes);
	    foreach (0..$#srcTokNodes){
		$$attr{source}[$_]{content}=$self->content($srcTokNodes[$_]);
	    }
	    foreach (0..$#trgTokNodes){
		$$attr{target}[$_]{content}=$self->content($trgTokNodes[$_]);
	    }
	}
    }
}

sub getSrcTokenFeatures{
    my $self=shift;
    return $self->getTokenFeatures('source',@_);
}

sub getTrgTokenFeatures{
    my $self=shift;
    return $self->getTokenFeatures('target',@_);
}

sub getTokenFeatures{
    my $self=shift;
    my $lang=shift;                  # source / target
    my ($param,$nodes)=@_;
    if (ref($param) ne 'HASH'){$param={};}
    if (ref($nodes) ne 'ARRAY'){$nodes=[];}
    if (not ref($self->{$lang})){return undef;}

    #----------------------------------------------------------------------

    $self->makeParameter($param,$lang);
    my @tok=$self->{$lang}->getTokens($param,$nodes);

    if (keys %{$param}){
	foreach (0..$#{$nodes}){
	    $tok[$_]=$self->{$lang}->getPhraseFeature([$$nodes[$_]],$param);
	}
    }
    return @tok;
}


sub getBitextPhrases{
    my $self=shift;
    my ($param,$src,$trg,$token,$attr)=@_;
    if (ref($param) ne 'HASH'){$param={};}


    #----------------------------------------------------------------------
    my @srcTokNodes=();          # 1) get all tokens
    my @trgTokNodes=();
    my @srcTok=$self->getSrcTokens($$param{general},\@srcTokNodes);
    my @trgTok=$self->getTrgTokens($$param{general},\@trgTokNodes);

    #----------------------------------------------------------------------
    my $srcNodes=[];             # 2) get all possible phrases
    my $trgNodes=[];
    my @srcPhr=$self->getSrcPhrases($$param{general},$srcNodes,
				    \@srcTokNodes,\@srcTok);
    my @trgPhr=$self->getTrgPhrases($$param{general},$trgNodes,
				    \@trgTokNodes,\@trgTok);

    #----------------------------------------------------------------------
    my @srcIdx=();               # 3) get token positions for each phrase
    my @trgIdx=();
    foreach (0..$#srcPhr){
	push (@srcIdx,$self->getPhrasePos($$srcNodes[$_],\@srcTokNodes));
    }
    foreach (0..$#trgPhr){
	push (@trgIdx,$self->getPhrasePos($$trgNodes[$_],\@trgTokNodes));
    }

    #----------------------------------------------------------------------

    foreach my $p (keys %{$param}){     # 4) generate phrase features
	if ($p eq 'general'){           #          a) general = phrase string
	    foreach (0..$#srcPhr){
		$$src{$srcIdx[$_]}{$p}=$srcPhr[$_];         # the source phrase
	    }
	    foreach (0..$#trgPhr){
		$$trg{$trgIdx[$_]}{$p}=$trgPhr[$_];         # the target phrase
	    }
	    next;
	}
	my $srcParam=$$param{$p};                  # b) feature parameter
	$self->makeParameter($srcParam,'source');  #    get source feature
	foreach (0..$#{$srcNodes}){
	    $$src{$srcIdx[$_]}{$p}=
		$self->{source}->getPhraseFeature(\@{$$srcNodes[$_]},
						  $srcParam);
	    if ((ref($$param{$p}) eq 'HASH') and 
		(defined $$param{$p}{'relative position'})){
		my $srcPos=$self->{source}->getPhrasePosition($$srcNodes[$_]);
		if ($$src{$srcIdx[$_]}{$p}=~/\S/){
		    $$src{$srcIdx[$_]}{$p}.=":pos($srcPos)";
		}
		else{
		    $$src{$srcIdx[$_]}{$p}="pos($srcPos)";
		}
	    }
	}
	my $trgParam=$$param{$p};                  #    get target features
	$self->makeParameter($trgParam,'target');  #    and generate feature
	foreach (0..$#{$trgNodes}){
	    $$trg{$trgIdx[$_]}{$p}=
		$self->{target}->getPhraseFeature(\@{$$trgNodes[$_]},
						  $trgParam);
	    if ((ref($$param{$p}) eq 'HASH') and 
		(defined $$param{$p}{'relative position'})){
		my $trgPos=$self->{target}->getPhrasePosition($$trgNodes[$_]);
		if ($$trg{$trgIdx[$_]}{$p}=~/\S/){
		    $$trg{$trgIdx[$_]}{$p}.=":pos($trgPos)";
		}
		else{
		    $$trg{$trgIdx[$_]}{$p}="pos($trgPos)";
		}
	    }
	}
    }
    if (ref($token) eq 'HASH'){
	@{$$token{source}}=@srcTok;
	@{$$token{target}}=@trgTok;

	if (ref($attr) eq 'HASH'){
	    @{$$attr{source}}=$self->{source}->attribute(\@srcTokNodes);
	    @{$$attr{target}}=$self->{target}->attribute(\@trgTokNodes);
	    foreach (0..$#srcTokNodes){
		$$attr{source}[$_]{content}=$self->content($srcTokNodes[$_]);
	    }
	    foreach (0..$#trgTokNodes){
		$$attr{target}[$_]{content}=$self->content($trgTokNodes[$_]);
	    }
	}
    }
}


sub getPhraseFeature{
    my $self=shift;
    my $lang=shift;
    my $nodes=shift;
    my $param=shift;
    if (not defined $lang){$lang='source'};
    if (not ref($self->{$lang})){return undef;}
#    $self->subData($self->{$lang},$lang);
#    $self->{$lang}=$self->subData($lang);
    $self->makeParameter($param,$lang);
    return $self->{$lang}->getPhraseFeature($nodes,$param,@_);
}

sub getSrcPhraseFeature{my $s=shift;return $s->getPhraseFeature('source',@_);}
sub getTrgPhraseFeature{my $s=shift;return $s->getPhraseFeature('target',@_);}

sub checkPairParameter{
    my $self=shift;
    my ($src,$trg,$param)=@_;
    if ($$param{'minimal length (source)'}){
	if (length($src)<$$param{'minimal length (source)'}){
#	    print STDERR "minimale length (source)\n";
	    return 0;
	}
    }
    if ($$param{'minimal length (target)'}){
	if (length($trg)<$$param{'minimal length (target)'}){
#	    print STDERR "minimale length (target)\n";
	    return 0;
	}
    }
    if ($$param{'minimal length diff'}){
	if ($self->lengthQuotient($src,$trg)<$$param{'minimal length diff'}){
#	    print STDERR "minimale length diff\n";
	    return 0;
	}
    }
    if ($$param{'matching word class'}){
	if (not $self->isSameType($src,$trg,$$param{'matching word class'})){
#	    print STDERR "matching word class\n";
	    return 0;
	}
    }
    if ($$param{'stop words'}){
	if (not $self->isSameType($src,$trg,$$param{'stop words'})){
#	    print STDERR "stop words\n";
	    return 0;
	}
    }
    return 1;
}


sub isSameType{
    my $self=shift;
    my ($src,$trg,$check)=@_;

    if (($check eq 'open/closed') or ($check eq 'same')){
	if ($self->{source}->isStopWord($src)){
	    return $self->{target}->isStopWord($trg);
	}
	return (not $self->{target}->isStopWord($trg));
    }
    elsif ($check eq 'exclude'){
	if (not $self->{source}->isStopWord($src)){
	    return 1;
	}
	return (not $self->{target}->isStopWord($trg));
    }
    elsif(($check eq 'same_class') or ($check eq 'wordclass')){
	return $self->isSameClass($src,$trg);
    }
    elsif(($check eq 'same_sub_class') or ($check eq 'subclass')){
	return $self->isSameSubClass($src,$trg);
    }
    return 1;
}


sub isSameClass{
    my $self=shift;
    my ($src,$trg)=@_;

    my $cat='stop word class hash';
    my $SrcData=$self->{source}->getLanguageData($cat);
    my $TrgData=$self->{target}->getLanguageData($cat);

    if (ref($SrcData) ne 'HASH'){return 1;}
    if (ref($TrgData) ne 'HASH'){return 1;}

    foreach my $c (%{$SrcData}){
	if (defined $$SrcData{$c}{$src}){
	    if (defined $$TrgData{$c}){
		if (defined $$TrgData{$c}{$trg}){
		    return 1;
		}
	    }
	    return 0;
	}

    }
    foreach my $c (%{$TrgData}){
	if (defined $$TrgData{$c}{$trg}){
	    return 0;
	}

    }
    return 1;
}

sub isSameSubClass{
    my $self=shift;
    my ($src,$trg)=@_;

    my $cat='stop word subclass hash';
    my $SrcData=$self->{source}->getLanguageData($cat);
    my $TrgData=$self->{target}->getLanguageData($cat);

    if (ref($SrcData) ne 'HASH'){return 1;}
    if (ref($TrgData) ne 'HASH'){return 1;}

    foreach my $x (%{$SrcData}){
	foreach my $y (%{$$SrcData{$x}}){
	    if (defined $$SrcData{$x}{$y}{$src}){
		if (defined $$TrgData{$x}){
		    if (defined $$TrgData{$x}{$y}){
			if (defined $$TrgData{$x}{$y}{$trg}){
			    return 1;
			}
		    }
		}
		return 0;
	    }
	}
    }
    foreach my $x (keys %{$TrgData}){
	foreach my $y (keys %{$$TrgData{$x}}){
	    if (defined $$TrgData{$x}{$y}{$trg}){
		return 0;
	    }
	}
    }
    return 1;
}



sub lengthQuotient{
    my $self=shift;
    my ($src,$trg)=@_;
    if (length($src)==0 or length($trg)==0) {return 0;}
    if (length($src)>length($trg)) {return length($trg)/length($src);}
    else {return length($src)/length($trg);}
}



sub makeParameter{
    my $self=shift;
    my ($param,$lang)=@_;
    if (ref($param) ne 'HASH'){return;}
    foreach (keys %{$param}){
	if (/^(.*) \($lang\)/){
	    $param->{$1}=$param->{$_};
	}
    }
}




sub rmLinkedToken{
    my $data=shift;

#    my $srcData=Uplug::Data::Lang->new;
#    my $trgData=Uplug::Data::Lang->new;
#    $data->subData($srcData,'source');
#    $data->subData($trgData,'target');
##    $data->{'source'}=$data->subData('source');
##    $data->{'target'}=$data->subData('target');

    my $srcData=$data->{source};
    my $trgData=$data->{target};

    my $link=$data->{link};
    my @nodes=$link->findNodes('wordLink');
    my @xtrg=$link->attribute(\@nodes,'xtargets');

    foreach my $l (@xtrg){
	if ($l=~/^(.*\S)\s?\;\s?(\S.*)$/){
	    my ($s,$t)=($1,$2);
	    $data->rmToken($s,$srcData);
	    $data->rmToken($t,$trgData);
	}
    }
}

sub rmToken{
    my $self=shift;
    my ($span,$data)=@_;
    my @token=split(/[\+\s]/,$span);
    foreach (@token){
	my ($node)=$data->findNodes('.*',{id => $_});
	if (defined $node){
	    $node->getParentNode->removeChild($node);
	    $node->dispose();
	}
    }
}

sub rmWordLinks{
    my $data=shift;
#    $data->{link}->delAttribute('wordLink');
    if (ref($data->{link})){
	$data->{link}->delNodes('wordLink');
    }
}

sub findLink{
    my $self=shift;
    my $link=shift;
    my %attr=();
    $attr{src}=$link->{source};
    $attr{trg}=$link->{target};
    my @nodes=$self->{link}->findNodes('wordLink',\%attr);
    if (@nodes){
	return @nodes;
    }
    return undef;
}


sub addWordLink{
    my $data=shift;
    my $link=shift;
    my $OutData=$data->{link};


    if (defined $data->findLink($link)){return;}

    my %attr=();

    if (defined $link->{score}){
	$attr{certainty}=$link->{score};
    }
    $attr{lexPair}=$link->{link};
    $attr{xtargets}="$link->{source};$link->{target}";
    $attr{xtargets}=~tr/:/+/;

    if ($link->{src} and $link->{trg}){
	$link->{src}=~tr/\&/\+/;
	$link->{trg}=~tr/\&/\+/;
	$attr{span}="$link->{src};$link->{trg}"
    }
    my $wordLink=$OutData->createNode('wordLink',\%attr);
    $OutData->addNode($wordLink);

#    if (defined $link->{step}){$attr{step}=$link->{step};}
#	    $attr{'id'}=$id;
#	    $attr{'content'}="\n$src:$trg\n";

}


sub toHTML{
    my $self=shift;
    my $html=$self->{source}->toHTML();
    $html.=$self->{target}->toHTML();
}
