#!/usr/bin/perl -w

use lib qw(.);
use XML::LibXML;
use File::Basename qw(basename dirname);
use strict;

##--------------------------------------------------------------
## globals

##--------------------------------------------------------------
## help
if (grep {/^\-{1,2}(?:h|help)$/} @ARGV) {
  print STDERR "Usage: $0 [INFILE=- [OUTFILE=-]]\n";
  exit 0;
}


##--------------------------------------------------------------
## buffer xml doc
my $xmlfile   = @ARGV ? shift : '-';
my $prog      = basename($0).": $xmlfile";
my ($xmlbuf);
{
  local $/=undef;
  open(XML,"<$xmlfile") or die("$prog: ERROR: open failed for XML file '$xmlfile': $!");
  binmode(XML,":raw");
  $xmlbuf = <XML>;
  $xmlbuf =~ s|(<[^>]*\s)xmlns=|${1}XMLNS=|g;  ##-- remove default namespaces
  close XML;
}
my $xmlparser = XML::LibXML->new();
$xmlparser->line_numbers(1);
$xmlparser->keep_blanks(1);
$xmlparser->expand_entities(0);
my $xmldoc    = $xmlparser->parse_string($xmlbuf)
  or die("$prog: ERROR: could not parse XML file '$xmlfile': $!");
my $root = $xmldoc->documentElement;

##--------------------------------------------------------------
## MAIN

##-- xpath context (not really needed, since we use xpath hack)
my $xc = XML::LibXML::XPathContext ->new($root);
$xc->registerNs(($_->declaredPrefix||'DEFAULT'),$_->declaredURI) foreach ($root->namespaces);
$xc->registerNs('tei',($root->getNamespaceURI||'')) if (!$root->lookupNamespaceURI('tei'));

my $idfmt = 'seg2pn_%d_%d';
my ($id_i,$id_j) = (0,0);
my $n_updated = 0;
my ($seg,$line,@kids,@chain, $nod,$cur,$nxt, $pb1, $label);

my $all_segs = $xc->findnodes('//seg');
my $n_segs   = scalar(@$all_segs);

CHAIN:
foreach my $seg (@$all_segs) {
  ##-- check for and warn about ignored segs
  next if (!$seg->parentNode->isa('XML::LibXML::Element')); ##-- already removed
  $line = $seg->line_number;
  #print STDERR "$0: check //seg at line $line\n";
  @kids = @{$seg->findnodes('./*')};
  if (@kids==0) {
    warn("$prog: no child element for //seg at line $line: skipping");
    next;
  } elsif (@kids > 1) {
    warn("$prog: multiple child elements for //seg at line $line: skipping");
    next;
  } elsif ($kids[0]->nodeName ne 'note') {
    warn("$prog: cowardly ignoring non-\"note\" //seg/", $kids[0]->nodeName, " at line $line: skipping");
    next;
  } elsif (($seg->getAttribute('part')||'') ne 'I') {
    ##-- silently ignore non-initial segs here
    next;
  }

  ##-- now get down to it
  $nod  = $kids[0];
  $line = $nod->line_number;
  @chain = qw();
  $id_j = 0;
  push(@chain, $cur={
		     nod=>$nod,
		     pb1=>$nod->findnodes('following::pb[1]')->[0],
		     n=>($nod->getAttribute('n') || ''),
		     id=>($nod->getAttribute('xml:id') || $nod->getAttribute('id') || sprintf($idfmt,++$id_i,++$id_j)),
		    });
  ##-- sanity checks
  if (!$cur->{pb1}) {
    warn("$prog: no following::pb for //seg/note[\@n='$cur->{n}'] at line $line: skipping chain");
    next CHAIN;
  }
  elsif (!$cur->{n}) {
    warn("$prog: no \@n attribute for //seg/note at line $line: skipping chain");
    next CHAIN;
  }

 NODE:
  while (defined($nod=$cur->{nod}->findnodes('following::seg[string(@part)!="I"][1]/'.$cur->{nod}->nodeName)->[0])) {
    $line = $nod->line_number;
    push(@chain, $nxt={
		       nod=>$nod,
		       pb0=>$nod->findnodes('preceding::pb[1]')->[0],
		       pb1=>$nod->findnodes('following::pb[1]')->[0],
		       n=>($nod->getAttribute('n') || ''),
		       id=>($nod->getAttribute('xml:id') || $nod->getAttribute('id') || sprintf($idfmt,$id_i,++$id_j)),
		      });

    ##-- sanity check(s)
    if (!$nxt->{pb0} || !$nxt->{pb0}->isSameNode($cur->{pb1})) {
      warn("$prog: not exactly one intervening //pb for //seg/note[\@n='$nxt->{n}'] at line $line: skipping chain");
      next CHAIN;
    }
    elsif (!$cur->{n}) {
      warn("$prog: no \@n attribute for //seg/note at line $line: skipping chain");
      next CHAIN;
    }
    elsif ($cur->{n} ne $nxt->{n}) {
      warn("$prog: \@n attribute mismatch for //seg/note[\@n='$nxt->{n}'] at line $line: skipping chain");
      next CHAIN;
    }

    ##-- final $seg1 node: remove it too
    last NODE if (($nod->parentNode->getAttribute('part')||'F') eq 'F');

    ##-- update and continue
    $cur = $nxt;
  }

  ##-- if we get here, we have an intact chain in @chain
  $cur = undef;
  foreach $nxt (@chain) {
    ##-- convert to @prev|@next
    $nxt->{nod}->setAttribute('xml:id' => $nxt->{id});
    $nxt->{nod}->setAttribute('prev'   => '#'.$cur->{id}) if ($cur);
    $cur->{nod}->setAttribute('next'   => '#'.$nxt->{id}) if ($cur);

    ##-- remove parent //seg nodes
    $nxt->{nod}->parentNode->replaceNode($nxt->{nod});
    $cur = $nxt;
  }
  $n_updated += scalar(@chain);
}
print STDERR sprintf("$prog: INFO: removed %d of %d <seg> node(s) (%.2f %%)\n",
		     $n_updated, $n_segs, ($n_segs==0 ? 'nan' : (100*$n_updated/$n_segs)));


##--------------------------------------------------------------
## dump
$xmlbuf = $xmldoc->toString(0);
$xmlbuf =~ s|(<[^>]*\s)XMLNS=|${1}xmlns=|g;  ##-- restore default namespaces

##-- FW 2014-03-03: entity-encode all unicode characters beyond latin-1
utf8::decode( $xmlbuf );
$xmlbuf =~ s{([^\x{01}-\x{ff}])}{ sprintf "&#x%04X;", ord($1) }eg;
$xmlbuf =~ s{&#x017F;}{\x{017f}}g; ##-- ... except for long-s (U+017F)
utf8::encode( $xmlbuf );

my $outfile = @ARGV ? shift : '-';
open(OUT,">$outfile") or die("$prog: ERROR: open failed for '$outfile': $!");
binmode(OUT,":raw");
print OUT $xmlbuf;
close OUT or die("$prog: ERROR: failed to close output file '$outfile': $!");
