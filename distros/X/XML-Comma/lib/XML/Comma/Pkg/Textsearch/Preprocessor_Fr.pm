##
#
#    Copyright 2001 AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Pkg::Textsearch::Preprocessor_Fr;
use XML::Comma::Pkg::Textsearch::Preprocessor;
use locale qw( fr );
use strict;

use XML::Comma::Util qw( dbg );

my %Preprocessor_Stopwords;
my $max_length = $XML::Comma::Pkg::Textsearch::Preprocessor::max_word_length;

# usage: @list_of_words = XML::Comma::Pkg::Textsearch::Preprocessor->stem($text)
sub stem {
  my %hash = $_[0]->stem_and_count($_[1]);
  return keys %hash;
}

# usage:
#   %hash = XML::Comma::Pkg::Textsearch::Preprocessor->stem_and_count($text)
#
sub stem_and_count {
  my %hash;
  # split and throw away stopwords
  my @words = map { lc } grep {
    ! defined $Preprocessor_Stopwords{$_}
  } grep { $_  and  $_ =~ m:\S: } split ( /\W+/, $_[1] );
  # stem each, adding every result that's under $max_length letters to our hash
  foreach ( snowball_stem(@words) ) {
    unless ( length($_) > $max_length ) {
      $hash{$_}++;
    }
  }
  return %hash;
}

# usage:
#   %hash = XML::Comma::Pkg::Textsearch::Preprocessor->is_stopword($word)
#
sub is_stopword {
  return defined $Preprocessor_Stopwords{$_[1]};
}

############
#
# DATA STRUCTURE - stopwords, suffix rule tables
#
############

BEGIN {
%Preprocessor_Stopwords = map { $_ => 1 }
  qw(

                    au              aux             avec
                    ce              ces             dans
                    de              des               du
                  elle               en               et
                   eux               il               je
                    la               le             leur
                   lui               ma             mais
                    me             même              mes
                   moi              mon               ne
                   nos            notre             nous
                    on               ou              par
                   pas             pour               qu
                   que              qui               sa
                    se              ses              son
                   sur               ta               te
                   tes              toi              ton
                    tu               un              une
                   vos            votre             vous
                     c                d                j
                     l                à                m
                     n                s                t
                     y              été             étée
                 étées             étés            étant
                étante           étants          étantes
                  suis               es              est
                sommes             êtes             sont
                 serai            seras             sera
                serons            serez           seront
                serais           serait          serions
                seriez         seraient            étais
                 était           étions            étiez
               étaient              fus              fut
                  ûmes             ûtes           furent
                  sois             soit           soyons
                 soyez           soient            fusse
                fusses              fût         fussions
               fussiez          fussent            ayant
                ayante          ayantes           ayants
                    eu              eue             eues
                   eus               ai               as
                 avons             avez              ont
                 aurai            auras             aura
                aurons            aurez           auront
                aurais           aurait          aurions
                auriez         auraient            avais
                 avait           avions            aviez
               avaient              eut            eûmes
                 eûtes           eurent              aie
                  aies              ait            ayons
                  ayez            aient            eusse
                eusses              eût         eussions
               eussiez          eussent

    );
}

my %step1_suffix_actions =
  (
   ance  => [ \&r2_del ],
   iqUe  => [ \&r2_del ],
   isme  => [ \&r2_del ],
   able  => [ \&r2_del ],
   iste  => [ \&r2_del ],
   eux   => [ \&r2_del ],
   ances => [ \&r2_del ],
   iqUes => [ \&r2_del ],
   ismes => [ \&r2_del ],
   ables => [ \&r2_del ],
   istes => [ \&r2_del ],

   atrice  => [ \&r2_del, \&r2_ic_del ],
   ateur   => [ \&r2_del, \&r2_ic_del ],
   ation   => [ \&r2_del, \&r2_ic_del ],
   atrices => [ \&r2_del, \&r2_ic_del ],
   ateurs  => [ \&r2_del, \&r2_ic_del ],
   ations  => [ \&r2_del, \&r2_ic_del ],

   logie  =>  [ \&r2_repl_log ],
   logies =>  [ \&r2_repl_log ],

   usion  =>  [ \&r2_repl_u ],
   ution  =>  [ \&r2_repl_u ],
   usions =>  [ \&r2_repl_u ],
   utions =>  [ \&r2_repl_u ],

   ence   =>  [ \&r2_repl_ent ],
   ences  =>  [ \&r2_repl_ent ],

   ement  =>  [ \&rv_del, \&handle_iv_eus_abl_etc ],
   ements =>  [ \&rv_del, \&handle_iv_eus_abl_etc ],

   'ité'  =>  [ \&r2_del, \&handle_abil_ic_iv ],
   'ités' =>  [ \&r2_del, \&handle_abil_ic_iv ],

   if    => [ \&r2_del, \&handle_at_ic_iqU ],
   ive   => [ \&r2_del, \&handle_at_ic_iqU ],
   ifs   => [ \&r2_del, \&handle_at_ic_iqU ],
   ives  => [ \&r2_del, \&handle_at_ic_iqU ],

   eaux  => [ \&eau_repl ],

   aux   => [ \&r1_al_repl ],

   euse  => [ \&handle_eux ],
   euses  => [ \&handle_eux ],

   issement  =>  [ \&r1_ifnonv_del ],
   issements =>  [ \&r1_ifnonv_del ],

   amment    =>  [ \&rv_repl_ant ],
   emment    =>  [ \&rv_repl_ent ],

   ment  =>  [ \&rv_ifvinrv_del ],
   ments =>  [ \&rv_ifvinrv_del ],
  );

