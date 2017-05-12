## $Id: PosMatcher.pm 252 2007-10-17 09:09:25Z anders $

# 2002-2006 Anders Ardö
# 
# See the file LICENCE included in the distribution.

package Combine::PosMatcher;

use Exporter();
@ISA=qw(Exporter);
@EXPORT=(Match);

use strict;
use Combine::XWI2XML;
use HTML::Entities; 
use locale; #needed for \b in regexps to work OK

#CONFIG
my $DoTermStat = 0;  # Dont save matched terms in a file for statitics
#my $DoTermStat = 1; # Do save matched terms in a file for statitics
#
#my $KeepTerms = 0; # Dont keep matched terms in an internal hash
my $KeepTerms = 1; # Do keep matched terms in an internal hash - MAY CAUSE MEMORY PROBLEM
my %mterms;        # hash to keep macthed terms

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

sub Match {
  my ($t, $termlist) = @_;
  #Accepts a text (either SCALAR or reference) and returns a list of classifications and scores 
  my %score;
  my $cl = "";
  my $text; #Holds the text to be matched.
#  if (ref($t)) {$text=$t;} else {$text=\$t;}
#  if (length($$text) < 3) { return %score; } #unitialized?

#NEW
  if (ref($t)) {$text=$$t;} else {$text=$t;}
  if (length($text) < 3) { return %score; } #unitialized?
#generate inverted hash table
  my $cpos=0;
  my %pos;
  foreach my $w (split('[\b\s]+',$text)) {
      $cpos++;
      push(@{$pos{$w}},$cpos);
#      print "POS=$w at $cpos\n";
  }
  if ( $DoTermStat ) { open(TMS,">>TermMatchStat.txt"); }
  foreach my $i (0 .. $#{$termlist->{Term}}) {
      my $k=@{$termlist->{Term}}[$i];
      if ( $k =~ /\@and/ ) { #Boolean
	  my $ipos=0;
	  ALLBOOL: while ( 1 ) {
#	      print "Loop $ipos: Process boolean: $k\n";
	      my @b_pos=();
	      foreach my $kk (split(' \@and ',$k)) {
		  # a $kk could be a phrase
		  if ( defined($pos{$kk}) && ($#{$pos{$kk}}>=$ipos) ) {
		      my $t=$#{$pos{$kk}};
#		      print "Pushing $kk array ant=$t\n";
		      push(@b_pos, ${$pos{$kk}}[$ipos]);
		  } else { last ALLBOOL; }
	      }
	      $ipos++;
	      # calc minimum position and mean of proximity between terms
	      my $p=$b_pos[0]; my $proxim=0;
	      foreach my $pi (1..$#b_pos) {
		  if ($b_pos[$pi] < $p) { $p = $b_pos[$pi]; }
		  $proxim += abs($b_pos[$pi] - $b_pos[$pi-1]);
#		  print "Proxim: L=$pi, p=$proxim, 1=$b_pos[$pi], 2=$b_pos[$pi-1]\n";
	      }
	      $proxim = $proxim/$#b_pos;
	      if ( $DoTermStat ) { print TMS "$k\n"; }
	      #calc score
	      foreach my $cl ( split('\s*,\s+', @{$termlist->{TermClass}}[$i] ) ) {
#		  print "Found: $k at $p (proximity=$proxim) giving $cl, ";
		  if (length($cl)>0) {
		      $score{$cl} +=  @{$termlist->{TermWeight}}[$i] / (log(0.5*$p+1.0) * log($proxim+1.0));
		    #  print "Score now $score{$cl}\n";
		      if ( $KeepTerms && ( !defined($mterms{$cl}) || (! ($mterms{$cl} =~ /$k, /)) ) ) {
			  $mterms{$cl} .= "$k, ";
		      }
		  }
	      }
	      # end calc
	  } #end ALLBOOL
      } elsif ( $k =~ /\s/ ) { #Phrases
#	  print "Phrase: $k\n";
	  my ($pw,@pr_words) = (split('\s+',$k));
#	  print "Word 1: $pw\n";
	  if (defined(@{$pos{$pw}})) {
	      ALLP: foreach my $p (@{$pos{$pw}}) {
		  my $ipos=$p+1;
		  my $fail = 1;
		  WORD: foreach my $kk (@pr_words) {
		      if ( defined($pos{$kk}) ) {
			  foreach my $pi (@{$pos{$kk}}) {
#			      print "POS $kk=$pi; $pw=$p; ipos=$ipos\n";
			      if ( $pi == $ipos ) {
				  $ipos++;
				  $fail = 0;
				  next WORD;
			      }
			  }
		      } else { last ALLP; }
		      $fail = 1;
		  }
		  if ( $fail == 0 ) {
		      #calc score
		      foreach my $cl ( split('\s*,\s+', @{$termlist->{TermClass}}[$i] ) ) {
#			  print "Found(phrase): $k at $p giving $cl, ";
			  if (length($cl)>0) {
			      $score{$cl} +=  @{$termlist->{TermWeight}}[$i] / log(0.5*$p+1.0);
			    #  print "Score now $score{$cl}\n";
			      if ( $KeepTerms && ( !defined($mterms{$cl}) || (! ($mterms{$cl} =~ /$k, /)) ) ) {
				  $mterms{$cl} .= "$k, ";
			      }
			  }
		      }
		      # end calc
		  }
	      } #end ALLP
	    }
      
      } else { #single words
	  if (defined($pos{$k})) {
	      if ( $DoTermStat ) { print TMS "$k\n"; }
	      foreach my $p (@{$pos{$k}}) {
		  #calc score
		  foreach my $cl ( split('\s*,\s+', @{$termlist->{TermClass}}[$i] ) ) {
#		     print "Found: $k at $p giving $cl, ";
		      if (length($cl)>0) {
			  $score{$cl} +=  @{$termlist->{TermWeight}}[$i] / log(0.5*$p+1.0);
	#		  print "Score now $score{$cl}\n";
			  if ( $KeepTerms && ( !defined($mterms{$cl}) || (! ($mterms{$cl} =~ /$k, /)) ) ) {
			      $mterms{$cl} .= "$k, ";
			  }
		      }
		  }
		  # end calc
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
    if (defined($Combine::XWI2XML::dcMap{$name})) { $name = $Combine::XWI2XML::dcMap{$name}; }
    next unless (($name =~ /subject/) || ($name =~ /description/));
    $meta .= $content . " ";
  } 

  $title = $xwi->title; # $head = $xwi->title; # AA0 Treated separately

  $url = $xwi->urlpath;
  $url =~ s/^\///;
  $url =~ s/\// /g;

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
    if ( defined($url) && ($url ne '') )   { SimpletextConv(\$url, $DoStem); }
    if ( defined($title) && ($title ne '') ) { SimpletextConv(\$title, $DoStem); }
  } else {
    if ( defined($meta) && ($meta ne '') ) { textConv(\$meta, $DoStem, $stoplist); }
    if ( defined($head) && ($head ne '') ) { textConv(\$head, $DoStem, $stoplist); }
    if ( defined($text) && ($text ne '') ) { textConv(\$text, $DoStem, $stoplist); }
    if ( defined($url) && ($url ne '') )   { textConv(\$url, $DoStem, $stoplist); }
    if ( defined($title) && ($title ne '') ) { textConv(\$title, $DoStem, $stoplist); }
  }
  return ($meta, $head, $text, $url, $title, $size);
}

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

sub textConv {
  my ($text, $DoStem, $stoplist) = @_;
#print "TEXTCONV: $DoStem\n";
  $$text =~ tr/0-9a-zA-ZÅÄÖåäöøæØÆ\/\'-/ /c; #Keep ' - /
  # lowercase words except all uppercase acronyms
  my @text=split(/\s+/,$$text);
  $$text="";
  my $word;
  my $w;
  my @sterm;
  foreach $word (@text) {
    #print "W:$word\n";
    if ( $word =~ /[a-z]/ ) {
      $word =~ tr/A-ZÅÄÖØÆ/a-zåäöøæ/;
      next if ( exists ${$stoplist->{StopWord}}{$word} );
      if ( $DoStem ) {
	@sterm = Text::English::stem($word);  #Porters stemming
	$w="@sterm";
        next if ( ! exists ${$stoplist->{TermWord}}{$w} );
	$$text .= "@sterm ";
        #print " WS:@sterm\n";
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
  my @sterm;
  foreach $word (@text) {
    if ( $word =~ /[a-z]/ ) {
      $word =~ tr/A-ZÅÄÖØÆ/a-zåäöøæ/;  # do this for all words????
      if ( $DoStem ) {
	@sterm = Text::English::stem($word);  #Porters stemming
	$w="@sterm";
	$$text .= "@sterm ";
        #print " WS:@sterm\n";
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

#EiUtil.pm ------------------

sub cleanEiTree {
  my (%cls) = @_;
# sum down the tree to the most specific leave and delete
# all above that
#512.1.1 += 512.1 + 512 + 51 + 5
#941.4 += 941 + 94 + 9
#941 += 94 + 9
#940 += 9
  my $cl;
  my ($t1, $t2, $t3, $t4);
  my %dels;
  foreach $cl (sort { length($b)<=>length($a); } keys(%cls)) {
    if ($cl =~ /^(\d)(\d)(\d)\.(\d)\.\d$/) {
      $t1=$1.$2.$3.".".$4;
      $t2=$1.$2.$3;
      $t3=$1.$2;
      $t4=$1;
      $cls{$cl} += $cls{$t1} +$cls{$t2} +$cls{$t3} +$cls{$t4};
      $mterms{$cl} .= $mterms{$t1} . $mterms{$t2} . $mterms{$t3} . $mterms{$t4};
      $dels{$t1}=1;$dels{$t2}=1;$dels{$t3}=1;$dels{$t4}=1;
    } elsif ($cl =~ /^(\d)(\d)(\d)\.\d$/) {
      $t2=$1.$2.$3;
      $t3=$1.$2;
      $t4=$1;
      #print "$cl=$cls{$cl}+$t2+$t3+$t4";
      $cls{$cl} += $cls{$t2} +$cls{$t3} +$cls{$t4};
      $mterms{$cl} .= $mterms{$t2} . $mterms{$t3} . $mterms{$t4};
      #print "=$cls{$cl} ";
      $dels{$t2}=1;$dels{$t3}=1;$dels{$t4}=1;
    } elsif ($cl =~ /^(\d)(\d)\d$/) {
      $t3=$1.$2;
      $t4=$1;
      $cls{$cl} += $cls{$t3} +$cls{$t4};
      $mterms{$cl} .= $mterms{$t3} . $mterms{$t4};
      $dels{$t3}=1;$dels{$t4}=1;
    } elsif ($cl =~ /^(\d)\d$/) {
      $t4=$1;
      $cls{$cl} += $cls{$t4};
      $mterms{$cl} .= $mterms{$t4};
      $dels{$t4}=1;
    } else {
      print STDERR "ERROR: klass= $cl\n"; #FIXA!!
    }
  }
  #print "\n";
  foreach $cl (keys(%dels)) { delete($cls{$cl}); }
  return %cls;
}


1;

__END__

=head1 NAME

PosMatcher

=head1 DESCRIPTION

This a module in the DESIRE automatic classification system. Copyright 1999.

Exported routines:
1. Fetching text:
   These routines all extract texts from a document (either a Combine record,
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

3. Heuristics: sum scores down the classification tree to the leafs
  cleanEiTree
    parameters: %res - an associative array from Match
    output:     %res - same array

=head1 AUTHOR

Anders Ardö, E<lt>anders.ardo@it.lth.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005,2006 Anders Ardö

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

See the file LICENCE included in the distribution at
 L<http://combine.it.lth.se/>

=cut
