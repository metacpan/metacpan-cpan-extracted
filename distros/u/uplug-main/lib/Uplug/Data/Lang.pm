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
#
#
#
###########################################################################


package Uplug::Data::Lang;

use strict;
use vars qw( @ISA 
	     $DEFAULTLANGUAGE $DEFAULTLANGUAGEFILE
	     $DEFAULTSPLITPATTERN $DEFAULTDELIMITER );

use Uplug::Data;
use Uplug::Config;

#----------------------
# Uplug::Data::Lang is derived from
#    either Uplug::Data::XML
#    either Uplug::Data::Tree
#        or Uplug::Data::DOM   (otherwise)
# depending on $Uplug::Data::DEFAULTDATATYPE
#----------------------

@ISA=qw( Uplug::Data );

$DEFAULTLANGUAGE = 'default';
$DEFAULTLANGUAGEFILE = 'default.ini';
$DEFAULTSPLITPATTERN = '\s+';
$DEFAULTDELIMITER=$Uplug::Data::DEFAULTDELIMITER;



sub init{
    my $self=shift;
    my $language=shift;
    if ((defined $language) or (not ref($self->{LanguageData}))){
	$self->{LanguageData}={};
	if ((defined $language) and ($self->{language} ne $language)){
	    $self->loadLanguageFile($language.'.ini');
	}
#	if (not $language){$language=$DEFAULTLANGUAGE;}
#	if ($self->{language} ne $language){
#	    $self->{language}=$language;
#	    $self->loadLanguageFile($language.'.ini');
#	}
    }
    return $self->SUPER::init(@_);
}

sub clone{return Uplug::Data::Lang->new();}

sub loadLanguageFile{
    my $self=shift;
    my $file=shift;
    my $lang=$self->getLanguage();
    $self->{LanguageData}=&ReadConfig($file);
#    &LoadIniData($self->{LanguageData},$file);
    if (defined $self->{LanguageData}->{$lang}){              # we don't need
	$self->{LanguageData}=$self->{LanguageData}->{$lang}; # a root node!
    }
    return $self->initLanguageData();
}

sub setLanguage{
    my $self=shift;
    my $lang=shift;
    if ($lang ne $self->getLanguage()){
	$self->{language}=$lang;
	return $self->loadLanguageFile($lang.'.ini');
    }
    return 1;
}

sub getLanguage{return $_[0]->{language};}
sub language{return $_[0]->getLanguage();}

sub getLanguageData{
    my $self=shift;
    my ($cat,$subcat,$attr)=@_;
    my $data=$self->{LanguageData};
    if ((defined $cat) and (defined $data->{$cat})){
	if ((defined $subcat) and (defined $data->{$cat}->{$subcat})){
	    if ((defined $attr) and 
		(defined $data->{$cat}->{$subcat}->{$attr})){
		return $data->{$cat}->{$subcat}->{$attr};
	    }
	    elsif (defined $attr){return undef;}
	    return $data->{$cat}->{$subcat};
	}
	elsif (defined $subcat){return undef;}
	return $data->{$cat};
    }
    elsif (defined $cat){return undef;}
    return $data;
}
sub languageData{return $_[0]->getLanguageData(@_);}



#----------------------------------------------------------------------------
# initLanguageData:
#
#      initialize language specific data hashs!
#


