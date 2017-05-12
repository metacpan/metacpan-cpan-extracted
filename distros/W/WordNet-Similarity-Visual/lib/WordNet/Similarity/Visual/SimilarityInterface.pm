package WordNet::Similarity::Visual::SimilarityInterface;

=head1 NAME

WordNet::Similarity::Visual::SimilarityInterface

=head1 SYNOPSIS

=head2 Basic Usage Example

  use WordNet::Similarity::Visual::SimilarityInterface;

  my $similarity = WordNet::Similarity::Visual::SimilarityInterface->new;

  $similarity->initialize;

  my ($result,$errors,$traces) = $similarity->compute_similarity($word1,$word2,$measure_index);

=head1 DESCRIPTION

This package provides an interface to WordNet::Similarity. It also converts the
trace string to the meta-language.

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=cut

use 5.008004;
use strict;
use warnings;
our $VERSION = '0.07';
use Gtk2 '-init';
use Gnome2;
use WordNet::QueryData;
use WordNet::Similarity;
use WordNet::Similarity::path;
use WordNet::Similarity::hso;
use WordNet::Similarity::lesk;
use WordNet::Similarity::lin;
use WordNet::Similarity::random;
use WordNet::Similarity::wup;
use WordNet::Similarity::jcn;
use WordNet::Similarity::res;
use WordNet::Similarity::vector_pairs;
use WordNet::Similarity::lch;
use constant TRUE  => 1;
use constant FALSE => 0;
my $STOPPED;
my %measure;
my $wn;
use constant CONFIG => $ENV{ HOME }."/.wordnet-similarity";

=item  $obj->new

The constructor for WordNet::Similarity::Visual::SimilarityInterface objects.

Return value: the new blessed object

=cut

sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

=item  $obj->initialize

To initialize WordNet::Similarity.

Return Value: None

=cut

sub initialize
{
  my ($self) = @_;
  $self->{ wn } = WordNet::QueryData->new;
  $self->{ measure }{"path"} = WordNet::Similarity::path->new($self->{ wn },CONFIG."/config-path.conf");
  $self->{ measure }{"hso"} = WordNet::Similarity::hso->new($self->{ wn },CONFIG."/config-hso.conf");
  $self->{ measure }{"lesk"} = WordNet::Similarity::lesk->new($self->{ wn });
  $self->{ measure }{"lin"} = WordNet::Similarity::lin->new($self->{ wn });
  $self->{ measure }{"random"} = WordNet::Similarity::random->new($self->{ wn });
  $self->{ measure }{"wup"} = WordNet::Similarity::wup->new($self->{ wn },CONFIG."/config-wup.conf");
  $self->{ measure }{"jcn"} = WordNet::Similarity::jcn->new($self->{ wn });
  $self->{ measure }{"res"} = WordNet::Similarity::res->new($self->{ wn });
  $self->{ measure }{"vector_pairs"} = WordNet::Similarity::vector_pairs->new($self->{ wn });
  $self->{ measure }{"lch"} = WordNet::Similarity::lch->new($self->{ wn },CONFIG."/config-lch.conf");
}


=item  $obj->compute_similarity

Computes the similarity and relatedness scores for two words.

Parameter: Two Words and the Measure Index
"hso","lch","lesk","lin","jcn","path","random","res","vector_pairs","wup"
The measure index can have any of the following values
  - 0 for "all measures"

  - 1 for "Hirst & St-Onge"

  - 2 for "Leacock and Chodorow"

  - 3 for "Adapted Lesk"

  - 4 for "Lin"

  - 5 for "Jiang & Conrath"

  - 6 for "Path Length"

  - 7 for "Random"

  - 8 for "Resnik"

  - 9 for "Vector Pair"

  - 10 for "Wu and Palmer"

Returns: Reference to Hashes containining

  - semantic relatedness/similarity values for all the word senses combination and measures,
  - errorStrings for the word senses and measure which did not return a similarity value
  - TraceString for all the measures that had trace output on

=over

=back

=cut

