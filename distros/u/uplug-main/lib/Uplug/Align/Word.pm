#-*-perl-*-
####################################################################
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
###########################################################################
# Uplug::Align::Word
#
# (best first aligner)
#
###########################################################################


package Uplug::Align::Word;

use strict;
# use Time::HiRes qw(time);
use vars qw($DEBUG @ISA $CLUEWEIGHT );

use Uplug::Data;
use Uplug::Data::Align;

# @ISA = qw( );

$CLUEWEIGHT = 0.05;
$DEBUG = 0;

sub new{
    my $class=shift;
    my $stream=shift;
    my $self={};
    bless $self,$class;
    if (ref($stream)){
	$self->{input}=$stream;
    }
    while ($_=shift){                       # set parameters!
	$self->setParameter($_,shift);

    }
    $self->{data}=Uplug::Data::Align->new($self->srcLanguage,$self->trgLanguage);
    $self->{dataCount}=0;

    return $self;
}

sub setLinkStreams{
    my $self=shift;
    my $streams=shift;
    if (ref($streams) eq 'HASH'){
	%{$self->{linkStreams}}=%{$streams};
    }
}

sub setInputStream{
    my $self=shift;
    my $stream=shift;
    $self->{input}=$stream;
}
sub setInput{my $self=shift;return $self->setInputStream(@_);}


sub read{
    my $self=shift;
    my $id=shift;
    $self->{dataCount}++;
    if (defined $id){
	return $self->{input}->select($self->{data},{id => $id});
    }
    return $self->{input}->read($self->{data});
}
sub readData{my $self=shift;return $self->read(@_);}

sub dataId{
    my $self=shift;

    if (defined $self->data->{link}){
	return $self->data->{link}->attribute('id');
    }
    my $id=$self->data->attribute('id');
    if (not defined $id){
	return $self->{dataCount};
    }
    return $id;
}

sub data{
    my $self=shift;
    return $self->{data};
}


sub align{
    my $self=shift;
    $self->{token}={};
    $self->{tokenAttr}={};
    $self->{srcToken}={};
    $self->{trgToken}={};
#    if ($self->getParameter('remove linked')){
#	$self->{data}->rmLinkedToken;
#    }

    my $time=time();

    if ($self->getParameter('non-aligned only')){  # --> align all tokens
	$self->{data}->rmLinkedToken;              #     which haven't been
    }                                              #     aligned yet
    else{                                          # otherwise:
	$self->{data}->rmWordLinks;                #     remove old links
    }
    $self->{data}->getBitextPhrases($self->{param},
				    $self->{srcToken},
				    $self->{trgToken},
				    $self->{token},
				    $self->{tokenAttr});

    $self->{nrSrcToken}+=$#{$self->{token}->{source}}+1;
    $self->{nrTrgToken}+=$#{$self->{token}->{target}}+1;
    ### DEBUG: store time for preparing data
    $self->{prepare_time}+=time()-$time;$time=time() if ($DEBUG);
    $self->getLinkScores();
    ### DEBUG: store time for retrieving clue scores
    $self->{get_scores_time}+=time()-$time;$time=time() if ($DEBUG);
    $self->findAlignment();
    ### DEBUG: store time for finding the best word alignment
    $self->{align_time}+=time()-$time if ($DEBUG);


#    if ($self->getParameter('remove word links')){
#	$self->{data}->rmWordLinks;
#    }
    return $self->{links};
}

sub getLinkScores{
    my $self=shift;

    $self->{linkProbs}={};
    $self->{links}={};
    my $LinkProb=$self->{linkProbs};
#    my $links=$self->{links};
    my $links=$self->{linkStreams};
    my $SrcTok=$self->{srcToken};
    my $TrgTok=$self->{trgToken};
    my $Param=$self->{param};
    my $data=$self->{data};
    my $MinScore=$self->scoreThreshold();

    foreach my $s (keys %{$SrcTok}){
	foreach my $t (keys %{$TrgTok}){

	    my ($src,$trg)=($$SrcTok{$s}{general},$$TrgTok{$t}{general});
	    if ($data->checkPairParameter($src,$trg,$$Param{general})){

		foreach (keys %{$links}){
		    my $weight=$self->defaultClueWeight();
		    if (ref($$Param{$_}) eq 'HASH'){
			if (defined $$Param{$_}{'score weight'}){
			    $weight=$$Param{$_}{'score weight'};
			}
		    }
		    my ($src,$trg)=($$SrcTok{$s}{$_},$$TrgTok{$t}{$_});
		    if ($src and $trg){
			if ($data->checkPairParameter($src,$trg,$$Param{$_})){
			    my %search=('source' => $src,
					'target' => $trg);
			    my $found=Uplug::Data->new;
			    if ($links->{$_}->select($found,\%search)){
				if ($self->checkScore($found,$$Param{$_})){
				    my $p=$$LinkProb{"$s\x00\x00$t"};

				    my $score=$found->attribute('score');

				    # shouldn't be >1, but in case ...
				    #--------------------------------
				    if ($score>1){$score=1;}
				    #--------------------------------
				    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				    # default: weight=0.5 for each score
				    $score*=$weight;
				    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

				    $$LinkProb{"$s\x00\x00$t"}=
					$p+$score-$p*$score;
				}
			    }
			}
		    }
		}
	    }
	}
    }
    foreach my $l (keys %{$LinkProb}){
	if ($$LinkProb{$l}<$MinScore){
	    delete $$LinkProb{$l};
	}
    }
}