sub initLanguageData{
    my $self=shift;

#----------------------------------------------------------------------------
# make skip token hashs (from skip token arrays)
#----------------------------------------------------------------------------

    my @skip=('skip phrase before',
	      'skip phrase after',
	      'skip phrase at',
	      'skip token',
	      'non-phrase-starter',
	      'non-phrase-ender');

    my $data=$self->getLanguageData();

    if (defined $$data{'phrases'}){
	foreach (@skip){
	    if (defined $$data{'phrases'}{$_}){
		if (ref($$data{'phrases'}{$_}) eq 'ARRAY'){
		    my @SkipWords=@{$$data{'phrases'}{$_}};
		    %{$$data{'phrases'}{"$_ hash"}}=();
		    &ArrayToHash(\@SkipWords,$$data{'phrases'}{"$_ hash"});
		}
	    }
	}
    }

#----------------------------------------------------------------------------
# make skip token string type arrays
#----------------------------------------------------------------------------

    if (defined $$data{'phrases'}){
	foreach (@skip){
	    if (defined $$data{'phrases'}{"$_ string type"}){
	       if (ref($$data{'phrases'}{"$_ string type"}) ne 'ARRAY'){
		   my @arr=$$data{'phrases'}{"$_ string type"};
		   delete $$data{'phrases'}{"$_ string type"};
		   @{$$data{'phrases'}{"$_ string type"}}=@arr;
	       }
	   }

	}
    }

#----------------------------------------------------------------------------
# make stop word hashs (from stop word arrays)
#----------------------------------------------------------------------------

    if (defined $$data{'stop words'}){
	if (defined $$data{'stop words'}{'wordform'}){
	    my @words=@{$$data{'stop words'}{'wordform'}};
	    &ArrayToHash(\@words,$$data{'stop word hash'},$data);
	}
	if (defined $$data{'stop words'}{'classes'}){
	    my ($cat,$subcat);
	    foreach $cat (@{$$data{'stop words'}{'classes'}}){
		if (defined $$data{$cat}){
		    foreach $subcat (keys %{$$data{$cat}}){
			foreach (@{$$data{$cat}{$subcat}}){
			    $$data{'stop word hash'}{$_}=1;
			    $$data{'stop word class hash'}{$cat}{$_}=1;
			    $$data{'stop word subclass hash'}{$cat}{$subcat}{$_}=1;
			}
		    }
		}
	    }
	}
    }

#----------------------------------------------------------------------------
# define some special character classes
#----------------------------------------------------------------------------

    my $cat='character specifications';

    $$data{$cat}{'alphabetic'}=$$data{$cat}{'letter'}.$$data{$cat}{'hyphen'};
    $$data{$cat}{'alphanumeric'}=
	$$data{$cat}{'letter'}.
	    $$data{$cat}{'hyphen'}.
		$$data{$cat}{'digit'}.
		    $$data{$cat}{'numeric symbol'};
    $$data{$cat}{'numeric'}=
	$$data{$cat}{'digit'}.$$data{$cat}{'numeric symbol'};

#------- compatibility with old spelling errors ....... -------------------

    $$data{$cat}{'alpha'}=$$data{$cat}{'alphabetic'};
    $$data{$cat}{'vowels'}=$$data{$cat}{'vowel'};
    $$data{$cat}{'consonants'}=$$data{$cat}{'consonant'};
    $$data{$cat}{'vocals'}=$$data{$cat}{'vowel'};
}


#####################################################################
# check stop word classes
#####################################################################



sub isStopWord{
    my $self=shift;
    my ($str)=@_;
    my $cat='stop word hash';
    my $data=$self->getLanguageData($cat);
    if (ref($data) eq 'HASH'){
	if (defined $$data{$str}){
	    return 1;
	}
    }
    return 0;
}


#####################################################################
# string processing functions
#####################################################################


# split into VC sequences ....

sub splitIntoVC{
    my $self=shift;
    my $str=shift;

    my $cat='character specifications';
    my $Vowel=$self->getLanguageData($cat,'vowel');
    my $Consonant=$self->getLanguageData($cat,'consonant');
    if (not $Vowel){return ($str);}
    if (not $Consonant){return ($str);}

    my @arr=();
    while ($str ne ''){
	if ($str=~/^([$Vowel]+)([^$Vowel].*)$/){
	    push (@arr,$1);
	    $str=$2;
	}
	elsif ($str=~/^([$Consonant]+)([^$Consonant].*)$/){
	    push (@arr,$1);
	    $str=$2;
	}
	elsif ($str=~/^([^$Vowel$Consonant]+)(.*)$/){
	    push (@arr,$1);
	    $str=$2;
	}
	else{
	    push @arr,$str;
	    $str='';
	}
    }
    return @arr;
}



#-----------------------------------------------------------------------------
# getTokens
#
# get all tokens which match the parameters in %{$param}
#

