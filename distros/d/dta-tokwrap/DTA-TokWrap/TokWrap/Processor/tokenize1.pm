## -*- Mode: CPerl; coding: utf-8 -*-

## File: DTA::TokWrap::Processor::tokenize1.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: tokenizer: post-processing hacks

package DTA::TokWrap::Processor::tokenize1;

use DTA::TokWrap::Version;  ##-- imports $VERSION, $RCDIR
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :slurp :time);
use DTA::TokWrap::Processor;
use DTA::TokWrap::Processor::tokenize;

use Encode qw(encode decode);
use Carp;
use strict;

no bytes;
use utf8;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor::tokenize);

##==============================================================================
## Constructors etc.
##==============================================================================

## $tp = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + static class-dependent defaults
##  + %args, %defaults, %$tp:
##    fixtok => $bool,                     ##-- attempt to fix common tokenizer errors? (default=true)
##    tokpp  => $bool,                     ##-- add tokenizer-supplied analyses with Moot::TokPP (default=false)
##    fixold => $bool,                     ##-- attempt to fix unexpected and/or obsolete (tomata2) errors? (default=false)
sub defaults {
  my $that = shift;
  return (
	  $that->DTA::TokWrap::Processor::defaults(),
	  fixtok => 1,
	  tokpp  => 0,
	  fixold => 0,
	 );
}

## $tp = $tp->init()
sub init {
  my $tp = shift;

  ##-- defaults
  $tp->{fixtok} = 1 if (!exists($tp->{fixtok}));
  $tp->{tokpp}  = 0 if (!exists($tp->{tokpp}));
  $tp->{fixold} = 0 if (!exists($tp->{fixold}));

  return $tp;
}

##==============================================================================
## Utilities
##==============================================================================


