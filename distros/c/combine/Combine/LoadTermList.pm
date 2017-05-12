# Copyright (c) 1999 Anders Ardö

package Combine::LoadTermList;

#use Exporter();
#@ISA=qw(Exporter);
#@EXPORT=(LoadTermList, LoadTermListStemmed, Term, TermClass, TermWeight);

use strict;
use DBI;

my $IgnoreLength = 3; # ignore terms shorter than 3 characters

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self =  {};
  $self->{Term} = [];
  $self->{TermClass} = [];
  $self->{TermWeight} = [];
  $self->{StopWord} = {};
  $self->{TermWord} = {};
  bless ($self , $class);
  return $self;
}

sub LoadStopWordList {
# Load stopword list from a file, one word per line
  my ($self, $StopWordList) = @_;
  my $text;
  my $ant = 0;
  open(TT,"<$StopWordList") || die "LoadStopWordList: No FileName: $StopWordList"; 
  while (<TT>) { 
    chop; 
    ${$self->{StopWord}}{$_}=1;
    $ant++;
  }
  close(TT);
  return $ant;
}

sub LoadStopWordListSQL {
# Load stopword list from the SQL database
  my ($self, $databasehandle) = @_;
  my $ant = 0;
  my $sth = $databasehandle->prepare(qq{SELECT term FROM stopwords;});
  $sth->execute;
  while (my ($t)=$sth->fetchrow_array) {
    ${$self->{StopWord}}{$t}=1;
    $ant++;
  }
  return $ant;
}

sub SaveStopWordListSQL {
# Saves the current stopword list in SQL database
  my ($self, $databasehandle) = @_;
  $databasehandle->do(qq{DELETE FROM stopwords;});
  my $sth = $databasehandle->prepare(qq{INSERT INTO stopwords SET term=?;});
  foreach my $w (keys(%{$self->{StopWord}})) {
      $sth->execute($w);
  }
  return;
}

sub EraseStopWordList {
  my ($self) = @_;
  my $w;
  foreach $w (keys %{$self->{StopWord}} ) {
    delete ${$self->{StopWord}}{$w};
  }
}

sub LoadTermList {
  my ($self, $TermList) = @_;
  my $text;
  my $weight;
  my $class;
  my $word;
  my @text;
  my $i=0;

  open(TT,"<$TermList") || die "LoadTermList: No FileName";
  while (<TT>) {
    chop;
    if ( /^\s*(-?\d+):\s+([^=]+)\s*=\s*(.*)$/ ) {
      $weight=$1; $text=$2; $class=$3;
      @text=split(/\s+/,$text);
      $text="";
      foreach $word (@text) {
	next if ( exists ${$self->{StopWord}}{$word} );
	$text .= "$word ";
        ${$self->{TermWord}}{$word}=1;
      }
      $text =~ s/\s+$//;
      next if ( length($text) < $IgnoreLength );
      @{$self->{Term}}[$i]=$text;
      @{$self->{TermClass}}[$i]=$class;
      @{$self->{TermWeight}}[$i]=$weight;
      $i++;
    }
  }
  close(TT);
  return $i;
}

sub LoadTermListStemmed {
  my ($self, $TermList) = @_;
  my $text;
  my $weight;
  my $class;
  my $word;
  my @text;
  my $sterm;
  my $k;
  my $i = 0;
  use Lingua::Stem; #For stemming

  open(TT,"<$TermList") || die "LoadTermList: No FileName";
  while (<TT>) {
    chop;
    if ( /^\s*(-?\d+):\s+([^=]+)\s*=\s*(.*)$/ ) {
      $weight=$1; $text=$2; $class=$3;
      next if (length($text) < $IgnoreLength );

      # stem terms except uppercase acronyms
      @text=split(/\s+/,$text);
      $text="";
      foreach $word (@text) {
      next if ( exists ${$self->{StopWord}}{$word} );
	if ( $word =~ /[a-z]/ && $word ne "\@and" ) {
	  $sterm = Lingua::Stem::stem($word);  #Porters stemming 
	  $k=join('',@{$sterm}); #??
	  $text .= "$k ";
          ${$self->{TermWord}}{$k}=1;
	} else { $text .= "$word "; ${$self->{TermWord}}{$word}=1; }
      }
      $text =~ s/\s+$//;
      next if (length($text) < $IgnoreLength );
      @{$self->{Term}}[$i]=$text;
      @{$self->{TermClass}}[$i]=$class;
      @{$self->{TermWeight}}[$i]=$weight; 
      $i++;
    }
  }
  close(TT);
  return $i;
}

