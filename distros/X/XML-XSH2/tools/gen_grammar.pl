#!/usr/bin/perl

# $Id: gen_grammar.pl,v 2.1 2004-12-02 19:26:40 pajas Exp $

use strict;
use XML::LibXML;

if ($ARGV[0]=~q(^(-h|--help)?$)) {
  print <<EOF;
Generates RecDescent grammar from RecDescentXML source.

Usage: $0 <source.xml>

EOF
  exit;
}

my $parser=XML::LibXML->new();
$parser->load_ext_dtd(1);
$parser->validation(1);
$parser->complete_attributes(1);
my $doc=$parser->parse_file($ARGV[0]);

my $dom=$doc->getDocumentElement();
my ($rules)=$dom->findnodes('./rules');
my ($preamb)=$dom->findnodes('./preamb');
my ($postamb)=$dom->findnodes('./postamb');

print "# This file was automatically generated from $ARGV[0] on \n# ",scalar(localtime),"\n";

print get_text($preamb,1);

foreach my $r ($rules->findnodes('./rule[@inline!="yes" and production]')) {
  print "\n  ",$r->getAttribute('id'),":\n\t   ";
  print join("\n\t  |",create_productions($r)),"\n";
}
print get_text($postamb,1);
print "\n";
exit;

## ================================================

sub strip_space {
  my ($text)=@_;
  $text=~s/^\s*//;
  $text=~s/\s*$//;
  return $text;
}

sub get_text {
  my ($node,$no_strip)=@_;
  my $text="";
  foreach ($node->childNodes()) {
    if ($_->nodeType() == XML::LibXML::XML_ELEMENT_NODE &&
	$_->nodeName() eq 'lineinfo') {
#      $text.='0,0,0,$XML::XSH2::Functions::SCRIPT'
      $text.='$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT';
    } elsif ($_->nodeType() == XML::LibXML::XML_TEXT_NODE ||
	$_->nodeType() == XML::LibXML::XML_CDATA_SECTION_NODE) {
      $text.=$_->getData();
    }
  }
  return $no_strip ? $text : strip_space($text);
}

sub find_rule {
  my ($r)=@_;
  return $r->findnodes('id("'.$r->getAttribute('ref').'")');
}

sub create_productions {
  my ($rule)=@_;
  return map {
    $_->nodeName() eq 'production' ?
      create_rule_production($rule,$_) : create_productions(find_rule($_))
      }
    $rule->findnodes('production|ruleref');
}

sub has_sibling {
  my ($node)=@_;
  return 0 unless $node;
  my$value=
    $node->find(
  '(following-sibling::*[name()!="action" and name()!="directive"]
    or
    not(following-sibling::*) and
    (parent::production/parent::group/following-sibling::*[name()!="action"
                                                           and name()!="directive"])
   )');
  return $value;
#   $node=$node->nextSibling();
#   while ($node) {
#     return 1 if ($node->nodeType == XML::LibXML::XML_ELEMENT_NODE
# 		 and
# 		 $node->nodeName ne 'action'
# 		 and
# 		 $node->nodeName ne 'directive'
# 		);
#     $node=$node->nextSibling();
#   }
#   return 0;
}

sub create_rule_production {
  my ($rule,$prod)=@_;
   my $result;
  my $name;
  foreach my $item ($prod->childNodes()) {
    next unless $item->nodeType == XML::LibXML::XML_ELEMENT_NODE;
    $name=$item->nodeName();
    if ($name eq 'lookahead') {
      $result.=' ...' . ($item->getAttribute('negative') eq 'yes' ? '!' : '');
    } elsif ($name eq 'regexp') {
      $result.=" /".get_text($item)."/".$item->getAttribute('mod');
    } elsif ($name eq 'directive') {
      my $text=get_text($item);
      my $type=$item->getAttribute('type');
      $type='error?' if ($type eq 'error-if-committed');
      $result.=" <".$type;
      $result.=":$text" if ($text ne "");
      $result.=">";
    } elsif ($name eq 'ruleref') {
      $result.=" ".$item->getAttribute('ref');
      if ($item->getAttribute('rep') ne '') {
	$result.="(".$item->getAttribute('rep').")";
      }
      if ($item->getAttribute('arguments') ne '') {
	$result.="[".$item->getAttribute('arguments')."]";
      }
    } elsif ($name eq 'string') {
      $result.=" '".get_text($item)."'";
    } elsif ($name eq 'action') {
      $result.="\n\t\t{ ".get_text($item,1)." }\n  \t";
    } elsif ($name eq 'group') {
      $result.="\n\t  " unless $result eq "";
      $result.="("
	     . join("\n\t  |",create_productions($item))
             . "\n\t   )";
      if ($item->getAttribute('rep') ne '') {
	$result.="(".$item->getAttribute('rep').")";
      }
    } elsif ($name eq 'selfref') {
      $result.=' /('
	.join("|", map { $_->getAttribute('regexp') ne "" ?
			   $_->getAttribute('regexp') :
			   $_->getAttribute('name')
		       }
	      $rule->findnodes('ancestor-or-self::rule'),
	      grep {defined($_)} $rule->findnodes("./aliases/alias"))
	. ')'
	. (($item->getAttribute('sep') ne 'no' and has_sibling($item)) ? '\b/' : '/');
    } elsif ($name eq 'paramlist') {
      $result.="\n\t  (( ";
      my $count = 0;
      foreach my $param ($item->childNodes()) {
	next unless
	  $param->nodeType == XML::LibXML::XML_ELEMENT_NODE
	  and $param->nodeName eq 'param';
	$result.="\n\t   | " if $count++;
	my $name=$param->getAttribute('name');
	my $short=$param->getAttribute('short');
	my $arg=$param->getAttribute('argument');
	my $type=$param->getAttribute('type');
	my $prefix=$param->getAttribute('prefix');
	my $shortprefix=$param->getAttribute('shortprefix');
	$result.='/'.$prefix.$name;
	$result.='|'.$shortprefix.$short if $short ne "";
	$result.='/';
	if ($arg ne '') {
	  $result.=' '.$arg." { [ '$type/$name' => \$item[2] ] }";
	} else {
	  $result.=" { [ '/$name' => 1 ] }";
	}
      }
      $result.="\n\t   )(s?) { [ map { \@\$_ } \@{\$item[1]} ] }\n\t  )\n";
#(( /:fold\s/                { [":fold" => 1] }
#           | /:encoding\s/ expression { [":encoding" => $item[2]] }
#           )(s)
#           { [ map { @$_ } @{$item[1]} ] })
    }
  }
  
  return $result;
}

