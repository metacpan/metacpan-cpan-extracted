# Copyright (c) 1996-1998 LUB NetLab
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 1, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# 			    NO WARRANTY
# 
# BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
# 
# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
# 
# Copyright (c) 1996-1998 LUB NetLab

# $Id: FromHTML.pm 292 2008-11-08 08:54:11Z it-aar $

package Combine::FromHTML;

use strict;
use Combine::Config;
use HTTP::Date;
use URI;
use URI::Escape;
use HTML::Entities;
use Encode;

# Character entities to char mapping. We do NOT convert those 
# entities with a structural meaning, because most likely 
# the output of this module will go through postprocessing. 
#
my %Ent2CharMap=(

		 # amp    => '&',
		 # gt    => '>',
		 # lt    => '<',
		 # quot   => '"',
		 # apos   => "'",

		 AElig  => 'Æ',
		 Aacute => 'Á',
		 Acirc  => 'Â',
		 Agrave => 'À',
		 Aring  => 'Å',
		 Atilde => 'Ã',
		 Auml   => 'Ä',
		 Ccedil => 'Ç',
		 ETH    => 'Ð',
		 Eacute => 'É',
		 Ecirc  => 'Ê',
		 Egrave => 'È',
		 Euml   => 'Ë',
		 Iacute => 'Í',
		 Icirc  => 'Î',
		 Igrave => 'Ì',
		 Iuml   => 'Ï',
		 Ntilde => 'Ñ',
		 Oacute => 'Ó',
		 Ocirc  => 'Ô',
		 Ograve => 'Ò',
		 Oslash => 'Ø',
		 Otilde => 'Õ',
		 Ouml   => 'Ö',
		 THORN  => 'Þ',
		 Uacute => 'Ú',
		 Ucirc  => 'Û',
		 Ugrave => 'Ù',
		 Uuml   => 'Ü',
		 Yacute => 'Ý',
		 aacute => 'á',
		 acirc  => 'â',
		 aelig  => 'æ',
		 agrave => 'à',
		 aring  => 'å',
		 atilde => 'ã',
		 auml   => 'ä',
		 ccedil => 'ç',
		 eacute => 'é',
		 ecirc  => 'ê',
		 egrave => 'è',
		 eth    => 'ð',
		 euml   => 'ë',
		 iacute => 'í',
		 icirc  => 'î',
		 igrave => 'ì',
		 iuml   => 'ï',
		 ntilde => 'ñ',
		 oacute => 'ó',
		 ocirc  => 'ô',
		 ograve => 'ò',
		 oslash => 'ø',
		 otilde => 'õ',
		 ouml   => 'ö',
		 szlig  => 'ß',
		 thorn  => 'þ',
		 uacute => 'ú',
		 ucirc  => 'û',
		 ugrave => 'ù',
		 uuml   => 'ü',
		 yacute => 'ý',
		 yuml   => 'ÿ',

		 copy   => '©',
		 reg    => '®',
		 # nbsp   => "\240",
		 nbsp   => ' ',

		 iexcl  => '¡',
		 cent   => '¢',
		 pound  => '£',
		 curren => '¤',
		 yen    => '¥',
		 brvbar => '¦',
		 sect   => '§',
		 uml    => '¨',
		 ordf   => 'ª',
		 laquo  => '«',
		 not   => '¬',
		 shy    => '­',
		 macr   => '¯',
		 deg    => '°',
		 plusmn => '±',
		 sup1   => '¹',
		 sup2   => '²',
		 sup3   => '³',
		 acute  => '´',
		 micro  => 'µ',
		 para   => '¶',
		 middot => '·',
		 cedil  => '¸',
		 ordm   => 'º',
		 raquo  => '»',
		 frac14 => '¼',
		 frac12 => '½',
		 frac34 => '¾',
		 iquest => '¿',
		 times => '×',
		 divide => '÷',

		);

my $log;