sub getTokens{
    my $self=shift;
    my $param=shift;
    my $accepted=shift;

    if (ref($accepted) ne 'ARRAY'){
	$accepted=[];
    }
    my @nodes;
    my @tokens=();

    if (not defined $$param{'token label'}){
	@nodes=$self->contentElements();
    }
    else{
	@nodes=$self->findNodes($$param{'token label'});
    }
    my @accepted=();
    foreach my $n (@nodes){
	if (defined (my $t=$self->checkTokenParameter($n,$param))){
	    push(@{$accepted},$n);
	    push(@tokens,$t);
	}
    }
    return @tokens;
}


#---------------------------------------------------------------
# GetChunks
#
# get all chunks from data which have been labeled with $label
#


sub getChunks{
    my $self=shift;
    my $param=shift;
    my ($phraseNodes,$tokenNodes,$tokens,$del)=@_;

    my @phrases=();
    if (not defined $del){$del=$DEFAULTDELIMITER;}
    if (not ref($tokenNodes)){
	$tokens=[];
	$tokenNodes=[];
	@{$tokens}=$self->getTokens($param,$tokenNodes);
    }

    #----------------------------------------------------------------------
    # check certain markup for additional phrases
    # (chunks etc.)

    if (defined $$param{'chunks'}){
	my @chunks=$self->findNodes($$param{'chunks'});
	foreach my $c (@chunks){
	    if (not ref($c)){next;}
	    my @nodes;
	    if (defined $$param{'token label'}){
#		@nodes=$self->findNodes($$param{'token label'},undef,$c);
		@nodes=$c->getElementsByTagName($$param{'token label'});
	    }
	    else{@nodes=$c->getElementsByTagName('*');}
#	    else{@nodes=$self->findNodes('*',undef,$c);}

	    my @chunk=();                              # find accepted tokens
	    my @chunkNodes=();                         # in the chunk
	    foreach my $x (@nodes){
		foreach my $y (0..$#{$tokenNodes}){
		    if ($x==$$tokenNodes[$y]){
			push(@chunkNodes,$$tokenNodes[$y]);
			if (ref($tokens) eq 'ARRAY'){
			    push(@chunk,$$tokens[$y]);
			}
		    }
		}
	    }

	    if (@chunkNodes){
		if (ref($phraseNodes)){
		    my $idx=$#{$phraseNodes}+1;
		    @{$$phraseNodes[$idx]}=@chunkNodes;
		}
		if (@chunk){
		    push (@phrases,join $del,@chunk);
		}
		else{
		    my $idx=$#phrases+1;
		    push (@phrases,'#chunk'.$idx);
		}
#	    $phrases[$idx]="chunk:".$phrases[$idx]
	    }
	}
    }
    return @phrases;
}


#---------------------------------------------------------------
# GetNgrams
#
# get all ngrams from data
#