my @step1_suffixes = sort { length($b) <=> length($a) }
  keys %step1_suffix_actions;

my @step2a_suffixes = sort { length($b) <=> length($a) }
  qw( îmes ît îtes
      i ie ies ir ira irai iraIent irais irait iras irent irez
      iriez irions irons iront is issaIent issais issait issant issante
      issantes issants isse issent isses issez issions issons it );

my %step2a_suffix_actions = map { $_ => [ \&r2a_rule ] } @step2a_suffixes;

my %step2b_suffix_actions =
  (
   'ions' => [ \&r2_del ],

   'é'        =>  [ \&del ],
   'ée'       =>  [ \&del ],
   'ées'      =>  [ \&del ],
   'és'       =>  [ \&del ],
   'èrent'    =>  [ \&del ],
   'er'       =>  [ \&del ],
   'era'      =>  [ \&del ],
   'erai'     =>  [ \&del ],
   'eraIent'  =>  [ \&del ],
   'erais'    =>  [ \&del ],
   'erait'    =>  [ \&del ],
   'eras'     =>  [ \&del ],
   'erez'     =>  [ \&del ],
   'eriez'    =>  [ \&del ],
   'erions'   =>  [ \&del ],
   'erons'    =>  [ \&del ],
   'eront'    =>  [ \&del ],
   'ez'       =>  [ \&del ],
   'iez'      =>  [ \&del ],

   'âmes'     =>  [ \&del, \&e_del ],
   'ât'       =>  [ \&del, \&e_del ],
   'âtes'     =>  [ \&del, \&e_del ],
   'a'        =>  [ \&del, \&e_del ],
   'ai'       =>  [ \&del, \&e_del ],
   'aIent'    =>  [ \&del, \&e_del ],
   'ais'      =>  [ \&del, \&e_del ],
   'ait'      =>  [ \&del, \&e_del ],
   'ant'      =>  [ \&del, \&e_del ],
   'ante'     =>  [ \&del, \&e_del ],
   'antes'    =>  [ \&del, \&e_del ],
   'ants'     =>  [ \&del, \&e_del ],
   'as'       =>  [ \&del, \&e_del ],
   'asse'     =>  [ \&del, \&e_del ],
   'assent'   =>  [ \&del, \&e_del ],
   'asses'    =>  [ \&del, \&e_del ],
   'assiez'   =>  [ \&del, \&e_del ],
   'assions'  =>  [ \&del, \&e_del ],
  );

my @step2b_suffixes = sort { length($b) <=> length($a) }
  keys %step2b_suffix_actions;

my %step4_suffix_actions =
  (
   ion => [ \&r2_rv_s_or_t_del ],

   ier     =>  [ \&i_repl ],
   'ière'  =>  [ \&i_repl ],
   Ier     =>  [ \&i_repl ],
   'Ière'  =>  [ \&i_repl ],

   e   => [ \&del ],
   'ë' => [ \&rv_gu_del ]
  );

my @step4_suffixes = sort { length($b) <=> length($a) }
  keys %step4_suffix_actions;


############
#
# ALGORITHM
#
############

# globals for actual stemming loop -- bad lazy programmer, bad
my ( $return_flag, $word, $suffix, $pos, $rV, $r1, $r2 );

