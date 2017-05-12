## $Id: Matcher.pm 152 2006-09-27 13:10:57Z anders $
# Copyright (c) 1996-1998 LUB NetLab, 2002-2006 Anders Ardö
# 
# See the file LICENCE included in the distribution.

package Combine::Matcher;

use Exporter();
@ISA=qw(Exporter);
@EXPORT=(Match);

use strict;
##use Combine::LoadTermList;
use HTML::Entities; 
use locale; #needed for \b in regexps to work OK  ????KOLLA????

#CONFIG
my $DoTermStat = 0;  # Dont save matched terms in a file for statitics
#my $DoTermStat = 1; # Do save matched terms in a file for statitics
#

#my $KeepTerms = 0; # Dont keep matched terms in an internal hash
my $KeepTerms = 1; # Do keep matched terms in an internal hash - MAY CAUSE MEMORY PROBLEM
my %mterms;        # hash to keep macthed terms

# Keep frequency of matched terms in an internal hash - MAY CAUSE MEMORY PROBLEM
my $KeepFreqTerms = 0; 
my %fterms;        # hash to keep frequency of macthed terms

#Matcher.pm ------------------

sub GetTermsM {
  # return matched terms up to now
  # empty hash of matched terms
  my %t;
  my $k;
  %t = %mterms;
  foreach $k (keys %mterms) { delete $mterms{$k}; }
  return (%t);
}

sub GetTermsF {
  # return frequency of matched terms up to now
  my %t;
  my $k;
  %t = %fterms;
  foreach $k (keys %fterms) { delete $fterms{$k}; }
  return (%t);
}