sub LoadTermListSQL {
  my ($self, $databasehandle) = @_;
  my $i = 0;
  my $sth = $databasehandle->prepare(qq{SELECT term,weight,class FROM topicdefinition;});
  $sth->execute;
  while (my ($text,$weight,$class)=$sth->fetchrow_array) {
      my @text=split(/\s+/,$text);
      $text='';
      foreach my $word (@text) {
        next if ( exists ${$self->{StopWord}}{$word} );
        $text .= "$word ";
        ${$self->{TermWord}}{$word}=1;
      }
      $text =~ s/\s+$//;
      next if ( length($text) < $IgnoreLength );
      @{$self->{Term}}[$i]=$text;
      @{$self->{TermClass}}[$i]=$class;
      @{$self->{TermWeight}}[$i]=$weight;
      $i++;
  }
  return $i;
}

sub LoadTermListStemmedSQL {
  my ($self, $databasehandle) = @_;
  my $i = 0;
  my $sth = $databasehandle->prepare(qq{SELECT term,weight,class FROM topicdefinition;});
  $sth->execute;
  while (my ($text,$weight,$class)=$sth->fetchrow_array) {
      next if ( length($text) < $IgnoreLength );
      # stem terms except uppercase acronyms
      my @text=split(/\s+/,$text);
      $text='';
      foreach my $word (@text) {
        next if ( exists ${$self->{StopWord}}{$word} );
        if ( $word =~ /[a-z]/ && $word ne "\@and" ) {
          my $sterm = Lingua::Stem::stem($word);  #Porters stemming 
          my $k=join('',@{$sterm}); #??
          $text .= "$k ";
          ${$self->{TermWord}}{$k}=1;
        } else { $text .= "$word "; ${$self->{TermWord}}{$word}=1; }
      }
      $text =~ s/\s+$//;
      next if ( length($text) < $IgnoreLength );
      @{$self->{Term}}[$i]=$text;
      @{$self->{TermClass}}[$i]=$class;
      @{$self->{TermWeight}}[$i]=$weight;
      $i++;
  }
  return $i;
}

sub SaveTermListSQL {
# Use with care since LoadTermList does modifications (stopword removal
# and removal of small terms < IngnoreLength
  my ($self, $databasehandle) = @_;
  $databasehandle->do(qq{DELETE FROM topicdefinition;});
  my $sth = $databasehandle->prepare(qq{INSERT INTO topicdefinition (term,class,weight) VALUES(?,?,?);});
  foreach my $i (0 .. $#{$self->{Term}}) {
      my $t=@{$self->{Term}}[$i];
      my $w=@{$self->{TermWeight}}[$i];
      my $c=@{$self->{TermClass}}[$i];
      $sth->execute($t,$c,$w);
  }
  return;
}


__END__

=head1 NAME

LoadTermList

=head1 DESCRIPTION

This a module in the DESIRE automatic classification system. Copyright 1999. 

LoadTermList - A class for loading and storing 
      a stoplist with single words
      a termlist with classifications and weights

 Subroutines:
   LoadStopWordList(StopWordListFileName)
      loads a list of stopwords, one per line, from 
      the file StopWordListFileName.

   EraseStopWordList
      clears the stopword list


 Subroutines:
  LoadTermList(TermListFileName) - loads TermClass from file
  LoadTermListStemmed(TermListFileName) - same plus stems terms


 Input: A formatted term-list including weights and classifications
  Format:  <weight>: <term_reg_exp>=[<classification>, ]+
  weight can be a positive or negative number
  term_reg_exp can be words, phrases, boolean expressions (with @and
     as operator) on term_reg_exp or Perl regular expressions


=head1 AUTHOR

Anders Ardö <Anders.Ardo@it.lth.se>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005,2006 Anders Ardö

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

See the file LICENCE included in the distribution at
 L<http://combine.it.lth.se/>

=cut