sub compute_similarity
{
  my ($self,$word1, $word2, $measure_index) = @_;
  my @allmeasures = ("hso","lch","lesk","lin","jcn","path","random","res","vector_pairs","wup");
  my @word1senses=[];
  my @word2senses=[];
  if ($self->{ STOPPED }==0)
  {
     @word1senses = $self->find_allsenses($word1);
  }
  if($self->{ STOPPED }==0)
  {
    @word2senses = $self->find_allsenses($word2);
  }
  my $measurename = $allmeasures[$measure_index-1];
  my $word1sense;
  my $word2sense;
  my %values=();
  my %errors=();
  my %measure=();
  my %traces=();
  my $module;
  my $value;
  foreach $word1sense (@word1senses)
  {
    while (Gtk2->events_pending)
    {
      Gtk2->main_iteration;
    }
    foreach $word2sense (@word2senses)
    {
      while (Gtk2->events_pending)
      {
        Gtk2->main_iteration;
      }
      if($self->{ STOPPED }==0)
      {
        if($measure_index != 0)
        {
          if($self->{ STOPPED } == 0)
          {
            $value=$self->{ measure }{$allmeasures[$measure_index-1]}->getRelatedness($word1sense,$word2sense);
            my ($error, $errorString) = $self->{ measure }{$allmeasures[$measure_index-1]}->getError();
            if($error)
            {
              $values{$word1sense}{$word2sense}=-1;
              $errors{$word1sense}{$word2sense}=$errorString;
            }
            else
            {
              $values{$word1sense}{$word2sense}=$value;
              $traces{$word1sense}{$word2sense}{$allmeasures[$measure_index-1]}=$self->{ measure }{$allmeasures[$measure_index-1]}->getTraceString;
            }
          }
        }
        else
        {
          foreach $module (@allmeasures)
          {
            if($self->{ STOPPED } == 0)
            {
              $value=$self->{ measure }{$module}->getRelatedness($word1sense,$word2sense);
              my ($error, $errorString) = $self->{ measure }{$module}->getError();
              if($error)
              {
                $values{$word1sense}{$word2sense}{$module}=-1;
                $errors{$word1sense}{$word2sense}{$module}=$errorString;
              }
              else
              {
                $values{$word1sense}{$word2sense}{$module}=$value;
                $traces{$word1sense}{$word2sense}{$module}=$self->{ measure }{$module}->getTraceString;
              }
            }
          }
        }
      }
    }
  }
  return (\%values, \%errors,\%traces);
}







sub find_allsenses
{
  my ($self, $word)=@_;
  my @temp = split '#',$word;
  my $wordlevel = $#temp+1;
  my $pos;
  my @wordsenses = ();
  my @wordsense;
  if($wordlevel==1)
  {
    @temp=$self->{ wn }->queryWord($word);
    foreach $pos (@temp)
    {
      @wordsense=$self->{ wn }->queryWord($pos);
      push (@wordsenses, @wordsense);
      @wordsense = ();
    }
  }
  elsif($wordlevel==2)
  {
    @wordsenses = $self->{ wn }->queryWord($word);
  }
  else
  {
    $wordsenses[0]=$word
  }
  return @wordsenses;
}


=item  $obj->convert_to_meta

Converts the Trace String to Meta-language.

Parameter: The two Word senses, Trace String and the Measure name

Returns: A String, the equivalent metalanguage for the trace string.

=over

=cut