sub findAlignment{
   my $self=shift;
    my $step=shift;

    $self->{links}={};
    my $MinScore=$self->scoreThreshold();

    my $LinkProb=$self->{linkProbs};
    my $Links=$self->{links};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};
    my $SrcTok=$self->{srcToken};
    my $TrgTok=$self->{trgToken};
    foreach (sort {$$LinkProb{$b} <=> $$LinkProb{$a}} keys %{$LinkProb}){
	if ($$LinkProb{$_}<$MinScore){last;}
	my ($s,$t)=split(/\x00\x00/,$_);
	if (not defined $$SrcTok{$s}){next;}
	if (not defined $$TrgTok{$t}){next;}

	my $link=$self->getLinkString($TokenAttr,$s,$t);

	$$Links{$s}{link}=$link;
	$$Links{$s}{source}=$self->ngramIDs($s,$TokenAttr,'source');
	$$Links{$s}{target}=$self->ngramIDs($t,$TokenAttr,'target');
	$$Links{$s}{score}=$$LinkProb{$_};
	if (defined $step){$$Links{$s}{step}=$step;} 
	my $span=$self->ngramSpans($s,$TokenAttr,'source');
	if ($span){$$Links{$s}{src}=$span;}
	$span=$self->ngramSpans($t,$TokenAttr,'target');
	if ($span){$$Links{$s}{trg}=$span;}

	&RemoveOverlap($s,$SrcTok);
	&RemoveOverlap($t,$TrgTok);
    }
}



sub getLinkString{
    my $self=shift;
    my ($TokenAttr,$s,$t)=@_;

    my $link='';
    my @tok=split(/:/,$s);
    foreach (@tok){
	$link.=$$TokenAttr{source}[$_]{content}.' ';
    }
    chop $link;
    $link.=';';
    my @tok=split(/:/,$t);
    foreach (@tok){
	$link.=$$TokenAttr{target}[$_]{content}.' ';
    }
    chop $link;
    return $link;
}

sub ngramIDs{
    my $self=shift;
    my ($pos,$attr,$l)=@_;
    my @arr=split(/\:/,$pos);
    my @res=();
    foreach (@arr){
	if (defined $$attr{$l}[$_]{id}){
	    push (@res,$$attr{$l}[$_]{id});
	}
	else{
	    push (@res,$_);
	}
    }
    return join ':',@res;
}

sub ngramSpans{
    my $self=shift;
    my ($pos,$attrs,$l)=@_;
    my @arr=split(/\:/,$pos);
    my @spans=();
    foreach (@arr){
	push (@spans,$$attrs{$l}[$_]{span});
    }
    return join '&',@spans;
}

sub makeRelPosFeature{
    my $self=shift;
    my ($src,$trg)=@_;
    if ($src=~/pos\((\-?[0-9]+)\)/){
	my $srcPos=$1;
	$src=~s/pos\((\-?[0-9]+)\)/x/;
	if ($trg=~/pos\((\-?[0-9]+)\)/){
	    my $relPos=$1-$srcPos;
	    $trg=~s/pos\((\-?[0-9]+)\)/$relPos/;
	}
    }
    return ($src,$trg);
}


sub printBitextToken{
    my $self=shift;
    my ($SrcTok,$TrgTok)=@_;
    print STDERR "\n";
    print STDERR join ' ',@{$SrcTok};
    print STDERR "\n";
    print STDERR join ' ',@{$TrgTok};
    print STDERR "\n\n";
}

sub tokenID{
    my $self=shift;
    my ($lang,$idx)=@_;
    if (ref($self->{tokenAttr}) eq 'HASH'){
	if (ref($self->{tokenAttr}->{$lang}) eq 'ARRAY'){
	    if (ref($self->{tokenAttr}->{$lang}->[$idx]) eq 'HASH'){
		return $self->{tokenAttr}->{$lang}->[$idx]->{id};
	    }
	}
    }
    return undef;
}

sub printBitextTokensWithID{
    my $self=shift;

    print STDERR "\n\n====================================================\n";
    print STDERR "bitext segment";
    print STDERR "\n====================================================\n";

    $self->printTokensWithID('source');
    $self->printTokensWithID('target');
}

sub printTokensWithID{
    my $self=shift;
    my $lang=shift;

    if (ref($self->{token}->{$lang}) eq 'ARRAY'){
	foreach (0..$#{$self->{token}->{$lang}}){
	    if (my $id=$self->tokenID($lang,$_)){
		print STDERR "$id:";
	    }
	    my $token = $self->{token}->{$lang}->[$_];
	    $token=~s/^\s*//;
#	    $token=~s/\s*$//;
#	    print STDERR $self->{token}->{$lang}->[$_];
	    print STDERR $token;
	    print STDERR " ";
	}
    }
    print STDERR "\n";
}



