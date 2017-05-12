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
#####################################################################
# string similarity measures
#####################################################################


package Uplug::StrSim;

use vars qw(@ISA @EXPORT);
@ISA = qw( Exporter);
@EXPORT = qw( &similar );

#####################################################################
# GetNrSims
#####################################################################


sub GetNrSims
{
  return 4;
}

#####################################################################
# similar($src,$trg,$meth[,\%weights[,$splitpattern]])
#####################################################################
# returns string similarity score for ($src,$trg)
#   $meth specifies similarity metric
#   $norm specifies normalization of scores
#      0 -> no normalization
#      1 -> normalization by length of longer string
#      2 -> normalization by length of shorter string

sub similar
{
  my ($src,$trg,                         # source and target string
      $meth,                             # similarity measure
      $norm,                             # normalization
      $W,                                # weight function
      $pattern)=@_;                      # pattern for splitting into char's

  my ($score,$first,$last)=(0,0,0);
#  $src=&my_lc($src);                     # make lower case versions
#  $trg=&my_lc($trg);                     #   of source and target strings
  if (length($src)>length($trg)){        # source string should be the shorter
      ($src,$trg)=($trg,$src);           #   one -> swap if necessary
  }

#---------------------------------------------------------------------------
# now, call the sub-function for string similarity score calculation
#---------------------------------------------------------------------------

  if (($meth==2) or ($meth eq 'ord')) {
      ($score,$first,$last)=
	  &LCIFS($src,$trg,$W,$pattern);
  }
  elsif (($meth==4) or ($meth eq 'pos')) {
      ($score,$first,$last)=
	  &LNCCRP($src,$trg,$W,$pattern);
  }
  elsif (($meth==6) or ($meth eq 'best')) {
      ($score,$first,$last)=
	  &BestSimilar($src,$trg,$W,$pattern);
  }
  else {
      ($score,$first,$last)=              # LCSR is the default metric
	  &LCS($src,$trg,$W,$pattern);
  }

#---------------------------------------------------------------------------
# score normalization
#---------------------------------------------------------------------------

  if ($norm==1) {
	if (length($trg)>0) {$score/=(length($trg));}
  }
  if ($norm==2) {
	if (length($src)>0) {$score/=(length($src));}
  }
  if ((defined $first) and (defined $last)){
      return ($score,$first,$last);
  }
  return $score;
}


###########################################################################
# LCSR($src,$trg,[\%weights[,$SplitPattern[,\%trace[,$PrintMatrix]]]])
#--------------------------------------------------------------------------
# longest common sub-sequence ratio
#--------------------------------------------------------------------------
# $src          - source string
# $trg          - target string
# %weights      - weights for character pairs
# $SplitPattern - pattern for splitting strings into characters
# %trace        - trace of character matches
# $PrintMatrix  - ==1 -> print the LSCR matrix
###########################################################################

sub LCSR {

  my ($src,$trg,$W,$pattern,$trace,$printMatrix)=@_;
  my $score=&LCS($src,$trg,$W,$pattern,$trace,$printMatrix);
  if (length($src)>length($trg)){
      return $score/length($src);
  }
  if (length($trg)>0){
      return $score/length($trg);
  }
  return 0;
}

###########################################################################
# LCS($src,$trg,[\%weights[,$SplitPattern[,\%trace[,$PrintMatrix]]]])
#--------------------------------------------------------------------------
# longest common sub-sequence
###########################################################################