sub getNgrams{
    my $self=shift;
    my $param=shift;
    my ($phraseNodes,$tokenNodes,$tokens,$del)=@_;

    my $minTokenLength=1;
    my $maxNgramLength=1;
    if (defined $$param{'minimal length'}){
	$minTokenLength=$$param{'minimal length'};
    }
    if (defined $$param{'maximal ngram length'}){
	$maxNgramLength=$$param{'maximal ngram length'};
    }
    if ($maxNgramLength<2){return;}

    #----------------------------------------------------------------------
    # 1) get tokens if necessary
    #----------------------------------------------------------------------

    my @phrases=();
    if (not defined $del){$del=$DEFAULTDELIMITER;}
    if (not ref($tokenNodes)){
	$tokens=[];
	$tokenNodes=[];
	@{$tokens}=$self->getTokens($param,$tokenNodes);
    }
    if (not ref($tokens)){$tokens=[];}
    foreach (0..$#{$tokenNodes}){
	if (not defined $$tokens[$_]){
	    $$tokens[$_]=$self->content($$tokenNodes[$_]);
	}
    }

    #----------------------------------------------------------------------
    # 2) compute all N-grams (N>1)
    #----------------------------------------------------------------------

    my @Ngram=();
    my @NgramNodes=();
    my @words=@{$tokens};                      # save tokens in a new array
    my @nodes=@{$tokenNodes};                  # and corresponding nodes, too
    push (@Ngram,shift(@words));               # (because we're shifting all
    push (@NgramNodes,shift(@nodes));          #  tokens from the array)

    while (@words){

	my $t=shift(@words);
	my $n=shift(@nodes);

#	print STDERR "length: $minTokenLength\n";
#	if (length($t)<$minTokenLength){
#	    print STDERR "skip $t\n";
#	    next;
#	}
#	if ((length($t)<$minTokenLength) or ($self->skipToken($t))){

	if ($self->skipToken($t)){
	    $self->addNgrams(\@Ngram,\@NgramNodes,\@phrases,$phraseNodes,$del);
#	    print STDERR "skip $t\n";
	    @Ngram=();
	    @NgramNodes=();
	    next;
	}
	elsif ($self->skipPhraseAt($t)){
	    $self->addNgrams(\@Ngram,\@NgramNodes,\@phrases,$phraseNodes,$del);
#	    print STDERR "skip at $t\n";
	    @Ngram=();
	    @NgramNodes=();
	    next;
	}
	elsif ($self->skipPhraseBefore($t)){
	    $self->addNgrams(\@Ngram,\@NgramNodes,\@phrases,$phraseNodes,$del);
	    @Ngram=();
	    @NgramNodes=();
#	    print STDERR "skip before $t\n";
	}

	push (@Ngram,$t);
	push (@NgramNodes,$n);

	if (scalar @Ngram == $maxNgramLength){
	    $self->addNgrams(\@Ngram,\@NgramNodes,\@phrases,$phraseNodes,$del);
	    shift (@Ngram);
	    shift (@NgramNodes);
#	    print STDERR "length = max\n";
	}
	if ($self->skipPhraseAfter($t)){
	    $self->addNgrams(\@Ngram,\@NgramNodes,\@phrases,$phraseNodes,$del);
	    @Ngram=();
	    @NgramNodes=();
#	    print STDERR "skip after $t\n";
	}
    }
    $self->addNgrams(\@Ngram,\@NgramNodes,\@phrases,$phraseNodes,$del);
    return @phrases;
}


#-----------------------------------------------------------
# $OBJ->getPhrases($param,\@phraseNodes)
#
#  get phrase candidates
#     @phraseNodes: list of lists of data-nodes
#
#


sub getPhrases{
    my $self=shift;
    my $param=shift;
    my ($phraseNodes,$tokenNodes,$tokens,$del)=@_;

    if (not defined $del){$del=$DEFAULTDELIMITER;}
    if (not ref($tokenNodes)){
	$tokens=[];
	$tokenNodes=[];
	@{$tokens}=$self->getTokens($param,$tokenNodes);
    }

    my @phrases=$self->getChunks($param,$phraseNodes,$tokenNodes,$tokens,$del);
    my @ngrams=$self->getNgrams($param,$phraseNodes,$tokenNodes,$tokens,$del);
    push (@phrases,@ngrams);

#----------------------------------------------------------------------
# add all single tokens that match the required string type
#----------------------------------------------------------------------

#    my $minTokenLength=1;
#    if (defined $$param{'minimal length'}){
#	$minTokenLength=$$param{'minimal length'};
#    }
    foreach (0..$#{$tokenNodes}){
	if (not ref($tokens) or $self->skipToken($$tokens[$_])){next;}
#	if (length($$tokens[$_])<$minTokenLength){next;}
	my $idx=$#phrases+1;
	if (ref($phraseNodes)){
	    @{$$phraseNodes[$idx]}=($$tokenNodes[$_]);
	}
	if (ref($tokens)){
	    push (@phrases,$$tokens[$_]);
	}
	else{
	    push (@phrases,'#token'.$idx);
	}
    }

    @phrases=$self->removeIdenticalPhrases($phraseNodes,\@phrases);
    return @phrases;
}      



sub getPhrasePosition{
    my $self=shift;
    my ($phr)=@_;
    if (ref($phr) ne 'ARRAY'){return 0;}
    my $tok=$phr->[0];
    if (not ref($tok)){return 0;}
    my $tokID=$self->attribute($tok,'id');
    if ($tokID=~/(\A|[^0-9])([0-9]+)$/){
	return $2;
    }
    return undef;
}