sub snowball_stem {
  my @words;
  foreach my $w ( @_ ) {
    $word = $w;
    prelude();
    # step 1
    $return_flag = 0;
    step_1();
    unless ( $return_flag ) {
      step_2();
    }
    if ( $return_flag ) {
      step_3();
    } else {
      step_4();
    }
    step_5();
    step_6();
    postlude();
    push @words, $word;
  }
  return @words;
}


##
# sub for each "step"
##

sub prelude {
  # first, munge the word a little. we need to marke a few letters
  # that are normally vowels as non-vowels. there are three rules,
  # here (with five regexp applications): 1) y preceded OR followed by
  # a vowel; 2) u after q; 3) u or i between two vowels. NOTE: the
  # order of application here matters -- the snowball code handles
  # this a bit differently, but these regexps pass all the tests.

  $word =~ s|([aeiouyâàëéêèïîôûù])y|$1Y|g  or
    $word =~ s|y([aeiouyâàëéêèïîôûù])|Y$1|g;
  $word =~ s|qu|qU|g;
  $word =~ s|([aeiouyâàëéêèïîôûù])u([aeiouyâàëéêèïîôûù])|$1U$2|g;
  $word =~ s|([aeiouyâàëéêèïîôûù])i([aeiouyâàëéêèïîôûù])|$1I$2|g;

  # find RV region
  if ( $word =~ m|^[aeiouyâàëéêèïîôûù][aeiouyâàëéêèïîôûù]| ) {
    # if first word starts with two vowels, RV is region after third letter
    $rV = 3;
  } else {
    # otherwise, RV is the region after the first vowel not at the
    # beginning of the word, or the end of the word if no such
    # position can be found
    if ( $word =~
         m|(^[aeiouyâàëéêèïîôûù]?[^aeiouyâàëéêèïîôûù]*[aeiouyâàëéêèïîôûù])| ) {
      $rV = length ( $1 );
    } else {
      $rV = length ( $word );
    }
  }
  # find R1: the region after the first non-vowel following a vowel
  # (or the end of the word, if there is no such non-vowel)
  if ( $word =~
       m|(^(.*?)[aeiouyâàëéêèïîôûù][^aeiouyâàëéêèïîôûù])| ) {
    $r1 = length ( $1 );
  } else {
    $r1 = length ( $word );
  }
  # find R2: the region after the first non-vowel following a vowel in
  # R1 (or the end of the word, if there is no such non-vowel)
  if ( $word =~
       m|(^.{$r1}(.*?)[aeiouyâàëéêèïîôûù][^aeiouyâàëéêèïîôûù])| ) {
    $r2 = length ( $1 );
  } else {
    $r2 = length ( $word );
  }
}

sub step_1 {
  dispatch_on_longest ( \@step1_suffixes, \%step1_suffix_actions, undef );
}

sub step_2 {
  $return_flag = 0;
  dispatch_on_longest
    ( \@step2a_suffixes, \%step2a_suffix_actions, $rV );
  unless ( $return_flag ) {
    dispatch_on_longest
      ( \@step2b_suffixes, \%step2b_suffix_actions, $rV );
  }
}

sub step_3 {
  $word =~ s|Y$|i|  or  $word =~ s|ç$|c|;
}

sub step_4 {
  if ( $word =~ m|[^aiouès]s$| ) {
    chop $word;
  }
  dispatch_on_longest ( \@step4_suffixes, \%step4_suffix_actions, $rV );
}

sub step_5 {
  # un-double
  if ( $word =~ m:(enn|onn|ett|ell|eill)$: ) {
    chop $word;
  }
}

sub step_6 {
  # un-accent
  $word =~ s:[éè]([^aeiouyâàëéêèïîôûù]+)$:e$1:;
}

sub postlude {
  # unmark pseudo-non-vowels
  $word =~ s/I/i/g;
  $word =~ s/U/u/g;
  $word =~ s/Y/y/g;
}


##
# utility subs
##

sub dispatch_on_longest {
  my ( $suffixes_list, $actions_table, $region ) = @_;
  foreach ( @$suffixes_list ) {
    $suffix = $_;
    if ( suffix_match($suffix, $region) ) {
      foreach my $action ( @{$actions_table->{$suffix}} ) {
        $action->();
      }
      return;
    }
  }
}