sub LCS {

  my ($src,$trg,$W,$pattern,$trace,$printMatrix)=@_;
  my (@l,$i,$j);
  my @src_let=split(/$pattern/,$src);		# split string into char
  my @trg_let=split(/$pattern/,$trg);
  unshift (@src_let,'');
  unshift (@trg_let,'');
  for ($i=0;$i<=$#src_let;$i++){                # initialize the matrix
      $l[$i][0]=0;
  }
  for ($i=0;$i<=$#trg_let;$i++){
      $l[0][$i]=0;
  }                                                       # weight function is
  if (defined $W){                                        # defined:
      for $i (1..$#src_let){                              #   if the pair
	  for $j (1..$#trg_let){                          #   ['.','.'] is 
	      if (($$W{'.'}{'.'}) and                     #   defined in %W:
		  (not $$W{$src_let[$i]}{$trg_let[$j]})){ #   -> count all
		  if ($src_let[$i] eq $trg_let[$j]){      #      identical 
		      $$W{$src_let[$i]}{$trg_let[$j]}=1;  #      matches with 
		  }                                       #      score=1 if the
	      }                                           #      pair is not
	      my $best;                                   #      included in %W
	      if ($$W{$src_let[$i]}{$trg_let[$j]}){
		  $best=$l[$i-1][$j-1]+$$W{$src_let[$i]}{$trg_let[$j]};
	      }
	      if ($l[$i][$j-1]>$best){
		  $best=$l[$i][$j-1];
	      }
	      if ($l[$i-1][$j]>$best){
		  $best=$l[$i-1][$j];
	      }
	      $l[$i][$j]=$best;
	  }
      }
  }
  else{
      for $i (1..$#src_let){
	  for $j (1..$#trg_let){
	      if ($src_let[$i] eq $trg_let[$j]){
		  $l[$i][$j]=$l[$i-1][$j-1]+1;
	      }
	      else{
		  if ($l[$i][$j-1]>$l[$i-1][$j]){
		      $l[$i][$j]=$l[$i][$j-1];
		  }
		  else{
		      $l[$i][$j]=$l[$i-1][$j];
		  }
	      }
	  }
      }
  }
  if (defined $trace){                           # save the trace of character
      $i=$#l;                                    # matches if %trace is defined
      $j=$#{$l[0]};
      while (($i>0) and ($j>0)){
	  if ($l[$i][$j]==$l[$i-1][$j]){
	      $$trace{$i}{$j}=$l[$i][$j]-$l[$i-1][$j];
	      $i-=1;
	  }
	  elsif($l[$i][$j]==$l[$i][$j-1]){
	      $$trace{$i}{$j}=$l[$i][$j]-$l[$i][$j-1];
	      $j-=1;
	  }
	  else{
	      $$trace{$i}{$j}=$l[$i][$j]-$l[$i-1][$j-1];
	      $i-=1;
	      $j-=1;
	  }
      }
  }
 
  if ($printMatrix){
      print '   ';
      foreach (0..$#src_let){
	  printf "%4s ", $src_let[$_];
      }
      print "\n";
      
      foreach (0..$#trg_let){
	  my $i;
	  printf "%3s ", $trg_let[$_];
	  foreach $i (0..$#src_let){
	      printf "%1.2f",$l[$i][$_];
	      print " ";
	  }
	  print "\n";
      }
  }

  return $l[$#src_let][$#trg_let];
}



#####################################################################
# GetNonMatches($src,$trg,\%NonMatchPairs)'
#--------------------------------------------------------------------
# get all non-matching pairs from two strings
#####################################################################

sub GetNonMatches{

    my ($src,$trg,$res)=@_;

    my %trace;
    my $score=&LCS($src,$trg,undef,'',\%trace);

    my @SRC=split(//,$src);
    my @TRG=split(//,$trg);

    my $i=1;
    my $j=1;

    my $x=1;
    my $y=1;
    my ($srcnot,$trgnot)=('','');

    my $matches='';
    my $nonmatches='';
    my $SrcNonMatch='';
    my $TrgNonMatch='';

    foreach $i (sort {$a <=> $b} keys %trace){
	foreach $j (sort {$a <=> $b} keys %{$trace{$i}}){
	    if ($trace{$i}{$j}){
		$matches.=$SRC[$i-1];
		while ($x<$i){
		    $srcnot.=$SRC[$x-1];
		    $x++;
		}
		while ($y<$j){
		    $trgnot.=$TRG[$y-1];
		    $y++;
		}
		$x++;
		$y++;
		if ($srcnot or $trgnot){
		    $$res{$srcnot}{$trgnot}++;
		    $SrcNonMatch.=$srcnot.'*';
		    $TrgNonMatch.=$trgnot.'*';
		    $nonmatches.='('.$srcnot.'|'.$trgnot.').*';
		}
		else{
		    if (not $nonmatches){
			$nonmatches='.*';
			$SrcNonMatch.='*';
			$TrgNonMatch.='*';
		    }
		}
		($srcnot,$trgnot)=('','');
	    }
	    else{
		if ($matches!~/\*$/){
		    $matches.='*';
		}
	    }
	}
    }
    while ($x<=@SRC){
	$srcnot.=$SRC[$x-1];
	$x++;
    }
    while ($y<=@TRG){
	$trgnot.=$TRG[$y-1];
	$y++;
    }
    if ($srcnot or $trgnot){
	$$res{$srcnot}{$trgnot}++;
#	$nonmatches.="\{'".$srcnot."' \=\> '".$trgnot."'\}\*";
	$nonmatches.='('.$srcnot.'|'.$trgnot.')';
	$SrcNonMatch.=$srcnot;
	$TrgNonMatch.=$trgnot;
    }
    return ($score,$nonmatches,$matches,
	    $SrcNonMatch,$TrgNonMatch);
}


#####################################################################
# GetNonMatches($src,$trg,\%NonMatchPairs)'
#--------------------------------------------------------------------
# get all non-matching pairs from two strings
#####################################################################

sub GetNonMatchesOld{

    my ($src,$trg,$res)=@_;

    my %trace;
    my $score=&LCS($src,$trg,undef,'',\%trace);

    my @SRC=split(//,$src);
    my @TRG=split(//,$trg);

    my $i=1;
    my $j=1;

    my $x=1;
    my $y=1;
    my ($srcnot,$trgnot)=('','');

    my $matches='';
    my $nonmatches='';

    foreach $i (sort {$a <=> $b} keys %trace){
	foreach $j (sort {$a <=> $b} keys %{$trace{$i}}){
	    if ($trace{$i}{$j}){
		$matches.=$SRC[$i];
		while ($x<$i){
		    $srcnot.=$SRC[$x-1];
		    $x++;
		}
		while ($y<$j){
		    $trgnot.=$TRG[$y-1];
		    $y++;
		}
		$x++;
		$y++;
		if ($srcnot or $trgnot){
		    $$res{$srcnot}{$trgnot}++;
		    $nonmatches.='('.$srcnot.'|'.$trgnot.').*';
		}
		else{
		    if (not $nonmatches){
			$nonmatches='.*';
		    }
		}
		($srcnot,$trgnot)=('','');
	    }
	    else{
		if ($matches!~/\*$/){
		    $matches.='*';
		}
	    }
	}
    }
    while ($x<=@SRC){
	$srcnot.=$SRC[$x-1];
	$x++;
    }
    while ($y<=@TRG){
	$trgnot.=$TRG[$y-1];
	$y++;
    }
    if ($srcnot or $trgnot){
	$$res{$srcnot}{$trgnot}++;
#	$nonmatches.="\{'".$srcnot."' \=\> '".$trgnot."'\}\*";
	$nonmatches.='('.$srcnot.'|'.$trgnot.')';
    }
    return ($score,$nonmatches,$matches);
}


#####################################################################
# LCIS($src,$trg)
#####################################################################
# longest common initial subsequence

sub LCIS
{
  my ($src,$trg,$W,$pattern)=@_;
  my ($i,$j,$score,$first,$last)=(0,0,0,0,0);
  if (length($src)>length($trg)) {($src,$trg)=($trg,$src);}
  @src_let=split(/$pattern/,$src);      # split words into single
  @trg_let=split(/$pattern/,$trg);	# letters
  while ($i<@src_let)			# until last letter is reached
  {
    if ($src_let[$i] eq $trg_let[$j])   # if same letters at
    {					# current positions
      $score++;                         # -> increment score and
      $i++;				# the position in the smaller word
      if (not $first) {$first=$j+1;}	# remember postition of the first
      $last=$j+1;			# and the last match
    }
    if ($j<@trg_let) {$j++;}		# increment the position in the
    else {last;}			# longer word, if not endposition
  }
  return ($score,$first,$last);		# return score, first and last
}

#####################################################################
# LCIFS($src,$trg)
#####################################################################
# max(longest common initial subsequence,
#     longest common final subsequence)

sub LCIFS
{
  my ($src,$trg,$W,$pattern)=@_;
  my ($i,$j,$score1,$first1,$last1)=(0,0,0,0,0);
  my ($score2,$first2,$last2)=(0,0,0);
  if (length($src)>length($trg)) {($src,$trg)=($trg,$src);}

  ($score1,$first1,$last1)=&LCIS($src,$trg);

  @src_let=split(/$pattern/,$src);      # split words into single
  @trg_let=split(/$pattern/,$trg);	# letters
  ($i,$j)=(@src_let-1,@trg_let-1);	# and now from the last character
  while ($i>=0)
  {
    if ($src_let[$i] eq $trg_let[$j])	# same as above
    {
      $score2++;
      $i--;				# but decrement positions
      if (not $last2) {$last2=$j+1;}	# remember postition of the last
      $first2=$j+1;			# and the first match
    }
    if ($j>0) {$j--;}
    else {last;};
  }

  if ($score1>=$score2){return ($score1,$first1,$last1);}
  return ($score2,$first2,$last2);
}

#####################################################################
# LNCCP($src,$trg)
#####################################################################
# largest number of common characters at same positions

sub LNCCP
{
  my ($src,$trg,$W,$pattern)=@_;
  my ($i,$score,$first,$last)=(0,0,0);
  if (length($src)>length($trg)) {($src,$trg)=($trg,$src);}
  @src_let=split(/$pattern/,$src);	# split words into single
  @trg_let=split(/$pattern/,$trg);      # letters
  for ($i=0;$i<@src_let;$i++)		# for every letter of the
  {					# string
    if ($src_let[$i] eq $trg_let[$i])	# if letters equal
    {                                   # at same positions
      	$score++;			# -> increment score
	if (not $first) {$first=$i+1;}
	$last=$i+1;
    }
  }
  return ($score,$first,$last);		# and return
}

#####################################################################
# LNCCRP($src,$trg)
#####################################################################
# largest number of common characters at same relativ positions

sub LNCCRP
{
  my ($src,$trg,$W,$pattern)=@_;

  my ($j,$i,$best,$score,$first,$last,$first_tmp,$last_tmp)=(0,0,0,0,0,0,0,0);
  if (length($src)>length($trg)) {($src,$trg)=($trg,$src);}

  @src_let=split(/$pattern/,$src);
  @trg_let=split(/$pattern/,$trg);
  for ($j=0-@src_let;$j<@trg_let;$j++){
      $score=0;
      $first_tmp=0;
      for ($i=0;$i<@src_let;$i++)
      {
	  if (($i+$j>=0) and ($i+$j<@trg_let)){
	      if ($src_let[$i] eq $trg_let[$i+$j])
	      {
		  $score++;
		  $last_tmp=$j+$i+1;
		  if (not $first_tmp){$first_tmp=$j+$i+1;}
	      }
	  }
      }
      if ($score>$best)
      {
	  $best=$score;
	  $first=$first_tmp;
	  $last=$last_tmp;
      }
  }
  return ($best,$first,$last);
}


#####################################################################
# BestSimilar($src,$trg)                                            #
#####################################################################
# calculate similarity scores with all available measures and
# return the highest for the current string pair

sub BestSimilar
{
  my ($src,$trg)=@_;
  my $sims=&GetNrSims;
  my ($i,$bestscore,$bestlast,$bestfirst)=(0,0,0,0);
  my ($score,$first,$last);
  for $i (0..$sims-2){                     # don't do BestSimilar again ...
      ($score,$first,$last)=similar($src,$trg,$i);
      if ($score>$bestscore){
	  $bestscore=$score;
	  $bestfirst=$first;
	  $bestlast=$last;
      }
  }
  return ($bestscore,$bestfirst,$bestlast);
}

#####################################################################
# CombScore(\@ScoreMatrix,\@ScoreComb,$meth)
#####################################################################
# scores[source][target]: score matrix
# $meth specifies algorithm
# @comb contains resulting score matrix

sub CombScore
{
  local (*scores,*comb,$meth)=@_;
  if (($meth==0)or($meth eq 'sub_s')) {&CombScore1(\@scores,\@comb);}
  if (($meth==1)or($meth eq 'sub_t')) {&CombScore2(\@scores,\@comb);}
  if (($meth==2)or($meth eq 'sub_l')) {&CombScore3(\@scores,\@comb);}
  if (($meth==3)or($meth eq 'sub_b')) {&CombScore4(\@scores,\@comb);}
  if (($meth==4)or($meth eq 'sub_s_sub_b')) {&CombScore5(\@scores,\@comb);}
  if (($meth==5)or($meth eq 'sub_t_sub_b')) {&CombScore6(\@scores,\@comb);}
  if (($meth==6)or($meth eq 'sub_l_sub_b')) {&CombScore7(\@scores,\@comb);}
}

#####################################################################
# score combination 1 (score-s)                                     #
#####################################################################

sub CombScore1{

    local (*scores,*comb)=@_;
    for $i (0..$#scores){
	for $j (0..$#{$scores[$i]}){
	    for $k (0..$#scores){
		if ($k==$i) {$comb[$i][$j]+=$scores[$k][$j];}
		else {$comb[$i][$j]-=$scores[$k][$j];}

	    }
	}
    }
}

#####################################################################
# score combination 2 (score-t)                                     #
#####################################################################

sub CombScore2{

    local (*scores,*comb)=@_;
    for $i (0..$#scores){
	for $j (0..$#{$scores[$i]}){
	    for $k (0..$#{$scores[$i]}){
		if ($k==$j) {$comb[$i][$j]+=$scores[$i][$k];}
		else {$comb[$i][$j]-=$scores[$i][$k];}

	    }
	}
    }
}

#####################################################################
# score combination 3 (score-l)                                     #
#####################################################################

sub CombScore3{
    local (*scores,*comb)=@_;
    if ($#scores>$#{$scores[0]}){CombScore2(\@scores,\@comb);}
    else{CombScore1(\@scores,\@comb);}
}


#####################################################################
# score combination 4 (lead_avr)                                    #
#####################################################################

sub CombScore4{

    local (*scores,*comb)=@_;
    for $i (0..$#scores){
	for $j (0..$#{$scores[$i]}){
	    my $best=-99999999;
	    my $bestpos=0;
	    for $k (0..$#scores){
		if ($k!=$i) {
		    if ($scores[$k][$j]>$best){
			$best=$scores[$k][$j];
			$bestpos=$k;
		    }
		}
	    }
	    $comb[$i][$j]=$scores[$i][$j]-$scores[$bestpos][$j];
	}
    }
}


#####################################################################
# score combination lead_avr-s                                      #
#####################################################################

sub CombScore5{
    local (*scores,*comb)=@_;
    my @tmparr;
    &CombScore1(\@scores,\@comb);
    &CombScore4(\@comb,\@tmparr);
    @comb=@tmparr;
}

#####################################################################
# score combination lead_avr-t                                      #
#####################################################################

sub CombScore6{
    local (*scores,*comb)=@_;
    my @tmparr;
    &CombScore2(\@scores,\@comb);
    &CombScore4(\@comb,\@tmparr);
    @comb=@tmparr;
}

#####################################################################
# score combination lead_avr-l                                      #
#####################################################################

sub CombScore7{
    local (*scores,*comb)=@_;
    my @tmparr;
    &CombScore3(\@scores,\@comb);
    &CombScore4(\@comb,\@tmparr);
    @comb=@tmparr;
}











1;