sub trans {
  my ($html, $xwi, $opt) = @_;
  return undef unless ref $xwi;
  #$opt can be 'HTML', 'TEXT', 'GuessHTML', 'GuessText'
  $xwi->url_rewind;		# (BR)
  my $url = $xwi->url_get || return undef; # $xwi object must have url field
  if ( !defined($log) ) {
    $log = Combine::Config::Get('LogHandle');
  }
  if ($$html eq '') {
    $html = $xwi->content;
  }
  if ( length($$html) < 10 ) {
    $log->say('FromHTML: short or empty file');
    return $xwi;
  }
  if ( length($$html) > 1024 ) { # should we check shorter files as well ?
    my $teststring = substr($$html,0,1024);
    my $start_len = 1024;
    $teststring =~ s/[^\s\x20-\xfe]+//g;
    my $len = length($teststring);
    if ( $len > ( 0.9 * $start_len ) ) { # this is some kind of text
      my @rows = split(/\n/,$teststring);
      shift(@rows); 
      my ($i,$uu,$b64,$r);
      $uu=0; $b64=0;
      my $n = $#rows>10 ? 10 : $#rows;
      for ($i=0;$i<$n;$i++) {
	$r = shift(@rows);
	$uu++ if (length($r)==61) and (substr($r,0,1) eq "M");
	$b64++ if (length($r)==72) and ($r!~/\s/);
	if ( ( $uu == 10 ) or ( $b64 == 10 ) ) {
	  # this is probably uuencoded or base64 encoded
	  $log->say('FromHTML: probably uuencoded or base64 encoded');
	  return $xwi;
	}
      }
    } else {
      # this is most likely a binary file => don't parse it
      # DISABLED since it creates problems with certain charactersets
      #	   $log->say('FromHTML: most likely a binary file');
      #          return $xwi;
    }
  }

  $html = $$html;
  if ($xwi->truncated()) {
    my $last_blank = rindex($html, ' ');
    if ($last_blank > 0) {
      $html = substr($html, 0, $last_blank);
    } else {
      # What ! No blanks ! This is some weird text => don't parse it
      $log->say('FromHTML: No blanks - Not processing');
      return $xwi;
    }
  }

  if ( $opt =~ /^Guess/ ) {
    if ( ($url =~ /\..?html?$|\/$/i) || 
	 ($html =~ /<\s*html\s*|<\s*head\s*|<\s*body\s*/i) ) {
      $opt = 'HTML';
    } else {
      $opt = 'Text';
    }
  }

  if ($opt =~ /Text/i) {
    $html =~ s/[\s\240\n]+/ /sg; # compress whitespace??
    $xwi->text(\$html);
    return $xwi;
  }

  #clean character entities #1..#255 to utf-8/latin1
my $html_utf8;
  if (1) {
    my $c;
     $html_utf8=HTML::Entities::decode_entities($html);
  }

  my $rtext;
  ##Plugin for extracting only relevant text and discarding base templates
  my $relTextPlugin = Combine::Config::Get('relTextPlugin');
  if (defined($relTextPlugin) && $relTextPlugin ne '') {
    eval "require $relTextPlugin";
    $rtext = $relTextPlugin->extrText($html_utf8);
    if (defined($rtext)) {
      $xwi->text(\$rtext);
    }
  }
  ##

  #Only do for HTML files
  # General modifications to the HTML code before extracting our information

  if ( Combine::Config::Get('useTidy') ) {


    #	print "Doing Tidy\n";
    require HTML::Tidy;
    my $tidy = new HTML::Tidy ( {config_file => Combine::Config::Get('baseConfigDir') . '/tidy.cfg'} );
    #	$tidy->ignore( type => TIDY_WARNING );
    #	if (!eval{$html = $tidy->clean( $html . "\n" )}) { print "TIDY ERR in eval\n"; }
    my $thtml;
    if (!eval{$thtml = $tidy->clean( $html_utf8 . "\n" )}) {
      print "TIDY ERR in eval\n";
    }
    #	for my $message ( $tidy->messages ) {
    #	    print $message->as_string; #LOG!
    #	}
    $html = Encode::decode('UTF-8', $thtml); # convert to Perl internal representation
  } else {
    $html_utf8 =~ s/<\!\-\-.*?\-\->/ /sgo; # replace all comments (including multiline) with whitespace
    $html = $html_utf8;
  }
  if ( ! Encode::is_utf8($html) ) {
    $log->say('WARN HTML content not in UTF-8');
  }				##

  $html =~ s/<script.*?<\/script>/ /sigo; # remove all the scripts (including multiline)
  $html =~ s/<noscript.*?<\/noscript>/ /sigo; # remove all the scripts (including multiline)
  $html =~ s/<style.*?<\/style>/ /sigo;	# remove all the style scripts (including multiline)
  ##    $html =~ s/[\s\240]+/ /g; # compress whitespace

  my $xwicontent=$html;
  $xwi->content(\$xwicontent);

  #    #Split into HEAD and BODY
  #    my $head='';
  ##    if ($html =~ s|^(.*?)<\s*body\s*|<body |i) { #Does not work on ceratin frame-sets
  ## where the frameset is outside the <body> see http://poseidon.csd.auth.gr/EN/
  #    if ( $html =~ s|^(.*?<\s*\/head[^>]*>)||i ) { ???
  #	$head=$1;
  #    }

  #Parsing and extraction of data
  if ($html =~ /<title>([^<]+)<\/title>/i) { # extract title
    my $tmp = $1;
    #	$tmp =~ s/\s+/ /g;   #needed AA0?
    #	$tmp = HTML::Entities::decode_entities($tmp);
    $xwi->title($tmp);
  }    

  #Extract META tags
  while ( $html =~ m/<meta\s*(.*?)>/sgi ) {
    my $tag = $1;
    my $key='';
    my $val='';
    $tag =~ s/[\n\r]/ /g;
    foreach my $attr ('name','content') {
      my $str='';

      if ($tag =~ /$attr\s*=\s*[\"]/i) {
	if ($tag =~ s/$attr\s*=\s*\"([^\"]+?)\"//i) {
	  $str = $1;
	}
      } elsif ($tag =~ /$attr\s*=\s*[\']/i) {
	if ($tag =~ s/$attr\s*=\s*\'([^\']+?)\'//i) {
	  $str = $1;
	}
      } else {
	if ($tag =~ s/$attr\s*=\s*([^\s]+?)\s//i) {
	  $str = $1;
	}
      }
      next if($str =~ /^$/);
      if ($attr =~ /name/i) {
	$key=lc($str);
      } elsif ($attr =~ /content/i) {
	$val=$str;
      }
    }
    next if(($key =~ /^$/) || ($val =~ /^$/));
    #     $xwi->meta_add($key,HTML::Entities::decode_entities($val));
    $xwi->meta_add($key,$val);
  }
  #END extract META tags

=begin comment
This feature is temporarily disabled

	my $summary = "";
	$xwi->meta_rewind;
	my ($name,$content);
	while(1) {
	    ($name,$content) = $xwi->meta_get;
	    if (!defined($name)) { last; }

          #If abstract, description or DC.Description is not a list of keywords: add it to summary
	  if ( $name eq 'description' || $name eq 'dc.description' || $name eq 'abstract' ) {
	      my @kom = split(', ',$content);
	      my @dot = split(' ',$content);
	      if ( $#kom < $#dot ) { #If several meta-fields check if they overlap or are the same##
		  $summary .= $content . ' ';
	      }
	  }
	}

    #Generate Summary
	my $sumlength = Combine::Config::Get('SummaryLength');
#	print "SUM1: $summary\nHTML: $html\n";
	if ( $sumlength > 0 ) {
	    if ( ($sumlength - length($summary)) > 0 ) {
		require HTML::Summary;
		require HTML::TreeBuilder;
		my $html_summarizer = new HTML::Summary( LENGTH => $sumlength - length($summary), USE_META => 0 );
		my $tree = new HTML::TreeBuilder;
		$tree->parse( Encode::encode('latin1',$html) );
#		$tree->parse( $html );
		$tree->eof();
##		$summary .= $html_summarizer->generate ( $tree );
		my $t .= Encode::decode('latin1',$html_summarizer->generate ( $tree ));
		$tree = $tree->delete;
		$summary .= $t;
	    }
	    if (length($summary)>2) {
#		$summary =~ s/[^\w\s,\.\!\?:;\'\"]//gs;
		$summary =~ s/[^\p{IsAlnum}\s,\.\!\?:;\'\"]//gs;
		$summary =~ s/[\s\240]+/ /g;
		$xwi->meta_add("Rsummary",$summary);
	    }
	}

=end comment

=cut

  # extract links
  use Combine::HTMLExtractor;
  my ($alt, $linktext, $linkurl, $base);
  $base = $xwi->base;		#Set by UA.pm
  my $lx = new Combine::HTMLExtractor(undef,undef,1);
  #	print "INPUT: $html\n";
  #	$html = HTML::Entities::decode_entities( Encode::encode('latin1',$html) );
  $html = HTML::Entities::decode_entities( $html );
  $lx->parse(\$html);

  my %Tags = ( a => 1, area => 1, frame => 1, img => 1, headings => 1, text => 1 );
  for my $link ( @{$lx->links} ) {
    #	    print "GOTLINK: $$link{tag} = $$link{_TEXT}\n";
    next unless exists($Tags{$$link{tag}});
    my $linktext = $$link{_TEXT} ? $$link{_TEXT} : '';
    if ( ($$link{tag} eq 'headings') ) {
      if ( $linktext !~ /^\s*$/ ) {
	$linktext =~ s/^[\s;]+//;
	$linktext =~ s/[\s;]+$//;
	#		    $xwi->heading_add(Encode::decode('latin1',$linktext));
	$xwi->heading_add($linktext);
      }
      next;
    } elsif ( ($$link{tag} eq 'text') ) {
      if (!defined($rtext)) {
	#		$linktext = Encode::decode('latin1',$linktext);
	$linktext =~ s/[\s\240]+/ /g; # compress whitespace??
	$xwi->text(\$linktext);
#print "HT=$linktext\n";
      }
      next;
    } elsif ( ($$link{tag} eq 'frame') || ($$link{tag} eq 'img') ) {
      $linkurl = $$link{src};
      $linktext .= $$link{alt} || '';
    } else {
      $linkurl = $$link{href};
    }
    $linktext =~ s/\[IMG\]//g;
    if ( $linkurl !~ /^#/ ) {	# Throw away links within a document
      $linkurl =~ s/\?\s+/?/;	#to be handled in normalize??
      my $urlstr = URI->new_abs($linkurl, $base)->canonical->as_string;
      #		 $xwi->link_add($urlstr, 0, 0, Encode::decode('latin1',$linktext), $$link{tag});
      $xwi->link_add($urlstr, 0, 0, $linktext, $$link{tag});
      #                 print "ADD: $$link{tag}; $urlstr; |$linktext|\n";
    }
  }

  return $xwi;
}

1; 

__END__

=head1 NAME

Combine::FromHTML.pm - HTML parser in combine package

=head1 AUTHOR

Yong Cao <tsao@munin.ub2.lu.se> v0.06 1997-03-19
 Anders Ardø 1998-07-18 
   added <AREA ... HREF=link ...>
   fixed <A ... HREF=link ...> regexp to be more general
 Anders Ardö 2002-09-20
   added 'a' as a tag not to be replaced with space
   added removal of Cntrl-chars and some punctuation marks from IP
   added <style>...</style> as something to be removed before processing
   beefed up compression of sequences of blanks to include \240 (non-breakable space)
   changed 'remove head' before text extraction to handle multiline matching (which can be
      introduced by decoding html entities)
   added compress blanks and remove CRs to metadata-content
 Anders Ardö 2004-04
   Changed extraction process dramatically

=cut