##==============================================================================
## Methods
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->tokenize1($doc)
## + $doc is a DTA::TokWrap::Document object
## + %$doc keys:
##    tokdata0 => $tokdata0, ##-- (input)  raw tokenizer output (string)
##    tokdata1 => $tokdata1, ##-- (output) post-processed tokenizer output (string)
##    tokenize1_stamp => $f, ##-- (output) timestamp of operation end
##    tokdata1_stamp  => $f, ##-- (output) timestamp of operation end
## + may implicitly call $doc->tokenize()
sub tokenize1 {
  my ($tp,$doc) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $tp = $tp->new if (!ref($tp));
  $tp->vlog($tp->{traceLevel},"tokenize1(): fixtok=".($tp->{fixtok} ? 1 : 0), "; fixold=".($tp->{fixold} ? 1 : 0), "; tokpp=".($tp->{tokpp} ? 1 : 0));
  $doc->{tokenize1_stamp0} = timestamp();

  ##-- sanity check(s)
  #(none)

  ##-- get token data
  my $tdata0r = \$doc->{tokdata0};
  if (!defined($$tdata0r)) {
    $tdata0r = $doc->loadTokFile0()
      or $tp->logconfess("tokenize1(): could not load raw tokenizer data (*.t0)");
  }

  ##-- auto-fix?
  if (!$tp->{fixtok} && !$tp->{fixold} && !$tp->{tokpp}) {
    $doc->{tokdata1} = $$tdata0r; ##-- just copy
  }
  else {
    my $data = $$tdata0r;
    utf8::decode($data) if (!utf8::is_utf8($data));
    my @lines = split(/\n/,$data);
    my ($fh,$off);
    my ($s_str, $s_txt,$s_off,$s_len,$s_rest);
    my ($ol_off,$ol_len);
    my ($nsusp,$nfixed, $i,$j);

    ##------------------------------------
    ## fix/tokpp: pseudo-morpholgy
    if ($tp->{tokpp}) {
      $tp->vlog($tp->{traceLevel},"autofix/tokpp: pseudo-morphology");
      require Moot::TokPP;
      my $tokpp = Moot::TokPP->new();
      my $npp   = 0;
      my ($ppa);
      foreach (@lines) {
	next if (/^$/ || /^%%/);
	($s_txt,$s_off,$s_rest) = split(/\t/,$_,3);
	if (!$s_rest && defined($ppa=$tokpp->analyze_text($s_txt))) {
	  $_ .= $ppa;
	  ++$npp;
	}
      }
      $tp->vlog($tp->{traceLevel},"autofix/tokpp: analyzed $npp token(s)");
    }

    ##------------------------------------
    ## fix: overlap
    if ($tp->{fixtok}) {
      $tp->vlog($tp->{traceLevel},"autofix: token overlap");
      $nsusp = $nfixed = $off = 0;
      my $ndel = 0;
      foreach (@lines) {
	if (/^([^\t]*)\t([0-9]+) ([0-9]+)(.*)$/) {
	  ($s_txt,$s_off,$s_len,$s_rest) = ($1,$2,$3,$4);
	  if ($s_off < $off) {
	    ($ol_off,$ol_len) = ($s_off,$s_len);
	    $s_len = $ol_off+$ol_len - $off;
	    $s_off = $off;
	    #print STDERR "  - OVERLAP[off=$off]: ($s_txt \@$ol_off.$ol_len :$s_rest) --> ", ($s_len <= 0 ? 'DELETE' : "TRUNCATE"), "\n";
	    if ($s_len <= 0) {
	      ++$ndel;
	      $_ = undef;
	    } else {
	      ++$nfixed;
	      $_ = "$s_txt\t$s_off $s_len$s_rest";
	    }
	  }
	  $off = $s_off+$s_len;
	}
      }
      @lines = grep {defined($_)} @lines if ($ndel);
      $tp->vlog($tp->{traceLevel},"autofix: token overlap: $nfixed truncation(s), $ndel deletion(s)");
    }

    ##------------------------------------
    ## fix: trailing commas
    if ($tp->{fixtok}) {
      $tp->vlog($tp->{traceLevel},"autofix: trailing commas");
      $nsusp = $nfixed = 0;
      foreach (@lines) {
	if (/^(\d+)\,\t([0-9]+) ([0-9]+)(?:\t.*)?$/) {
	  ($s_txt,$s_off,$s_len) = ($1,$2,$3);
	  $_ = ("$s_txt\t$s_off ".($s_len-1)."\t[CARD]\n"
		.",\t".($s_off+$s_len-1)." 1\t[\$,]");
	  ++$nfixed;
	}
      }
      $tp->vlog($tp->{traceLevel},"autofix: trailing commas: $nfixed fix(es)");
    }

    ##------------------------------------
    ## fix/old: stupid interjections
    if ($tp->{fixold}) {
      $tp->vlog($tp->{traceLevel},"autofix/old: re/ITJ");
      $nsusp = $nfixed = 0;
      foreach (@lines) {
	++$nfixed if (s/^(re\t\d+ \d+)\tITJ$/$1/);
      }
      $tp->vlog($tp->{traceLevel},"autofix/old: re/ITJ: ", ($nfixed+0), " fix(es)");
    }


    ##------------------------------------
    ## fix/old: tokenized $WB$, $SB$ (mantis bug #548)
    if ($tp->{fixold}) {
      $tp->vlog($tp->{traceLevel},"autofix/old: \${WB,SB}\$");
      $nfixed = 0;
      foreach (@lines) {
	#++$nfixed if (s/^\$[WS]B\$_?\t.*$//);	##-- e.g. "$SB$\tOFF LEN\t[XY]\t[$ABBREV]\n"
	++$nfixed if (!/^%%/ && s/^[^\t]*\$[WS]B\$.*$//);	##-- e.g. "O$SB$\tOFF LEN\t[XY]\t[$ABBREV]\n"
      }
      $tp->vlog($tp->{traceLevel},"autofix/old: \${WB,SB}\$: ", ($nfixed+0), " fix(es)");
    }

    ##------------------------------------
    ## fix/old: bogus trailing underscore (also in mantis bug #548)
    ##  + Thu, 04 Oct 2012 11:09:29 +0200: read line-wise from temporary fh to avoid
    ##    weird perfomance hit from simple regex ($data=~/^[^\t\n_]_\t.*\n/mg)
    if ($tp->{fixold}) {
      $tp->vlog($tp->{traceLevel},"autofix/old: *_/\$ABBREV");
      $nsusp = $nfixed = 0;
      foreach (@lines) {
	if (m/^([^\t]*)_\t([0-9]+) ([0-9]+)(\t.*)?$/) {
	  ($s_txt,$s_off,$s_len,$s_rest) = ($1,$2,$3,$4);
	  ++$nsusp;
	  if ($s_rest =~ /(?:\t\[(?:XY|\$ABBREV)\]){2,}/) {
	    $_ = "$s_txt\t$s_off ".($s_len-1)."\n";
	    ++$nfixed;
	  }
	}
      }
      $tp->vlog($tp->{traceLevel},"autofix/old: *_/\$ABBREV: $nsusp suspect(s), $nfixed fix(es)");
    }

    ##------------------------------------
    ## fix/old: line-broken tokens, part 1: get list of suspects
    ## NOTE:
    ##  + we do this fix in 2 passes to allow some fine-grained checks (e.g. %nojoin_txt2)
    ##  + also, at least 1 dta file (kurz_sonnenwirth_1855.xml) caused the original single-regex
    ##    implementation to choke (or at least to churn cpu cycles for over 5 minutes without
    ##    producing any results, for some as-yet-undetermined reason)
    ##  + the 2-pass approach using a simpler regex for the large buffer and the @-, @+ arrays
    ##    rather then ()-groups, but doesn't cause the same race-condition-like behavior... go figure
    ## -moocow Wed, 04 Aug 2010 13:37:25 +0200
    ##
    ## + hypens we might want to pay attention to:
    ##   CP_HEX   CP_DEC LEN_U8   CHR_L1     CHR_U8_C         BLOCK                   NAME
    ##   U+002D       45      1        -            -         Basic Latin             HYPHEN-MINUS
    ##   U+00AC      172      2        ¬      \xc2\xac        Latin-1 Supplement      NOT SIGN
    ##   U+2014     8212      3       [?] \xe2\x80\x94        General Punctuation     EM DASH
    ##    -- this is not really a connector, but it might be used somewhere!
    my ($txt1,$off1,$len1,$rest1, $txt2,$off2,$len2,$rest2, @repl);
    if ($tp->{fixold}) {
      $tp->vlog($tp->{traceLevel},"autofix/old: linebreak: scan");
      my %nojoin_txt2 = map {($_=>undef)} qw(und vnd unnd vnnd nnd oder als wie noch sondern ſondern u. o. bis);
      $nsusp=$nfixed=0;
      for ($i=0; $i < $#lines; ++$i) {
	if ($lines[$i] =~ /^
			   [[:alpha:]\'\-\x{ac}]*		##-- w1.text [modulo final "-"]
			   [\-\x{ac}]			##--   : w1.final "-"
			   \t.*				##--   : w1.rest
			   $				##--   : EOT (w1 . EOS? w2)
			  /x

	    && defined($j=$i+($lines[$i+1] =~ /^$/
			      ? 2				##--  EOS (w1 EOS . w2)
			      : 1))			##-- !EOS (w2     . w2)
	    && $j <= $#lines

	    && $lines[$j] =~ /^
			      [[:alpha:]\'\-\x{ac}]*	##-- w2.text [modulo final "."]
			      \.?				##--   : w2.text: final "." (optional)
			      \t.*			##--   : w2.rest
			      $				##--   : EOT (w1 EOS? w2 .)
			     /x
	   ) {
	  ++$nsusp;

	  ##-- parse: w1
	  next if ($lines[$i] !~ m/^([^\t\n]*)		##-- $1: w1.txt
				   \t([0-9]+)\ ([0-9]+)	##-- ($2,$3): (w1.off, w1.len)
				   (.*)$			##-- $4: w1.rest
				  /x);
	  ($txt1,$off1,$len1,$rest1)=($1,$2,$3,$4);

	  ##-- parse: w2
	  next if ($lines[$j] !~ m/^([^\t\n]*)		##-- $1: w2.txt
				   \t([0-9]+)\ ([0-9]+)	##-- ($2,$3): (w2.off, w2.len)
				   (.*)$			##-- $4: w2.rest
				  /x);
	  ($txt2,$off2,$len2,$rest2) = ($1,$2,$3,$4);

	  ##-- skip vowel-less w1
	  next if ($txt1 !~ /[aeiouäöüy]/);

	  ##-- skip common conjunctions as w2
	  next if (exists($nojoin_txt2{$txt2})); # || $txt2 =~ /\.$/

	  ##-- skip upper-case and vowel-less w2
	  next if ($txt2 =~ /[[:upper:]]/ || $txt2 !~ /[aeiouäöüy]/);

	  ##-- check for abbrevs
	  @repl = qw();
	  if ($txt2 =~ /\.$/ && $rest2 =~ /\bXY\b/) {
	    @repl = (
		     (substr($txt1,0,-1).substr($txt2,0,-1)."\t$off1 ".(($off2+$len2)-$off1-1)),
		     (".\t".($off2+$len2-1)." 1\t\$."),
		    );
	  } elsif ($rest2 =~ /^(?:\tTRUNC)?$/) {
	    @repl = (
		     substr($txt1,0,-1).$txt2."\t$off1 ".(($off2+$len2)-$off1)."$rest2"
		    );
	  }

	  ##-- DEBUG
	  #print STDERR "  - SUSPECT: ($txt1 \@$off1.$len1 :$rest1)  +  ($txt2 \@$off2.$len2 :$rest2)  -->  ".(@repl ? join(" + ",map {"($_)"} @repl)."\n" : "IGNORE\n");
	  if (@repl) {
	    splice(@lines, $i, (1+$j-$i), @repl);
	    ++$nfixed;
	  }
	}
      }
      $tp->vlog($tp->{traceLevel},"autofix/old: linebreak: $nsusp suspect(s), $nfixed fix(es)");
    }

    ##------------------------------------
    ## fix: pre-numeric abbreviations (e.g. biblical books), part 1: collect suspects
    if ($tp->{fixtok}) {
      $tp->vlog($tp->{traceLevel},"autofix: pre-numeric abbreviations: scan");
      my %nabbrs   = (map {($_=>undef)}
		      qw( Bar Dan Deut Esra Eſra Est Eſt Ex Galater Man Hos Hoſ Ijob Job Jak Col Kor Cor Mal Ri Sir ),
		      #qw( Mark ), ##-- heuristics too dodgy
		      qw( Art Bon Kim ),
		      ##-- more bible books
		      qw( Gall Reg Hos Hoſ Hose Hoſe Rom Reg ),
		      qw( Joel Johan Johann Malach Eze Esa Eſa Sap ),
		      ##-- other stuff that fits here
		      qw( Idiot idiot ),
		     );
      my ($offd,$lend);
      my $nabbr_max_distance = 2; ##-- max number of text bytes between end(w1) and start(w2), including EOS-dot
      $nsusp=$nfixed=0;
      for ($i=0; $i <= ($#lines-3); ++$i) {
	if (
	    ##-- parse: w1
	    $lines[$i] =~ m/^([^\t]*)			##-- $1: w1.txt
			    \t([0-9]+)\ ([0-9]+)		##-- ($2,$3): (w1.off, w1.len)
			    (.*)				##-- $4: w1.rest
			    $				##-- w1.EOT
			   /x
	    && (($txt1,$off1,$len1,$rest1)=($1,$2,$3,$4))

	    ##-- parse: dot
	    && $lines[$i+1] =~ m/^\.			##-- dot:"."
				 \t([0-9]+)\ ([0-9]+)	##-- ($1,$2): (dot.off, dot.len)
				 (?:.*)			##-- (-): dot.rest
				 $			##-- dot.EOT
				/x
	    && (($offd,$lend)=($1,$2))

	    ##-- parse: EOS
	    && $lines[$i+2] =~ m/^$/ ##-- EOS

	    ##-- parse: w2
	    && $lines[$i+3] =~ m/^([0-9][^\t]*)		##-- $1: w2.txt (beginning with arabic numeral)
				 \t([0-9]+)\ ([0-9]+)	##-- ($2,$3): (w2.off, w2.len)
				 (.*)			##-- $4: w2.rest
				 $			##-- w2.EOT
				/x
	    && (($txt2,$off2,$len2,$rest2)=($1,$2,$3,$4))
	   ) {
	  ++$nsusp;

	  ##-- check for known pre-numeric abbrevs
	  @repl = qw();
	  if (exists($nabbrs{$txt1}) && ($off2-($off1+$len1)) <= $nabbr_max_distance) {
	    ++$nfixed;
	    splice(@lines, $i, 4,
		   @repl = (
			    ("$txt1.\t$off1 ".(($offd+$lend)-$off1)."\tXY\t\$ABBREV"),
			    ("$txt2\t$off2 $len2$rest2"),
			   ));
	  }

	  ##-- DEBUG
	  #print STDERR "  - NABBR: ($txt1 \@$off1.$len1 :$rest1) + . + EOS +  ($txt2 \@$off2.$len2 :$rest2)  -->  ".(@repl ? join(" + ", map {"($_)"} @repl) : "IGNORE")."\n" if (@repl);
	}
      }
      $tp->vlog($tp->{traceLevel},"autofix: pre-numeric abbreviations: $nsusp suspect(s), $nfixed fix(es)");
    }

    ##------------------------------------
    ## finalize: write data back to doc (encoded)
    $tp->vlog($tp->{traceLevel},"autofix: recode");
    $doc->{tokdata1} = join("\n", @lines)."\n\n";
    utf8::encode($doc->{tokdata1}) if (utf8::is_utf8($doc->{tokdata1}));
  }
  ##-- /ifelse:fixtok | fixold

  ##-- finalize
  $doc->{ntoks} = $tp->nTokens(\$doc->{tokdata1});
  $doc->{tokfile1_stamp} = $doc->{tokenize1_stamp} = $doc->{tokdata1_stamp} = timestamp(); ##-- stamp
  return $doc;
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::tokenize1 - DTA tokenizer wrappers: tokenizer post-processing

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::tokenize1;
 
 $tp = DTA::TokWrap::Processor::tokenize1->new(%args);
 $doc_or_undef = $tp->tokenize1($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Processor::tokenize1 provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for post-processing of raw tokenizer output
for L<DTA::TokWrap::Document|DTA::TokWrap::Document> objects.

Most users should use the high-level
L<DTA::TokWrap|DTA::TokWrap> wrapper class
instead of using this module directly.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tokenize1: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::tokenize1
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tokenize1: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $tp = $CLASS_OR_OBJ->new(%args);

%args, %$tp:

 fixtok => $bool,  ##-- attempt to fix common tokenizer errors? (default=true)
 fixold => $bool,  ##-- attempt to fix unexpected and/or obsolete (tomata2) errors? (default=false)


=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tokenize1: Methods
=pod

=head2 Methods

=over 4

=item tokenize1

 $doc_or_undef = $CLASS_OR_OBJECT->tokenize1($doc);

Runs the low-level tokenizer on the
serialized text from the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object $doc.

Relevant %$doc keys:

  tokdata0 => $tokdata0,  ##-- (input)  raw tokenizer output (string)
  tokdata1 => $tokdata1,  ##-- (output) post-processed tokenizer output (string)
  tokenize1_stamp => $f,  ##-- (output) timestamp of operation end
  tokdata1_stamp  => $f,  ##-- (output) timestamp of operation end

may implicitly call $doc-E<gt>tokenize()
(but shouldn't).

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