sub Match {
  my ($t, $termlist) = @_;
  #Accepts a text (either SCALAR or reference) and returns a list of classifications and scores 
  my %score;
  my $cl = "";
  my $k;
  my $i;
  my $ant;
  my $text; #Holds a reference to the text to be matched.
  if (ref($t)) {$text=$t;} else {$text=\$t;}
  if (length($$text) < 3) { return %score; } #unitialized?
  study($text); #OK att skicka in en reference?

  if ( $DoTermStat ) { open(TMS,">>TermMatchStat.txt"); }
  foreach $i (0 .. $#{$termlist->{Term}})
    {
      $k=@{$termlist->{Term}}[$i];
      if ( $k =~ /\@and/ )
	{ 
	  $ant= &boolmatch($k,$text);
	  if ( $ant > 0 ) {
	    if ( $DoTermStat ) { print TMS "$k\n"; }
	    foreach $cl ( split('\s*,\s+', @{$termlist->{TermClass}}[$i] ) )
	      {
		if (length($cl)>0)
		  {
#print "BHIT: $ant, $cl\n";
		    $score{$cl} += $ant * @{$termlist->{TermWeight}}[$i];
#fel		    if ( $KeepTerms && defined($mterms{$cl}) && ! ($mterms{$cl} =~ /$k, /) ) {
#OK warn		    if ( $KeepTerms && ! ($mterms{$cl} =~ /$k, /) ) {
		    if ( $KeepTerms && ( !defined($mterms{$cl}) || (! ($mterms{$cl} =~ /$k, /)) ) ) {
		      $mterms{$cl} .= "$k, ";
		    }
                    if ( $KeepFreqTerms ) { $fterms{$k}++; }
		  }
	      } 
	  }
	} else { 
	  while ($$text =~ /\b$k\b/g) { 
	    if ( $DoTermStat ) { print TMS "$k\n"; }
	    foreach $cl ( split('\s*,\s+', @{$termlist->{TermClass}}[$i] ) )
	      {
		  if (length($cl)>0)
		  {
#print "HIT: $cl ($k)\n";
		    $score{$cl} += @{$termlist->{TermWeight}}[$i];
#fel		    if ( $KeepTerms && defined($mterms{$cl}) && ! ($mterms{$cl} =~ /$k, /) ) {
#OK warn		    if ( $KeepTerms && ! ($mterms{$cl} =~ /$k, /) ) {
		    if ( $KeepTerms && ( !defined($mterms{$cl}) || (! ($mterms{$cl} =~ /$k, /)) ) ) {
		      $mterms{$cl} .= "$k, ";
		    }
                    if ( $KeepFreqTerms ) { $fterms{$k}++; }
		  }
	      } 
  
	  }
	}
  }
  if ( $DoTermStat ) { close(TMS); }
  return (%score);
  
}

sub boolmatch { 
  my ($terms, $text) = @_; 
  my $m; 
  my $min=100000; 
  my $t; 
  my @term; 
  @term = split('\s+\@and\s+', $terms); 
  foreach $t (@term) { 
    $m=0; 
    while ( $$text =~ /\b$t\b/g ) { $m++; } 
    if ( $m == 0 ) { return 0; } 
    if ( $min > $m ) { $min = $m; } 
  } 
  return $min; 
} 

#GetText.pm ------------------

sub getTextXWI {
  my ( $xwi, $DoStem, $stoplist, $simple) = @_;

  my $url ="";
  my $title="No Title";
  my $size=0;
  #  my $DoStem = 0 unless $DoStem; #False
  my $meta=""; my $head=""; my $text="";
  
  $xwi->meta_rewind;
  my ($name,$content);
  while (1) {
    ($name,$content) = $xwi->meta_get;
    last unless $name;
    next if ($name eq 'Rsummary');
    next if ($name =~ /^autoclass/);
    $meta .= $content . " ";
  } 

  $title = $xwi->title; # $head = $xwi->title; # AA0 Treated separately
  
  $xwi->heading_rewind;
  my $this;
  while (1) {
    $this = $xwi->heading_get or last; 
    $head .= $this . " "; 
  }

  $this = $xwi->text;
  if ($this) {
    $this = $$this;
    $text .= $this ;
  }

  $size = $xwi->length;

#unitialized?
  if ($simple) {
    if ( defined($meta) && ($meta ne '') ) { SimpletextConv(\$meta, $DoStem); }
    if ( defined($head) && ($head ne '') ) { SimpletextConv(\$head, $DoStem); }
    if ( defined($text) && ($text ne '') ) { SimpletextConv(\$text, $DoStem); }
    if ( defined($title) && ($title ne '') ) { SimpletextConv(\$title, $DoStem); }
  } else {
    if ( defined($meta) && ($meta ne '') ) { textConv(\$meta, $DoStem, $stoplist); }
    if ( defined($head) && ($head ne '') ) { textConv(\$head, $DoStem, $stoplist); }
    if ( defined($text) && ($text ne '') ) { textConv(\$text, $DoStem, $stoplist); }
    if ( defined($title) && ($title ne '') ) { textConv(\$title, $DoStem, $stoplist); }
  }
  return ($meta, $head, $text, $url, $title, $size);
}

#Keep??
sub getTextURL {
  my ( $url, $DoStem, $stoplist, $simple) = @_;

  my $title = "";
  my $size = 0;
#  my $DoStem = 0; #False
  my $meta=""; my $head=""; my $text="";
  my $html = `GET $url`;
  if ($html eq "") { return ($meta, $head, $text, $url, $title, -1); }
  $size = length($html);
  $html =~ s/\n/ /g;
  # converting HTML chars to Latin1
  $html = HTML::Entities::decode_entities($html);

  #title
  if ($html =~ s/<title>([^<]+)<\/title>//i) {
    $head = "$1 ";
    $title = $head;
  }

  #Metadata
  my $tmeta;
  $html =~ s/^(.*?)<body[^>]*>/ /i; # remove head
  my $tmp=$1;
  if ( $tmp ne "" ) {
    while ($tmp =~ /<meta(.*?)>/ig) {
      $tmeta = $1;
      if ($tmeta =~ /content=\"(.*?)\"/i) {
	$meta .= "$1 ";
      }
    }
  }

  #Headings
  my $heading;
  my $alt;
  while ($html =~ s/<h\d[^>]*?>(.*?)<\/h\d>/ /i) {
    $heading = $1;
    if ($heading =~ s/<.*?alt *= *"(.*?)">/ /i) {
      $alt = $1;
      $alt =~ s/<.*?>/ /g;
      $alt =~ s/\s+/ /g;
    }
    $heading =~ s/<.*?>/ /g;
    $heading =~ s/\s+/ /g;
    if ( $heading !~ /^\s*$/ ) {
      $head .= "$heading ";
    } elsif ( $alt !~ /^\s*$/ ) {
      $head .= "$alt ";
    }
  }

  #text
  $html =~ s/<script>.*?<\/script>/ /ig; # remove all the scripts
  $html =~ s/<img [^>]*?alt *= *"(.+?)"[^>]*?>/$1/ig; # keep IMG ALT texts
  # the follwing tags should not be replaced with space
  my $tag;
  foreach $tag ('font','i','b','u','blink','tt','big','small','strong'){
    $html =~ s/<\/?$tag[^>]*?>//gi;
  }
  $html =~ s/<.*?>/ /g; # replace all other tags including comments with whitespace
  $text = $html;

  if ($simple) {
    if ( $meta ne "") { SimpletextConv(\$meta, $DoStem); }
    if ( $head ne "") { SimpletextConv(\$head, $DoStem); }
    if ( $text ne "") { SimpletextConv(\$text, $DoStem); }
    if ( $title ne "") { SimpletextConv(\$title, $DoStem); }
  } else {
    if ( $meta ne "") { textConv(\$meta, $DoStem, $stoplist); }
    if ( $head ne "") { textConv(\$head, $DoStem, $stoplist); }
    if ( $text ne "") { textConv(\$text, $DoStem, $stoplist); }
    if ( $title ne "") { textConv(\$title, $DoStem, $stoplist); }
  }
  return ($meta, $head, $text, $url, $title, $size);
}

#textConv uses stoplist while SimpletextConv does not

sub textConv {
  my ($text, $DoStem, $stoplist) = @_;
#print "TEXTCONV: $DoStem\n";
  $$text =~ tr/0-9a-zA-ZÅÄÖåäöøæØÆ\/\'-/ /c; #Keep ' - /
  # lowercase words except all uppercase acronyms
  my @text=split(/\s+/,$$text);
  $$text="";
  my $word;
  my $w;
  my $sterm;
  foreach $word (@text) {
    #print "W:$word\n";
    if ( $word =~ /[a-z]/ ) {
      $word =~ tr/A-ZÅÄÖØÆ/a-zåäöøæ/;
      next if ( exists ${$stoplist->{StopWord}}{$word} );
      if ( $DoStem ) {
	$sterm = Lingua::Stem::stem($word);  #Porters stemming
	$w=join('',@{$sterm});
        next if ( ! exists ${$stoplist->{TermWord}}{$w} );
	$$text .= "$w ";
        #print " WS:$w\n";
      } else {
	next if ( ! exists ${$stoplist->{TermWord}}{$word} );
	$$text .= "$word ";
        #print " WW:$word\n";
      }
    } else {
      next if ( ! exists ${$stoplist->{TermWord}}{$word} );
      $$text .= "$word ";
    }
  }
  $$text =~ s/\s+$//;
  return;
}

sub SimpletextConv {
  my ($text, $DoStem) = @_;
  $$text =~ tr/0-9a-zA-ZÅÄÖåäöøæØÆ\/\'-/ /c; #Keep ' - /
  # lowercase words except all uppercase acronyms
  my @text=split(/\s+/,$$text);
  $$text="";
  my $word;
  my $w;
  my $sterm;
  foreach $word (@text) {
    if ( $word =~ /[a-z]/ ) {
      $word =~ tr/A-ZÅÄÖØÆ/a-zåäöøæ/;  # do this for all words????
      if ( $DoStem ) {
	$sterm = Lingua::Stem::stem($word);  #Porters stemming
	$w=join('',@{$sterm});
	$$text .= "$w ";
        #print " WS:$w\n";
      } else {
	$$text .= "$word ";
        #print " WW:$word\n";
      }
    } else {
      $$text .= "$word ";
    }
  }
  $$text =~ s/\s+$//;
  return;
}


1;

__END__

=head1 NAME

Matcher

=head1 DESCRIPTION

This a module in the DESIRE automatic classification system. Copyright 1999.
Modified in the ALVIS project. Copyright 2004

Exported routines:
1. Fetching text:
   These routines all extract texts from a document (either
   a Combine XWI datastructure or a WWW-page identified by a URL.
   They all return: $meta, $head, $text, $url, $title, $size
        $meta: Metadata from document
        $head: Important text from document
        $text: Plain text from document
        $url: URL of the document
        $title: HTML title of the document
        $size: The size of the document

   Common input parameters:
        $DoStem: 1=do stemming; 0=no stemming
        $stoplist: object pointer to a LoadTermList object with a stoplist loaded
        $simple: 1=do simple loading; 0=advanced loading (might induce errors)

 getTextXWI
     parameters: $xwi, $DoStem, $stoplist, $simple
       $xwi is a Combine XWI datastructure

 getTextURL
    parameters: $url, $DoStem, $stoplist, $simple
       $url is the URL for the page to extract text from

2. Term matcher
    accepts a text as a (reference) parameter, matches each term in Term against text
    Matches are recorded in an associative array with class as key and summed weight as value.
  Match
    parameters: $text, $termlist
       $text: text to match against the termlist
       $termlist: object pointer to a LoadTermList object with a termlist loaded
    output: 
       %score: an associative array with classifications as keys and scores as values

=head1 AUTHOR

Anders Ardö <anders.ardo@it.lth.se>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005,2006 Anders Ardö

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

See the file LICENCE included in the distribution at
 L<http://combine.it.lth.se/>

=cut