sub getPhraseContent{
    my $self=shift;
    my $nodes=shift;
    my $param=shift;
    my ($del)=@_;

    if (not defined $del){$del=$DEFAULTDELIMITER;}
    my @phrase=();
    foreach my $n (@{$nodes}){
	if (my $t=$self->checkTokenParameter($n,$param)){
	    push(@phrase,$t);
	}
    }
    return join $del,@phrase;
}

sub getPhraseFeature{
    my $self=shift;
    my ($phraseNodes,$param)=@_;

    if (ref($phraseNodes) ne 'ARRAY'){return undef;}
    if (not @{$phraseNodes}){return '';}


    if (not ref($param)){return $self->getPhraseContent($phraseNodes,$param);}
    if (ref($param->{features}) ne 'HASH'){
	return $self->getPhraseContent($phraseNodes,$param);
    }

    my $FeatureString='';
    foreach my $f (sort keys %{$param->{features}}){  # for all features:

	my %NodeHash=();       # feature node names
	my @FeatNodes=();      # array of unique feature nodes
	my @AllFeatNodes=();   # array of all feature nodes (for suffix/prefix)
	my $attr=$f;           # initialize feature-attribute
	my $path=undef;        # initialize feature-node path
#	print STDERR "$f\n";
	if ($f=~/^(.*)\:([^:]+)$/){                   # first part is the path
	    ($path,$attr)=($1,$2);                    # second is the attribute
	}

	foreach my $t (@{$phraseNodes}){              # for all token nodes:
	    my $node=$self->getFeatureNode($t,$path); #   find the feature node
	    push(@AllFeatNodes,$node);                #   save feature nodes
	    if (not ref($node)){next;}
	    if (not defined $NodeHash{$node}){
		$NodeHash{$node}=1;                   #  save unique
		push(@FeatNodes,$node);               #  feature nodes
	    }
	}

	#---------------------------------------------------------------
	# check if the left neighbour of the first token has the same
	#   feature node as the first token itself ---> add prefix ')'
	# check if the right neighbour of the last token has the same
	#   feature node as the last token itself ---> add suffix '('
	#
	# e.g., if the feature node is a chunk-node
	# and the neighbours of the current phrase belong to the same chunk

	my $prefix;
	my $suffix;
	my $node=$self->getFeatureNode($$phraseNodes[0],'left:'.$path);
	if ($node and ($node eq $AllFeatNodes[0])){
	    $prefix=')';
	}
	my $node=$self->getFeatureNode($$phraseNodes[-1],'right:'.$path);
	if ($node and ($node eq $AllFeatNodes[-1])){
	    $suffix='(';
	}

	#---------------------------------------------------------------


	my $feature='';
	my $pattern=$param->{features}->{$f};          # substitution pattern
	my $re=undef;                                  # regular expression
	my $subst=undef;                               # substitution
	if ($pattern=~/(.*)\/(.*)/){                   # subst.-pattern found:
	    $re=$1;                                    #   set variables
	    $subst=$2;
	}

	foreach my $n (@FeatNodes){                    # for all feature nodes:
	    my $value;                                 #   get feature string
	    if ($attr eq '#text'){
		$value=$self->content($n);
	    }
	    else{
		$value=$self->attribute($n,$attr);
	    }
	    if (defined $re){
#		eval { $value=~s/$re/$subst/; }
		eval "\$value=~s/$re/$subst/;";        # change thos ?!?
	    }
	    $feature.=$value.' ';
	}
	chop $feature;
	$FeatureString.=$prefix.$feature.$suffix.':'; # put everything together
    }
    chop $FeatureString;
    return $FeatureString;
}


sub getFeatureNode{
    my $self=shift;
    return $self->moveTo(@_);
}


#-----------------------------------------------------------
#

sub removeIdenticalPhrases{
    my $self=shift;
    my ($nodes,$phrases)=@_;

    if ((not ref($nodes)) and (ref($phrases))){    # easy! just check strings!
	my %hash=();
	foreach (@{$phrases}){$hash{$_}=1;}
	return keys %hash;
    }
    if (ref($nodes) ne 'ARRAY'){return undef;}
    my @accNodes=();
    my @accPhrases=();
    my %hash;
    foreach my $p (0..$#{$nodes}){
	my $key=join "\x00",@{$$nodes[$p]};
	if (not defined $hash{$key}){
	    $hash{$key}=1;
	    push(@accNodes,$$nodes[$p]);
	    if (ref($phrases)){
		push(@accPhrases,$$phrases[$p]);
	    }
	}
#	else{print STDERR "remove phrase $$phrases[$p]\n";}
    }
    @{$nodes}=@accNodes;
    return @accPhrases;
}