sub printBitextLink{
    my $self=shift;
    my $id=shift;
    my $link=shift;
    my ($src,$trg)=split(/;/,$$link{link});
    my $sidx = $$link{source};
    my $tidx = $$link{target};
    if (defined $$link{score}){
	print STDERR join "\t",($id,$sidx,$tidx,$src,$trg,$$link{score});
	print STDERR "\n";
#	printf STDERR "%s  %10s %-10s %s %s\t%s\n",
#	$id,$sidx,$tidx,$src,$trg,$$link{score};
    }
    else{
	print STDERR join "\t",($id,$sidx,$tidx,$src,$trg);
	print STDERR "\n";
	$id,$sidx,$tidx,$src,$trg;
    }
}


sub getNrLinks{
    my $self=shift;
    if (ref($self->{linkProbs}) eq 'HASH'){
	return scalar keys %{$self->{linkProbs}};
    }
    return undef;
}

sub getParameter{
    my $self=shift;
    return $self->parameter(@_);
}
sub parameter{
    my $self=shift;
    my $name=shift;
    return $self->{$name};
}
sub setParameter{
    my $self=shift;
    my ($attr,$val)=@_;
    $self->{$attr}=$val;
}

sub setLanguages{
    my $self=shift;
    my ($src,$trg)=@_;
    $self->setSrcLanguage($src);
    $self->setTrgLanguage($trg);
}

sub srcLanguage{
    my $self=shift;
    return $self->{'language (source)'};
}
sub trgLanguage{
    my $self=shift;
    return $self->{'language (target)'};
}

sub setSrcLanguage{
    my $self=shift;
    my ($src)=@_;
    $self->{'language (source)'}=$src;
    $self->{data}->{source}->setLanguage($src);
}
sub setTrgLanguage{
    my $self=shift;
    my ($trg)=@_;
    $self->{'language (target)'}=$trg;
    $self->{data}->{target}->setLanguage($trg);
}

sub searchMethod{
    my $self=shift;
    return $self->{search};
}
sub scoreThreshold{
    my $self=shift;
    return $self->{'minimal score'};
}

sub defaultClueWeight{
    my $self=shift;
    return $CLUEWEIGHT;
}

sub setSearchMethod{
    my $self=shift;
    $self->{search}=shift;
}
sub setScoreThreshold{
    my $self=shift;
    $self->{'minimal score'}=shift;
}
sub setRmLinkedFlag{
    my $self=shift;
    $self->{'remove linked'}=shift;
}
sub setLinkParam{
    my $self=shift;
    my $linkType=shift;
    my $param=shift;
    if (ref($param) eq 'HASH'){
	%{$self->{param}->{$linkType}}=%{$param};
#	if ($linkType!~/^general$/){
#	    if ($linkType!~/^original$/){
#		%{$self->{clueparam}->{$linkType}}=%{$param};
#	    }
#	}
    }
}

sub setLinkParams{
    my $self=shift;
    my $param=shift;
    if (ref($param) eq 'HASH'){
	foreach (keys %{$param}){
	    $self->setLinkParam($_,$param->{$_});
	}
    }
}


sub checkScore{
    my $self=shift;
    my ($data,$param)=@_;
    my $score=$data->attribute('score');
    if (not defined $score){return 0;}
#    if (defined $$param{normalize}){
## ........
#    }
    if (defined $$param{'minimal score'}){
	if ($score<$$param{'minimal score'}){
#	    print STDERR "score too low\n";
	    return 0;
	}
    }
#    if ($score<$$param{general}{'minimal score'}){
#	return 0;
#    }
    return 1;
}




sub linksToHtml{
    my $self=shift;
    my $links=$self->{links};
    my $split=8;
    my $count=0;
    my $html;
    if (ref($links) eq 'HASH'){
	$html="<div class=\"alignments\"><table cellspacing=\"10\">";
	foreach my $l (keys %{$links}){
	    if ((not $count % $split) || ($count==0)){
		if ($count){$html.="</table></td>";}
		$html.="<td valign=\"top\"><table cellspacing=1 border=0><tr>";
		$html.="<th bgcolor=\"#c9c9c9\">source</th>";
		$html.="<th bgcolor=\"#c9c9c9\">target</th>";
		$html.="</tr>";
	    }
	    my ($src,$trg)=split(/;/,$$links{$l}{link});
	    $html.="<tr><td bgcolor=\"#EEEEEE\" align='center'>$src</td>";
	    $html.="<td bgcolor=\"#E4EEEE\" align='center'>$trg</td></tr>\n";
	    $count++;
	}
	$html.='</table></td></table></div>';
    }
    return $html;
}













#--------------------------------------------------------------------------
# remove overlapping alignments
#

sub RemoveOverlap{
    my ($id,$token)=@_;
    my $pat='('.$id.')';
    $pat=~tr/:/|/;
    foreach (keys %{$token}){
	if (/(\A|\:)$pat(\:|\Z)/){
	    delete $token->{$_};
	}
    }
}



1;


__END__