sub suffix_match {
  my $lsuffix = shift || $suffix;
  my $rX =     shift  || 0;
  $pos = rindex ( $word, $lsuffix);
  return  (($pos >= $rX)  and  (length($word) == $pos + length($lsuffix)));
}

sub suffix_replac {
  my $lsuffix = shift || $suffix;
  my $rX =      shift || 0;
  my $repl    = shift || '';
  if ( suffix_match($lsuffix, $rX) ) {
    substr $word, length($word)-length($lsuffix), length($lsuffix), $repl;
    return 1;
  } else {
    return 0;
  }
}

sub preceded_by {
  my ( $regexp, $rlength, $region ) = @_;
  my $pre_pos = $pos - $rlength;
  return ( $pre_pos >= ($region||0)  and
           substr($word,$pre_pos,$rlength) =~ m:$regexp: );
}

##
# rule subs
##

sub r2a_rule {
  if ( preceded_by("[^aeiouyâàëéêèïîôûù]", 1, $rV) ) {
    $word =~ s/$suffix$//;
    $return_flag++;
  }
}

sub del {
#  print "del: $word ($suffix) -- > ";
  suffix_replac();
  $return_flag++;
#  print "$word\n";
}

sub e_del {
  suffix_replac('e',$rV)  and  $return_flag++;
}

sub r1_ifnonv_del {
  if ( $pos >= $r1  and  preceded_by("[^aeiouyâàëéêèïîôûù]", 1) ) {
    suffix_replac();
    $return_flag++;
  }
}

sub rv_del {
  suffix_replac( $suffix, $rV)  and  $return_flag++;
}

sub handle_iv_eus_abl_etc {
  suffix_replac ( 'iv', $r2 )         && suffix_replac ( 'at', $r2 ) && return;
  suffix_replac ( 'eus', $r2 )        && return;
  suffix_replac ( 'eus', $r1, 'eux' ) && return;
  suffix_replac ( 'abl', $r2 )        && return;
  suffix_replac ('iqU', $r2 )         && return;
  suffix_replac ('ièr', $rV, 'i')     && return;
  suffix_replac ('Ièr', $rV, 'i')     && return;
}

sub r2_repl_u {
  suffix_replac ( $suffix, $r2, 'u' ) && $return_flag++;
}

sub r2_del {
  suffix_replac ( $suffix, $r2 ) && $return_flag++;
}

sub r2_ic_del {
  suffix_replac ( 'ic', $r2 ) && return;
  $word =~ s/ic$/iqU/;
}

# don't set return flag for these two
sub rv_repl_ant {
  suffix_replac ( $suffix, $rV, 'ant' );
}
sub rv_repl_ent {
  suffix_replac ( $suffix, $rV, 'ent' );
}

sub handle_abil_ic_iv {
  suffix_replac ( 'abil', $r2 )  &&  return;
  suffix_replac ( 'abil', undef, 'abl' )  &&  return;
  suffix_replac ( 'ic', $r2 )  &&  return;
  suffix_replac ( 'ic', undef, 'iqu' )  &&  return;
  suffix_replac ( 'iv', $r2 )  &&  return;
}

sub r2_repl_ent {
  suffix_replac ( $suffix, $r2, 'ent' )  and  $return_flag++;
}

# don't set return flag on this one
sub rv_ifvinrv_del {
  if ( preceded_by('[aeiouyâàëéêèïîôûù]',1,$rV) ) {
    suffix_replac();
  }
}


sub r2_rv_s_or_t_del {
  if ( $pos >= $r2  and  preceded_by('[st]',1,$rV) ) {
    suffix_replac('ion');
  }
}

sub handle_at_ic_iqU {
  suffix_replac('at', $r2)  and
    ( suffix_replac('ic', $r2)  or  suffix_replac('ic', undef, 'iqU') );
}

sub handle_eux {
  suffix_replac ( $suffix, $r2 )  and  $return_flag++  and  return;
  suffix_replac ( $suffix, $r1, 'eux' )  and  $return_flag++  and  return;
}

sub eau_repl {
  suffix_replac ( $suffix, undef, 'eau' );
  $return_flag++;
}

sub rv_gu_del {
  $word =~ s/gu$suffix$/gu/;
}

sub r1_al_repl {
  suffix_replac ( $suffix, $r1, 'al' )  and  $return_flag++;
}

sub r2_repl_log {
  suffix_replac ( $suffix, $r2, 'log' )  and  $return_flag++;
}

sub i_repl {
  suffix_replac ( $suffix, undef, 'i' );
}




1;
