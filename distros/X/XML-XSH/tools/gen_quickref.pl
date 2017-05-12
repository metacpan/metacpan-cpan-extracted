#!/usr/bin/perl

# $Id: gen_quickref.pl,v 1.1 2003/05/06 13:46:09 pajas Exp $

use strict;
use XML::LibXML;
use Text::Wrap qw(wrap);

if ($ARGV[0]=~'^(-h|--help)?$') {
  print <<EOF;
Generates command usage reference text-file from RecDescentXML.

Usage: $0 <source.xml>

EOF
  exit;
}

my $parser=XML::LibXML->new();
$parser->load_ext_dtd(1);
$parser->validation(1);
$parser->keep_blanks(1);
my $doc=$parser->parse_file($ARGV[0]);

my $dom=$doc->getDocumentElement();
my ($rules)=$dom->findnodes('./rules');

my $ruledoc;
my $title;
my @aliases;
my @seealso;
my @usage;
my $desc;


print "This file was automatically generated with $0\nfrom $ARGV[0] on ",scalar(localtime),"\n";
print "-"x59;
print "\n";

my @rules=$rules->findnodes('./rule');

foreach my $r (sort { get_name($a) cmp get_name($b) } @rules) {
  my ($ruledoc)=$r->findnodes('./documentation');
  next unless $ruledoc;
  my $name=get_name($r);

  ($title)=$ruledoc->findnodes('./title');
  @usage=$ruledoc->findnodes('./usage');
  next unless @usage;
  print get_text($title),"\n\n" if ($title);
#    print "usage:       ";
  foreach (@usage) {
    my $usage=get_text($_);
    $usage=~s/\s+/ /;
    print $usage,"\n             ";
  }
#    print "\n";

  @aliases=grep {defined($_)} $r->findnodes('./aliases/alias');
  if (@aliases) {
    print "\nALIASES: ",join " ",map { get_name($_) } @aliases;
  }
  print "\n";
  print "-"x59;
  print "\n";
}

exit;

## ================================================

sub strip_space {
  my ($text)=@_;
  $text=~s/^\s*//;
  $text=~s/\s*$//;
  return $text;
}

sub get_name {
  my ($r)=@_;
  return $r->getAttribute('name') ne ""
    ? $r->getAttribute('name')
      : $r->getAttribute('id');
}

sub get_text {
  my ($node,$no_strip)=@_;
  my $text="";
  foreach my $n ($node->childNodes()) {
    if ($n->nodeType() == XML::LibXML::XML_TEXT_NODE ||
	$n->nodeType() == XML::LibXML::XML_CDATA_SECTION_NODE) {
      my $data=$n->getData();
      $data=~s/\t/  /g;
      $text.=$data;
    } elsif ($n->nodeType() == XML::LibXML::XML_ELEMENT_NODE) {
      if ($n->nodeName() eq 'link') {
	$text.="<".get_text($n,1).">";
      } elsif ($n->nodeName() eq 'xref') {
	$text.="<";
	my ($ref)=$node->findnodes("id('".$n->getAttribute('linkend')."')");
	if ($ref) {
	  $text.=get_name($ref);
	} else {
	  print STDERR "Reference to undefined identifier: ",$n->getAttribute('linkend'),"\n";
	}
	$text.=">";
      } elsif ($n->nodeName() eq 'typeref') {
	foreach (split /\s/,$n->getAttribute('types')) {
	  $text.=join ", ", sort map { get_name($_) } grep {defined($_)} $node->findnodes("//rules/rule[\@type='$_']");
	}
      } elsif ($n->nodeName() eq 'tab') {
	$text.="\t" x $n->getAttribute('count');
      } if ($n->nodeName() eq 'literal') {
	$text.="`".get_text($n,1)."'";
      } else {
	$text.=get_text($n);
      }
    }
  }
  return $no_strip ? $text : strip_space($text);
}

sub max { ($_[0] > $_[1]) ? $_[0] : $_[1] }