sub convert_to_meta
{
  my ($self,$word1, $word2, $tracestring, $measure) = @_;
  my @trace= split "\n", $tracestring;
  my $length = $#trace;
  my $i;
  my %uniquepaths;
  my $path;
  my $w2tree;
  my @synsets = ();
  my $synset;
  my %lcs_path;
  my %tree;
  my $wtree;
  my $alt_path;
  my %alt_paths;
  my %allpaths;
  my $maxdepth=0;
  my $trace_return;
  if($measure =~ /path/)
  {
    my @paths = grep /Shortest path/, @trace;
    my @pathlengths = grep /Path length/, @trace;
    my @hypertrees = grep /HyperTree/, @trace;
    my $pathlength = $pathlengths[0];
    foreach $i (0...$#hypertrees)
    {
      if (length($hypertrees[$i])>$maxdepth)
      {
        $maxdepth = length($hypertrees[$i]);
      }
      $hypertrees[$i]=~ s/\*Root\*/Root/;
      $hypertrees[$i]=~ s/HyperTree: //;
    }
    foreach $path (@paths)
    {
      $path=~ s/\*Root\*/Root/;
      $path =~ s/Shortest path: //;
      if(length($path)>0)
      {
        $uniquepaths{$path}=1;
        $allpaths{$path}=1;
      }
    }
    my @syns1;
    my @syns2;
    my $syn;
    my $all_lcs="";
    my @word1tree;
    @syns1 = $self->{ wn }->querySense($word1,"syns");
    foreach $syn (@syns1)
    {
      push @word1tree, grep(/\b$syn\b/, @hypertrees);
    }
    my @word2tree;
    @syns2 = $self->{ wn }->querySense($word2,"syns");
    foreach $syn (@syns2)
    {
      push @word2tree, grep(/\b$syn\b/, @hypertrees);
    }
    if($#word2tree == $#hypertrees)
    {
      @word2tree = ();
      foreach $syn (@syns1)
      {
        push @word2tree, grep(!/\b$syn\b/, @hypertrees);
      }
    }
    if($#word1tree == $#hypertrees)
    {
      @word1tree = ();
      foreach $syn (@syns2)
      {
        push @word1tree, grep(!/\b$syn\b/, @hypertrees);
      }
    }
    @pathlengths = ();
    @trace=();
    foreach $path (keys %uniquepaths)
    {
      @synsets=split " ", $path;
      PATH: foreach $w2tree (@word2tree)
      {
        foreach $synset (@synsets)
        {
          if($w2tree=~/$synset/)
          {
            $lcs_path{$path}{$synset}=1;
            if(length($all_lcs) > 0)
            {
              $all_lcs = $synset." ".$all_lcs;
            }
            else
            {
              $all_lcs = $synset
            }
            last PATH;
          }
        }
      }
    }
    my %lcs_root_paths = ();
    my $lcs_root;
    foreach $path (@hypertrees)
    {
      $lcs_root='';
      @synsets=split " ", $path;
      foreach $synset (@synsets)
      {
        if(length($lcs_root)!=0 )
        {
          $lcs_root=$synset." hypernym ".$lcs_root;
        }
        else
        {
          $lcs_root = $synset;
        }
        if($all_lcs=~/$synset/)
        {
          last;
        }
      }
      $lcs_root_paths{$lcs_root}++;
      $allpaths{$lcs_root}=1;
      $alt_paths{$lcs_root}=1;
    }
    my %w2_paths=();
    my $w2_path;
    foreach $path (keys %uniquepaths)
    {
      $w2_path='';
      @synsets=split " ", $path;
      foreach $synset (reverse @synsets)
      {
        if(length($w2_path)!=0 )
        {
          $w2_path=$w2_path." hypernym ".$synset;
        }
        else
        {
          $w2_path = $synset;
        }
        if(exists $lcs_path{$path}{$synset})
        {
          last;
        }
      }
      $w2_paths{$w2_path}++;
    }
    my %w1_paths=();
    my $w1_path;
    foreach $path (keys %uniquepaths)
    {
      $w1_path='';
      @synsets=split " ", $path;
      foreach $synset (@synsets)
      {
        if(length($w1_path)!=0 )
        {
          $w1_path=$w1_path." hypernym ".$synset;
        }
        else
        {
          $w1_path = $synset;
        }
        if(exists $lcs_path{$path}{$synset})
        {
          $all_lcs = $synset;
          last;
        }
      }
      $w1_paths{$w1_path}++;
    }
#     my $flag=1;
#     my $flag2=0;
#     foreach $wtree (@hypertrees)
#     {
#       @synsets = split " ", $wtree;
#       foreach $i (reverse 0...$#synsets)
#       {
#         $flag=1;
#         foreach $path (keys %allpaths)
#         {
#           if($path=~/\b$synsets[$i]\b/)
#           {
#             $flag=0;
#             last;
#           }
#         }
#         if ($flag==1)
#         {
#           if($flag2==1)
#           {
#             $alt_path=$alt_path." hypernym ".$synsets[$i];
#           }
#           else
#           {
#             $flag2=1;
#             $alt_path = $synsets[$i+1]." hypernym ".$synsets[$i];
#           }
#         }
#         elsif($flag2==1)
#         {
#           $flag2=0;
#           $alt_path=$alt_path." hypernym ".$synsets[$i];
#           $alt_paths{$alt_path}=1;
#           $allpaths{$alt_path}=1;
#           $alt_path='';
#         }
#       }
#       if($flag2==1)
#       {
#         $flag2=0;
#         $alt_paths{$alt_path}=1;
#         $allpaths{$alt_path}=1;
#         $alt_path='';
#       }
#     }
    my $key;
    $trace_return=$measure."\n";
    my $j=0;
    foreach $key (keys %w1_paths)
    {
      if($j==0)
      {
        $trace_return=$trace_return.$key;
      }
      else
      {
        $trace_return=$trace_return." OR ".$key;
      }
      $j++;
    }
    $trace_return=$trace_return."\n";
    $j=0;
    foreach $key (keys %w2_paths)
    {
      if($j==0)
      {
        $trace_return=$trace_return.$key;
      }
      else
      {
        $trace_return=$trace_return." OR ".$key;
      }
      $j++;
    }
    $trace_return=$trace_return."\n";
    foreach $key (keys %alt_paths)
    {
      if($key =~ /$all_lcs/)
      {
        $trace_return=$trace_return.$key."\n";
      }
    }
    $trace_return=$trace_return."Max Depth = ".$maxdepth."\n";
    $trace_return=$trace_return.$pathlength."\n";
  }
  elsif($measure=~/wup/)
  {
    my @depth = grep /Depth/, @trace;
    my @word1_depth;
    my $syn;
    my @syns1;
    my @syns2;
    @syns1 = $self->{ wn }->querySense($word1,"syns");
    foreach $syn (@syns1)
    {
      push @word1_depth, grep /$syn/, @depth;
    }
    my @word2_depth;
    @syns2 = $self->{ wn }->querySense($word2,"syns");
    foreach $syn (@syns2)
    {
      push @word2_depth, grep /$syn/, @depth;
    }
    my @lcs_depth = grep /Lowest\sCommon\sSubsumers/, @depth;
    my @hypertrees = grep /HyperTree/, @trace;
    foreach $i (0...$#hypertrees)
    {
      if (length($hypertrees[$i])>$maxdepth)
      {
        $maxdepth = length($hypertrees[$i]);
      }
      $hypertrees[$i]=~ s/\*Root\*/Root/;
      $hypertrees[$i]=~ s/HyperTree: //;
    }
    my $w_tree;
    my $tree;
    my %trace_trees;
    foreach $w_tree (@hypertrees)
    {
      $tree='';
      @synsets=split " ", $w_tree;
      foreach $synset (reverse @synsets)
      {
        if(length($tree)!=0 )
        {
          $tree=$tree." hypernym ".$synset;
        }
        else
        {
          $tree = $synset;
        }
      }
      $trace_trees{$tree}++;
    }
    my $lcs = $lcs_depth[0];
    my $key;
    my $temptree = join " ", @hypertrees;
    $lcs =~ s/Lowest\sCommon\sSubsumers:\s//;
    $lcs =~ s/\*Root\*/Root/;
    $lcs =~ s/\s\(Depth=\d\)//;
    my $depth_word1;
    my $depth_word2;
    my @temp;
    if($#word1_depth>0)
    {
      @temp = split /=/,$word1_depth[0];
      $depth_word1 = $word1." = ".$temp[1];
    }
    else
    {
      foreach $syn (@syns1)
      {
        if($temptree =~ /$syn/)
        {
          $depth_word1=$syn;
          last;
        }
      }
    }
    if($#word2_depth>0)
    {
      @temp = split /=/,$word2_depth[0];
      $depth_word2 = $word2." = ".$temp[1];
    }
    else
    {
      foreach $syn (@syns2)
      {
        if($temptree=~/$syn/)
        {
          $depth_word2=$syn;
          last;
        }
      }
    }
    @temp = split /=/,$lcs_depth[0];
    $temp[1] =~ s/\)//;
    $lcs = $lcs." = ".$temp[1];
    $trace_return = $measure."\n";
    foreach $key (keys %trace_trees)
    {
      $trace_return=$trace_return.$key."\n";
    }
    $trace_return=$trace_return.$depth_word1."\n";
    $trace_return=$trace_return.$depth_word2."\n";
    $trace_return=$trace_return.$lcs;
  }
  elsif($measure=~/lch/)
  {
    @trace = split /Lowest\sCommon\sSubsumer\(s\):\s/, $tracestring;
    my @hypertrees = split /\n/, $trace[0];
    my @lcs_temp = split /\n/, $trace[1];
    my $key;
    my @lcs_split;
    my %lcs;
    foreach $key (@lcs_temp)
    {
      @lcs_split = split " ",$key;
      $lcs{$lcs_split[0]}=1;
    }
    foreach $i (0...$#hypertrees)
    {
      if (length($hypertrees[$i])>$maxdepth)
      {
        $maxdepth = length($hypertrees[$i]);
      }
      $hypertrees[$i]=~ s/\*Root\*/Root/;
      $hypertrees[$i]=~ s/HyperTree: //;
    }
    my @syns1;
    my @syns2;
    my $syn;
    my @word1tree;
    @syns1 = $self->{ wn }->querySense($word1,"syns");
    foreach $syn (@syns1)
    {
      push @word1tree, grep(/\b$syn\b/, @hypertrees);
    }
    my @word2tree;
    @syns2 = $self->{ wn }->querySense($word2,"syns");
    foreach $syn (@syns2)
    {
      push @word2tree, grep(/\b$syn\b/, @hypertrees);
    }
    if($#word1tree == $#hypertrees)
    {
      @word1tree = ();
      foreach $syn (@syns1)
      {
        push @word1tree, grep(!/\b$syn\b/, @hypertrees);
      }
    }
    if($#word2tree == $#hypertrees)
    {
      @word2tree = ();
      foreach $syn (@syns2)
      {
        push @word2tree, grep(!/\b$syn\b/, @hypertrees);
      }
    }
    my %w1_paths=();
    my $w1_path;
    my $j=0;
    my $all_lcs="";
    foreach $path (@word1tree)
    {
      $w1_path='';
      $j=0;
      @synsets=split " ", $path;
      foreach $synset (reverse @synsets)
      {
        $j++;
        if(length($w1_path)!=0 )
        {
          $w1_path=$w1_path." hypernym ".$synset;
        }
        else
        {
          $w1_path = $synset;
        }
        if(exists $lcs{$synset})
        {
          $all_lcs=$synset;
          last;
        }
      }
      if (length($all_lcs)>0)
      {
        $w1_paths{$all_lcs}{$w1_path}=$j;
      }
      else
      {
        $w1_paths{"Root#n#1"}{$w1_path}=$j;
      }
    }
    my %w2_paths=();
    my $w2_path;
    $j=0;
    foreach $path (@word2tree)
    {
      $w2_path='';
      $j=0;
      @synsets=split " ", $path;
      foreach $synset (reverse @synsets)
      {
        $j++;
        if(length($w2_path)!=0 )
        {
          $w2_path=$w2_path." hypernym ".$synset;
        }
        else
        {
          $w2_path = $synset;
        }
        if(exists $lcs{$synset})
        {
          $all_lcs=$synset;
          last;
        }
      }
      if (length($all_lcs)>0)
      {
        $w2_paths{$all_lcs}{$w2_path}=$j;
      }
      else
      {
        $w2_paths{"Root#n#1"}{$w2_path}=$j;
      }
    }
    my $lcs_synset;
    my $length = 100;
    foreach $lcs_synset (keys %w1_paths)
    {
      foreach $w1_path (keys %{$w1_paths{$lcs_synset}})
      {
        foreach $w2_path (keys %{$w2_paths{$lcs_synset}})
        {
          if($length > $w1_paths{$lcs_synset}{$w1_path}+$w2_paths{$lcs_synset}{$w2_path})
          {
            $path = $w1_path."\n".$w2_path;
            $length = $w1_paths{$lcs_synset}{$w1_path}+$w2_paths{$lcs_synset}{$w2_path};
          }
          elsif($length == $w1_paths{$lcs_synset}{$w1_path}+$w2_paths{$lcs_synset}{$w2_path})
          {
            $path = $path."\n".$w1_path."\n".$w2_path;
          }
        }
      }
    }

#     my $length = 100;
#     foreach $w1_path (keys %w1_paths)
#     {
#       foreach $w2_path (keys %w2_paths)
#       {
#         if($length > $w1_paths{$w1_path}+$w2_paths{$w2_path})
#         {
#           $path = $w1_path."\n".$w2_path;
#           $length = $w1_paths{$w1_path}+$w2_paths{$w2_path};
#         }
#         elsif($length == $w1_paths{$w1_path}+$w2_paths{$w2_path})
#         {
#           $path = $path."\n".$w1_path."\n".$w2_path;
#         }
#       }
#     }
    $trace_return = $measure."\n";
    $length--;
    $trace_return = $trace_return.$path."\n".$length;
    return $trace_return;
  }
  elsif ($measure =~ /hso/)
  {
    my $trace_return = "hso";
    if( $tracestring =~ /MedStrong\srelation\spath\.\.\./)
    {
      $tracestring =~ s/\n//g;
      @trace = split /MedStrong\srelation\spath\.\.\./, $tracestring;
      my @path;
      foreach $i(1...$#trace)
      {
        chomp $trace[$i];
        $path[$i-1] = $trace[$i];
        $path[$i-1] =~ s/\[U\]/hyponym/g;
        $path[$i-1] =~ s/\[D\]/hypernym/g;
        $path[$i-1] =~ s/\[H\]/merynym/g;
        $trace_return = $trace_return."\n".$path[$i-1];
      }
    }
    elsif($tracestring=~/Strong\sRel\s\(Synset\sMatch\)/)
    {
      $tracestring =~ s/\n//g;
      @trace = split /Strong\sRel\s\(Synset\sMatch\)\s:\s/, $tracestring;
      $trace_return = $trace_return."\n".$trace[1];
    }
    else
    {
        $trace_return = $trace_return."\n-1";
    }
    return $trace_return;
  }
}
1;
__END__


=back

=back

=head2 Discussion

This module provides an interface to the various WordNet::Similarity measures.
It implements functions that take as argument two words then find the similarity
scores scores for all the senses of these words. This module also implements the
funtion that takes as input a tracestring and converts it to the meta-language.

=head3 Meta-language

The first line in the meta language is the measure name. The next two line list
all the possible shortest paths between the two concepts. The synsets represent
the nodes along these paths, thile the relation names between these synsets
represent the edges. If there is more than one shortest path they are also
listed. The alternate shortest paths are seperated using the OR operator. The
rest of the lines list all the other paths in the hypernym tree. These alternate
hypernym trees also use the same system as used in the shortest path. The next
line is the maximum depth of the hypertree

    path
    cat#n#1 hypernym feline#n#1 hypernym carnivore#n#1
    dog#n#1 hypernym canine#n#2 hypernym carnivore#n#1
    carnivore#n#1 hypernym placental#n#1 hypernym mammal#n#1 hypernym vertebrate#n#1 hypernym
      chordate#n#1 hypernym animal#n#1 hypernym organism#n#1 hypernym living_thing#n#1 hypernym
      object#n#1 hypernym entity#n#1 hypernym Root#n#1
    Max Depth = 13
    Path length = 5


=head1 SEE ALSO

WordNet::Similarity
WordNet::QueryData

Mailing List: E<lt>wn-similarity@yahoogroups.comE<gt>


=head1 AUTHOR

Saiyam Kohli, University of Minnesota, Duluth
kohli003@d.umn.edu

Ted Pedersen, University of Minnesota, Duluth
tpederse@d.umn.edu


=head1 COPYRIGHT

Copyright (c) 2005-2006, Saiyam Kohli and Ted Pedersen

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at <http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut