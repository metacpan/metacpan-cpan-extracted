#!/usr/bin/perl

package WordNet::BestStem;

use base qw( Exporter );
our @EXPORT = ();
our @EXPORT_OK = qw( best_stem  deluxe_stems );

=head1 NAME

WordNet::BestStem -- get the best guess stem of a word.

=head1 VERSION

0.2.2

=cut

$VERSION = '0.2.2';

use strict;
use warnings;

use Data::Dumper;
use List::Util qw( max );
use WordNet::QueryData;
use WordNet::Similarity::ICFinder;

=head1 SYNOPSIS

  my $best = best_stem( 'roses', {V=>1} );

=head1 DESCRIPTION

Based on the assumption that the stem has the highest occurence frequency in text corpus. Of course it is not always true, but for certain purposes it may be justifiable to treat the most frequent form as stem.

Find a word's variant forms. Returns the highest frequency (part-of-speech) form according to ICFinder's "information content file", which comes by default with WordNet but can be customized.

ICFinder has frequency count for n and v part-of-speech and not a or r. When a or r is involved, use the number of senses for part-of-speech intead of fre of wp to choose form.

Alternatively, best_stem can use a custom word variant frequency table.

=head1 METHODS

=head2 best_stem

Returns in list context the best guess stem form, part-of-speech, and frequency; returns in scalar context the stem form.

*Note: WordNet does not at the moment have variant forms for very high frequency words, like "what", "the", "would". best_stem returns empty string in such cases.

Default options (case insensitive):

  V     => 0,         # verbose. for debugging / checking
  FRE   => undef,     # % ref to custom word variant frequency table

Usage:

  use WordNet::BestStem qw( best_stem );

  print best_stem('misgivings');          # misgiving n 8
  print best_stem('roses');               # rose n 5
  print best_stem('rose');                # rise v 17

Compared to WordNet::stem,

  use WordNet::QueryData;
  use WordNet::stem;

  $WN = WordNet::QueryData->new();
  $stemmer = WordNet::stem->new($WN)

  print $stemmer->stemWord('misgivings')  # misgiving
  print $stemmer->stemWord('roses')       # rose
  print $stemmer->stemWord('rose')        # rose rise

Compared to Lingua::Stem::En,

  use Lingua::Stem::En qw( stem );

  $stems = stem( { -words => ['misgivings'] } );
  print @$stems;                          # misgiv

  $stems = stem( { -words => ['roses'] } );
  print @$stems;                          # rose

  $stems = stem( { -words => ['rose'] } );
  print @$stems;                          # rose

=cut

  # put it outside so we don't have to init it
  # every time we call the function
my $WN  = WordNet::QueryData->new;
my $ICF = WordNet::Similarity::ICFinder->new( $WN );
  # hash WordNet results so we don't have to query it everytime
my $BEST_FOR = {};

sub best_stem { 
  my ($str, $opt) = @_;
    # WordNet hangs with some nonword stuff
  return( wantarray? ('', '', 0) : '' )
    unless $str =~ /^\w/;

  my %opt = (
    V     => 0,
    FRE   => undef,       # % ref to custom word variant frequency table
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  return $BEST_FOR->{$str}
    unless $opt{FRE} or wantarray or !$BEST_FOR->{$str};

  my ($best_w, $best_p, $best_fre) = ('', '', undef);

  my %wps;    # Word Part_of_speech Sense
  for my $wp_0 ($WN->validForms($str)) {
    if ($opt{FRE}) {
      my ($w, $p) = split '#', $wp_0;
      $opt{V} and print STDERR "w: $w\t" . ($opt{FRE}->{$w}||0) . "\n";
      ($best_w, $best_p, $best_fre) = ($w, $p, $opt{FRE}->{$w}||0)
        if !defined($best_fre)
        or ($opt{FRE}->{$w} and $opt{FRE}->{$w} > $best_fre);
    }

    if (!$best_w) {     # fall back on wordnet if no fre for word
      $opt{V} and print STDERR "wp_0: $wp_0\n";
      $wps{$_} = 1 for ($WN->querySense($wp_0));
    }
  }
  if ($best_w) {
    !$opt{FRE} and $BEST_FOR->{$str} = $best_w;
    return wantarray? ($best_w, $best_p, $best_fre) : $best_w;
  }

  my (%c, $n_sense);
  for (keys %wps) {
    my ($w, $p, $s) = split '#', $_;

      # use num sense instead of fre of part_of_speech to choose form
    $n_sense ||= 1
      if $p eq 'a' or $p eq 'r';

    my $fre = $ICF->getFrequency($_, $p, 'wps') || 0;
    $c{$w}{$p}[0] ++;         # num of part_of_speech senses
    $c{$w}{$p}[1] += $fre;    # fre of part_of_speech across senses
    
    $opt{V} and print STDERR "\t$_\t$fre\n";
  } 
  $opt{V} and print STDERR Dumper(\%c);

  if (!$n_sense) {  # use fre of part_of_speech to choose form
    for my $w ( keys %c ) {
      for my $p ( keys %{ $c{$w} }) {
        ($best_w, $best_p, $best_fre) = ($w, $p, $c{$w}{$p}[1])
          if !defined($best_fre) or $c{$w}{$p}[1] > $best_fre;
      }
    }
  }
  else {           # use num of sense of part_of_speech to choose form
    # no fre profile for r and a
    # so when r or a are involved, use num of senses to help choose form
    # get the pos with highest num of senses for each wp
    for my $w (sort keys %c) {
	# do it in this order, ie bias towards early one when have same value
	# more nouns than other forms in language => nouns have lower fre
	# ditto re r and a ?
      for my $p (qw( r a v n )) {
        ($best_w, $best_p, $best_fre) = ($w, $p, $c{$w}{$p}[0])
          if !defined($best_fre) or ($c{$w}{$p} and $c{$w}{$p}[0] > $best_fre);
      }
    }
  }

  !$opt{FRE} and $BEST_FOR->{$str} = $best_w;
  return wantarray? ($best_w, $best_p, $best_fre) : $best_w;
}

=head2 deluxe_stems

Uses contextual info, ie appearances of word forms in paragraph/corpus to help choose stem form.

Default options (case insensitive):

  V     => 0,
  FRE   => undef,    # % ref to custom word variant frequency table
  STEM  => undef,    # % ref to stem_of{string} table per best_stem

Usage:

  use WordNet::BestStem qw( deluxe_stems );

  my $stemmed_text = deluxe_stems \@text;

or in list context

    # ref to @, %, %, %
  my ($stemmed, $stem_of, $stem_fre, $str_fre) = deluxe_stems \@paragraph;

For two paragraphs / sentences,

  a) beautiful roses i would like a long stem rose
  b) he thinks that average salary rose in the last few years

deluxe_stems,

  $a_ = deluxe_stems \@a;
  print @$a_;
    # beautiful rose i would like a long stem rose
    # he think that average salary rise in the last few year

Compared to best_stem,

  @a_ = map { scalar( best_stem $_ ) || $_ } @a;
  print "@a_\n";
    # beautiful rose i would like a long stem rise
    # he think that average salary rise in the last few year

=cut

sub deluxe_stems {
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';

  my ($parag) = @_;
  my %opt = (
    V     => 0,
    FRE   => undef,    # % ref to custom word variant frequency table
    STEM  => undef,    # % ref to stem_of{string} table per best_stem
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  $opt{STEM} ||= $BEST_FOR;

  my %str_fre;
  $str_fre{$_} ++
    for (@$parag);

  my (%nonambi, %str_wp, %fre_wp);
  while (my ($str, $fre) = each %str_fre) {
    next
      if length $str < 2 or $str =~ /\W/;
    my (%wp, $w);
    for ($WN->validForms($str)) {
      ($w, my $p) = split '#', $_;
      $wp{$w} = 1;
    }
    $fre_wp{$_} += $fre
      for (keys %wp);

    if ((keys %wp) == 1) {            # final form
      $nonambi{$w}  = 1;                # $str_fre{$str};
      $str_wp{$str} = $w;
    }
    elsif ((keys %wp) > 1) {          # save for further processing
      $str_wp{$str} = \%wp;
    }
    else {                            # no wordnet data. leave empty
    }
  }
  $opt{V} and do {
    print STDERR "nonambiguous:\t" . (keys %nonambi) . "\n";
    print STDERR "ambiguous:\t" . (grep {ref $str_wp{$_}} keys %str_wp) . "\n";
    for my $w (keys %str_wp) {
      next
        unless ref $str_wp{$w};
      print STDERR "\t$w:\t";
      print STDERR "$_=$fre_wp{$_}\t"
        for (keys %{$str_wp{$w}});
      print STDERR "\n";
    }
  };

  my @stems;
  for my $str (@$parag) {
    if ( !$str_wp{$str} or !ref($str_wp{$str}) ) {       # final form
      push @stems, $str_wp{$str} || $str;
    }
    else {                             # make a guess
      my $guess;

      my @candis = grep { $nonambi{$_} } keys %{ $str_wp{$str} };
#      my @candis = keys %{ $str_wp{$str} };
      my $best = $opt{STEM}->{$str} || best_stem( $str, {fre=>$opt{FRE}} );

      push @candis, $best
        unless $nonambi{$best};

      if (@candis > 1) {             # pick highest potential wp fre 
        $guess = $best;
        my $f  = $fre_wp{$guess} || 1;
        for (@candis) {
          ($guess, $f) = ($_, $fre_wp{$_})
            if $fre_wp{$_} > $f;
        }
      }
      else {
        $guess = pop @candis;      # at least best_stem
      }

      $guess ||= $str;
      push @stems, $guess;
    }
  }

  return \@stems
    unless wantarray;

  my (%stem_of, %stem_fre);
  @stem_of{ @$parag } = @stems;
  for (keys %str_fre) { $stem_fre{ $stem_of{$_} } += $str_fre{$_} }

  return \@stems, \%stem_of, \%stem_fre, \%str_fre;
}

=head1 DEPENDENCIES

  WordNet  ( http://wordnet.princeton.edu )
  WordNet::QueryData
  WordNet::Similarity::ICFinder

=head1 AUTHOR

~~~~~~~~~~~~ ~~~~~ ~~~~~~~~ ~~~~~ ~~~ `` ><(((">

Copyright (C) 2009 Maggie J. Xiong  < maggiexyz users.sourceforge.net >

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as Perl itself.

=cut

1;
