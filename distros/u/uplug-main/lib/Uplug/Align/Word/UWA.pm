#-*-perl-*-
#
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


sub getLinkScoresUwa1{
    my $self=shift;
    $self->{linkProbs}={};
    &GetLinkScoresUwa1($self->{linkProbs},
		       $self->{linkStreams},
		       $self->{srcToken},
		       $self->{trgToken},
		       $self->{param},
		       $self->{data});
}

sub getLinkScoresUwa2{
    my $self=shift;
    $self->{linkProbs}={};
    &GetLinkScoresUwa2($self->{linkProbs},
		       $self->{linkStreams},
		       $self->{srcToken},
		       $self->{trgToken},
		       $self->{param},
		       $self->{data});
}

sub uwaSearch{
    my $self=shift;
    my $links=shift;
    my $minScore=$self->scoreThreshold();
    return &UwaAlign($links,
		     $self->{linkProbs},
		     $self->{token},
		     $self->{tokenAttr},
		     $self->{srcToken},
		     $self->{trgToken},
		     $minScore);
}




#--------------------------------------------------------------------------
# uwa style
#--------------------------------------------------------------------------



sub GetLinkScoresUwa1{
#    my $self=shift;
    my ($LinkProb,$links,$SrcTok,$TrgTok,$Param,$data)=@_;

    foreach my $s (keys %{$SrcTok}){
	foreach my $t (keys %{$TrgTok}){

	    my ($src,$trg)=($$SrcTok{$s}{general},$$TrgTok{$t}{general});
	    if ($data->checkPairParameter($src,$trg,$$Param{general})){
#	    if (&TokenPairParameter($src,$trg,$$Param{general})){

		foreach (keys %{$links}){
		    my ($src,$trg)=($$SrcTok{$s}{$_},$$TrgTok{$t}{$_});
		    if ($src and $trg){
			if ($data->checkPairParameter($src,$trg,$$Param{$_})){
#			if (&TokenPairParameter($src,$trg,$$Param{$_})){
			    my %search=('source' => $src,
					'target' => $trg);
			    my $found=uplugTreeData->new;
			    if ($links->{$_}->select($found,\%search)){
				if (&CheckScore($found,$$Param{$_})){
				    my $p=$$LinkProb{"$s\x00\x00$t"};

				    my $score=$found->attribute('score');

				    # shouldn't be >1, but in case ...
				    #--------------------------------
				    if ($score>1){$score=1;}
				    #--------------------------------
				    $$LinkProb{$_}{"$s\x00\x00$t"}=$score;
				}
			    }
			}
		    }
		}
	    }
	}
    }
    foreach my $l (keys %{$LinkProb}){
	if ($$LinkProb{$l}<$$Param{general}{'minimal score'}){
	    delete $$LinkProb{$l};
	}
    }
}



sub UwaAlign{
#    my $self=shift;
    my ($Links,$LinkProb,$Token,$TokenAttr,$SrcTok,$TrgTok,$MinScore)=@_;
    my @steps=(
	       'identical num',
	       'co-occurrence',
	       'string similarities',
	       'basic',
	       'low',
	       'previous',
	       'co-occurrence',
	       'string similarities',
	       '1:1'
	       );
    my @para;
    $para[1]{score}=0.7;
    $para[2]{score}=0.7;
    $para[6]{score}=0.4;
    $para[7]{score}=0.4;

    foreach (0..$#steps){

	if ($steps[$_]=~/identical num/){
	    foreach my $s (0..$#{$$SrcTok{general}}){
		my $src=$$SrcTok{general}[$s];
		&SetLanguage($lang{source});
		if (&IsNumeric($src)){
		    foreach my $t (0..$#{$$TrgTok{general}}){
			my $trg=$$TrgTok{general}[$t];
			if ($trg eq $src){
			    &AddLink($s,$t,$Links,$Token,$TokenAttr);
			    $Links->{$s}->{step}=$_;
			    &RemoveOverlap($s,$SrcTok);
			    &RemoveOverlap($t,$TrgTok);
			}
		    }
		}
	    }
	}
	elsif ($steps[$_]=~/1\:(.)/){
	    my $nr=$1;
	    if ($nr==1){
		if ((scalar keys %{$SrcTok} == 1) and 
		    (scalar keys %{$TrgTok} == 1)){
		    my ($s)=each %{$SrcTok};
		    my ($t)=each %{$TrgTok};
		    &AddLink($s,$t,$Links,$Token,$TokenAttr);
		    $Links->{$s}->{step}=$_;
		    &RemoveOverlap($s,$SrcTok);
		    &RemoveOverlap($t,$TrgTok);
		}
	    }
	    else{
		if ((scalar keys %{$SrcTok} == 1) or 
		    (scalar keys %{$TrgTok} == 1)){
		    my ($s)=each %{$SrcTok};
		    my ($t)=each %{$TrgTok};
		    &AddLink($s,$t,$Links,$Token,$TokenAttr);
		    $Links->{$s}->{step}=$_;
		    &RemoveOverlap($s,$SrcTok);
		    &RemoveOverlap($t,$TrgTok);
		}
	    }
	}
	elsif ($steps[$_]=~/basic/){
	}
	elsif ($steps[$_]=~/previous/){
	}
	elsif ($steps[$_]=~/low/){
	}
	elsif (defined $LinkProb->{$steps[$_]}){
	    if (defined $para[$_]{score}){
		$MinScore=$para[$_]{score};
	    }
	    &BestFirstSearch($Links,$LinkProb->{$steps[$_]},
			      $Token,$TokenAttr,$SrcTok,$TrgTok,$MinScore,$_);
	}
    }
}


sub AddLink{
#    my $self=shift;
    my ($s,$t,$Links,$Token,$TokenAttr)=@_;
    my $link=&GetLinkString($TokenAttr,$s,$t);

    $$Links{$s}{link}=$link;
    $$Links{$s}{source}=&NgramIDs($s,$TokenAttr,'source');
    $$Links{$s}{target}=&NgramIDs($t,$TokenAttr,'target');
    my $span=&NgramSpans($s,$TokenAttr,'source');
    if ($span){$$Links{$s}{src}=$span;}
    $span=&NgramSpans($t,$TokenAttr,'target');
    if ($span){$$Links{$s}{trg}=$span;}
}

1;