#---------------------------------
# add all Ngrams and sub-Ngrams
#

sub addNgrams{
    my $self=shift;
    my $tokens=shift;
    my $nodes=shift;

    if ($#{$tokens}<1){return;}             # at least bigram!
    $self->addNgram($tokens,$nodes,@_);     # add this Ngram

    my $t=shift @{$tokens};                 # recursively add N-1_grams
    my $n=shift @{$nodes};                  #   * without the initial token
    $self->addNgrams($tokens,$nodes,@_);
    unshift(@{$tokens},$t);
    unshift(@{$nodes},$n);
    $t=pop @{$tokens};                      #   * without the final token
    $n=pop @{$nodes};
    $self->addNgrams($tokens,$nodes,@_);
    push(@{$tokens},$t);                    # always restore
    push(@{$nodes},$n);                     # the original arrays!
}

#---------------------------------
# add Ngram
#

sub addNgram{
    my $self=shift;
    my ($tokens,$nodes,$ngrams,$ngramNodes,$del)=@_;

    if ($#{$tokens}<1){return;}                              # at least bigram
    if (not $self->isNonStarter($$tokens[0])){               # no non-starter
	if (not $self->isNonEnder($$tokens[-1])){            # no non-ender
	    if (not defined $del){$del=$DEFAULTDELIMITER;}
	    if (ref($ngramNodes) eq 'ARRAY'){
		my $idx=$#{$ngramNodes}+1;
		@{$$ngramNodes[$idx]}=@{$nodes};
	    }
	    if (ref($ngrams) eq 'ARRAY'){
		push(@{$ngrams},join $del,@{$tokens});
	    }
	}
    }
}





sub checkTokenParameter{
    my $self=shift;
    my $node=shift;
    my $param=shift;

    if (not ref($node)){return undef;}
    my $token=$self->content($node);
    if (ref($param) ne 'HASH'){return $token;}

    if (defined $$param{'use attribute'}){
	my $attr=$self->attribute($node,$$param{'use attribute'});
	if (defined $attr){$token=$attr;}
#	else{$token='_undef';}
    }
    if ($$param{'grep token'}){
	if (not $self->isStringType($token,$$param{'grep token'})){
	    return undef;
	}
    }
    if (defined $$param{'minimal length'}){
	if (length($token)<$$param{'minimal length'}){
	    return undef;
	}
    }
    if ($$param{'lower case'}){
	return $self->lowerCase($token);
    }
    return $token;
}



sub makeLowInitial{
    my $self=shift;
    my $string=shift(@_);
    my $LowerCaseLetter=$self->getLanguageData('character specifications',
					       'lower case letter');
    if (not $LowerCaseLetter){return $string;}
    if ($string=~/^(.)[$LowerCaseLetter]/){
	my $low=$self->lowerCase($1);
	$string=~s/^./$low/;
    }
    elsif ($string=~/^.$/){
	$string=$self->LowerCase($string);
    }
    return $string;
}

# convert string to low case characters

sub lowerCase {
    my $self=shift;
    my $string=shift(@_);
    my $LowerCaseLetter=
	$self->getLanguageData('character specifications','lower case letter');
    my $UpperCaseLetter=
	$self->getLanguageData('character specifications','upper case letter');

    if ((not $UpperCaseLetter) or (not $LowerCaseLetter)){
	return lc($string);
    }

    eval "\$string\=\~tr/$UpperCaseLetter/$LowerCaseLetter/;";
    return $string;
}

# get number of alphabetic characters in string

sub containsAlpha {
    my $self=shift;
    my $string=shift(@_);
    my $Letter=$self->getLanguageData('character specifications','letter');
    my $result=eval("\$string\=\~tr/$Letter//");
    return $result;
}

sub containsNumeric {
    my $self=shift;
    my $string=shift(@_);
    my $Numeric=$self->getLanguageData('character specifications','numeric');
    if (not $Numeric){return 0;}
    my $pattern="\[$Numeric\]";
    return $string=~/$pattern/;
}

sub isVowel {
    my $self=shift;
    my $string=shift;
    my $Vowel=$self->getLanguageData('character specifications','vowel');
    my $pattern="\[$Vowel\]\+";
    if (not $Vowel){return 0;}
    return $string=~/^$pattern$/;
}

sub isConsonant {
    my $self=shift;
    my $string=shift;
    my $Consonant=
	$self->getLanguageData('character specifications','consonant');
    my $pattern="\[$Consonant\]\+";
    if (not $Consonant){return 0;}
    return $string=~/^$pattern$/;
}

sub isLetter {
    my $self=shift;
    my $string=shift;
    my $Letter=$self->getLanguageData('character specifications','letter');
    if (not $Letter){return 0;}
    my $pattern="\[$Letter\]";
    return $string=~/^$pattern$/;
}

sub isLetterSeq {
    my $self=shift;
    my $string=shift;
    my $Letter=$self->getLanguageData('character specifications','letter');
    if (not $Letter){return 0;}
    my $pattern="\[$Letter\]\+";
    return $string=~/^$pattern$/;
}

sub isAlphabetic {
    my $self=shift;
    my $string=shift;
    my $Alphabetic=
	$self->getLanguageData('character specifications','alphabetic');
    if (not $Alphabetic){return 0;}
    my $pattern="\[$Alphabetic\]\+";
    return $string=~/^$pattern$/;
}

sub isAlphanumeric {
    my $self=shift;
    my $string=shift;
    my $Alphanumeric=
	$self->getLanguageData('character specifications','alphanumeric');
    if (not $Alphanumeric){return 0;}
    my $pattern="\[$Alphanumeric\]\+";
    return $string=~/^$pattern$/;
}

sub isNumeric {
    my $self=shift;
    my $string=shift;
    my $Numeric=
	$self->getLanguageData('character specifications','numeric');
    if (not $Numeric){return 0;}
    my $pattern="\[$Numeric\]\+";
    return $string=~/^$pattern$/;
}

sub isNumber {
    my $self=shift;
    my $string=shift;
    my $Digit=
	$self->getLanguageData('character specifications','digit');
    if (not $Digit){return 0;}
    my $pattern="\[$Digit\]\+";
    return $string=~/^$pattern$/;
}

sub isPunctuation {
    my $self=shift;
    my $string=shift;
    my $Punctuation=
	$self->getLanguageData('character specifications','punctuation');
    if (not $Punctuation){return 0;}
    my $pattern="\[$Punctuation\]\+";
    return $string=~/^$pattern$/;
}




sub isStringType{
    my $self=shift;
    my ($string,$type)=@_;
    if ($type eq 'all'){
	return 1;
    }
    my $CharacterSpec=$self->getLanguageData('character specifications');

    my $pattern;
    my $mod;
    if ($type=~/^not[\_\s](.*)$/){
	$mod='not';
	$type=$1;
    }
    if ($type=~/^contains[\_\s](.*)$/){
	$mod.='contains';
	$type=$1;
    }
    if (defined $$CharacterSpec{$type}){
	$pattern=$$CharacterSpec{$type};
	if (not $pattern){return 1;}
	if ($mod eq 'not'){
	    return $string!~/^[$pattern]+$/;
	}
	elsif ($mod eq 'contains'){
	    return $string=~/[$pattern]/;
	}
	elsif ($mod eq 'notcontains'){
	    return $string!~/[$pattern]/;
	}
	else{
	    return $string=~/^[$pattern]+$/;
	}
    }
    return 1;
}

sub grepStringType{
    my $self=shift;
    my ($list,$type)=@_;
    return grep ($self->isStringType($_,$type),@{$list});
}

sub grepStringTypeElements{
    my $self=shift;
    my ($list,$type)=@_;
    return grep ($self->IsStringType($$list[$_],$type),(0..$#{$list}));
}



sub isNonStarter{
    my $self=shift;
    my $token=shift;

    my $skip=$self->getLanguageData('phrases','non-phrase-starter hash');
    if (ref($skip) eq 'HASH'){
	if (exists $$skip{$token}){
	    return 1;
	}
    }
    my $skip=
	$self->getLanguageData('phrases','non-phrase-starter string type');
    if (ref($skip) eq 'ARRAY'){
	foreach (@{$skip}){
	    if (&IsStringType($token,$_)){
		return 1;
	    }
	}
    }
    return 0;
}

sub isNonEnder{
    my $self=shift;
    my $token=shift;

    my $skip=$self->getLanguageData('phrases','non-phrase-ender hash');
    if (ref($skip) eq 'HASH'){
	if (exists $$skip{$token}){
	    return 1;
	}
    }
    my $skip=$self->getLanguageData('phrases','non-phrase-ender string type');
    if (ref($skip) eq 'ARRAY'){
	foreach (@{$skip}){
	    if (&IsStringType($token,$_)){
		return 1;
	    }
	}
    }
    return 0;
}

sub skipToken{
    my $self=shift;
    my $token=shift;

    my $skip=$self->getLanguageData('phrases','skip token hash');
    if (ref($skip) eq 'HASH'){
	if (exists $$skip{$token}){
	    return 1;
	}
    }
    my $skip=$self->getLanguageData('phrases','skip token string type');
    if (ref($skip) eq 'ARRAY'){
	foreach (@{$skip}){
	    if ($self->isStringType($token,$_)){
		return 1;
	    }
	}
    }
    return 0;
}

sub skipPhraseAt{
    my $self=shift;
    my $token=shift;

    my $skip=$self->getLanguageData('phrases','skip phrase at hash');
    if (ref($skip) eq 'HASH'){
	if (exists $$skip{$token}){
	    return 1;
	}
    }
    my $skip=$self->getLanguageData('phrases','skip phrase at string type');
    if (ref($skip) eq 'ARRAY'){
	foreach (@{$skip}){
	    if ($self->isStringType($token,$_)){
#		print STDERR "skip at $_ type\n";
		return 1;
	    }
	}
    }
    return 0;
}


sub skipPhraseBefore{
    my $self=shift;
    my $token=shift;

    my $skip=$self->getLanguageData('phrases','skip phrase before hash');
    if (ref($skip) eq 'HASH'){
	if (exists $$skip{$token}){
	    return 1;
	}
    }
    my $skip=
	$self->getLanguageData('phrases','skip phrase before string type');
    if (ref($skip) eq 'ARRAY'){
	foreach (@{$skip}){
	    if ($self->isStringType($token,$_)){
		return 1;
	    }
	}
    }
    return 0;
}

sub skipPhraseAfter{
    my $self=shift;
    my $token=shift;

    my $skip=$self->getLanguageData('phrases','skip phrase after hash');
    if (ref($skip) eq 'HASH'){
	if (exists $$skip{$token}){
	    return 1;
	}
    }
    my $skip=$self->getLanguageData('phrases','skip phrase after string type');
    if (ref($skip) eq 'ARRAY'){
	foreach (@{$skip}){
	    if ($self->isStringType($token,$_)){
		return 1;
	    }
	}
    }
    return 0;
}




#-----------------------------------------------------------------------------
# auxiliary functions ....


sub ArrayToHash{
    my ($Array,$Hash)=@_;
    if (ref($Array) eq 'ARRAY'){
	foreach (@{$Array}){
	    $$Hash{$_}=1;
	}
    }
}


sub GetGeneralParam{
    my $Param=shift;
    if (defined $$Param{general}){
	if (ref($$Param{general}) eq 'HASH'){
	    return $$Param{general};
	}
    }
    return $Param;
}

sub GetNgramLengthParam{
    my $Param=shift;
    my $length=1;

    if (defined $$Param{'maximal ngram length'}){
	$length=$$Param{'maximal ngram length'};
    }
    foreach (keys %{$Param}){
	if (ref($$Param{$_}) ne 'HASH'){next;}
	if ($$Param{$_}{'maximal ngram length'}>$length){
	    $length=$$Param{$_}{'maximal ngram length'};
	}
    }
    return $length;
}

1;
