#!/usr/bin/perl

# $Id: gen_pod.pl,v 1.1 2003/08/11 15:08:51 pajas Exp $

use strict;
use vars qw(%enc);
use XML::LibXML;

if ($ARGV[0]=~'^(-h|--help)?$') {
  print <<EOF;
Generates POD documentation from RecDescentXML source.

Usage: $0 <source.xml>

EOF
  exit;
}

%enc=('>' => 'gt', '<' => 'lt', '/' => 'sol', '|' => 'verbar');
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


print "=for comment\n  This file was automatically generated from $ARGV[0]\n  on ",scalar(localtime),"\n";
print <<'PREAMB';

=head1 NAME

XSH (DEPRECATED) scripting language for XPath-based editing of XML

=head1 DEPRECATED

This module is deprecated, use XML::XSH2 instead.

PREAMB

foreach my $sec ($dom->findnodes('/recdescent-xml/doc/section')) {
  my $name=$sec->getAttribute('id');

  ($title)=$sec->findnodes('./title');
  my $t= $title ? get_text($title,0,1) : $name;
  print "\n=head1 ",uc($t),"\n\n";
  print_description($sec,"","");

  my @commands=$dom->findnodes("//rules/rule[\@type='command' and ".
			       "documentation[contains(\@sections,'$name')]]");
  if (@commands) {
    print "\n\n=head2 RELATED COMMANDS\n\n";
    print join ", ", sort map { get_name($_) }
	       @commands;
    print "\n\n";
  }

}

#print "\n=head1 COMMAND REFERENCE\n\n=over 5\n\n";
#foreach ($dom->findnodes("//rules/rule[\@type='command' and documentation]")) {
#  print "\n\n=item B<".get_name($_).">\n\n";
#  print get_text($_->findnodes('documentation/shortdesc'));
#}
#print "\n=back\n\n";

#print "\n=head1 ARGUMENT TYPES\n\n";
#print wrap("    ","    ",
#	   join ", ", sort map { get_name($_) } 
#	   grep {defined($_)} 
#	   $dom->findnodes("//rules/rule[\@type='argtype']")),
#  "\n\n";


print "\n=head1 COMMAND REFERENCE\n\n";

foreach my $r (sort {get_name($a) cmp get_name($b)} 
	       $rules->findnodes('./rule[@type="command"]')) {
  print_rule_desc($r);
}

print "\n=head1 ARGUMENT TYPE REFERENCE\n\n";
print "=over 4\n\n";

foreach my $r (sort {get_name($a) cmp get_name($b)} 
	       $rules->findnodes('./rule[@type="argtype"]')) {
  ($desc)=$r->findnodes('./documentation/description');
  if ($desc) {
    print "\n\n=item B<".get_name($r).">\n\n";
    print_description($desc,'','');
  }
}
print "\n\n=back\n\n";

print "\n";


exit;

## ================================================

sub print_rule_desc {
  my ($r)=@_;
  return unless $r;
  my ($ruledoc)=$r->findnodes('./documentation');
  return unless $ruledoc;
  my $name=get_name($r);
#  ($title)=$ruledoc->findnodes('./title');
#  my $t=$title ? get_text($title) : $name;
  print "\n\n=head2 ",$name,"\n\n";
  print "\n\n=over 4\n\n";

  @usage=$ruledoc->findnodes('./usage');
  if (@usage) {
    print "\n\n=item Usage:\n\n";
    foreach (@usage) {
      my $usage=get_text($_);
      $usage=~s/\s+/ /;
      print $usage,"\n             ";
    }
    print "\n";
  }
  @aliases=grep {defined($_)} $r->findnodes('./aliases/alias');
  if (@aliases) {
    print "\n\n=item Aliases:\n\n";
    print join " ",map { get_name($_) } @aliases;
    print "\n\n";
  }
  ($desc)=$ruledoc->findnodes('./description');
  if ($desc) {
    print "\n\n=item Description:\n\n";
    print_description($desc,'','');
  }
  @seealso=grep {defined($_)} $ruledoc->findnodes('./see-also/ruleref');
  if (@seealso) {
    print "\n\n=item See also:\n\n";
    print join " ", grep {defined($_)}
      map { $_->getAttribute('ref') } @seealso;
    print "\n\n";
  }
  print "\n\n=back\n\n";
}

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
  my ($node,$no_strip,$noformat)=@_;
  my $text="";
  foreach my $n ($node->childNodes()) {
    if ($n->nodeType() == XML::LibXML::XML_TEXT_NODE ||
	$n->nodeType() == XML::LibXML::XML_CDATA_SECTION_NODE) {
      my $data=$n->getData();
      $data=~s/\t/  /g;
      $data=~s/([\/\|><])/"E<$enc{$1}>"/eg unless $noformat;
      $text.=$data;
    } elsif ($n->nodeType() == XML::LibXML::XML_ELEMENT_NODE) {
      if (!$noformat and $n->nodeName() eq 'link') {
	$text.="B<".get_text($n,1,$noformat).">";
      } elsif (!$noformat and  $n->nodeName() eq 'xref') {
	$text.="B<";
	my ($ref)=$node->findnodes("id('".$n->getAttribute('linkend')."')");
	if ($ref) {
	  $text.=get_name($ref);
	} else {
	  print STDERR "Reference to undefined identifier: ",$n->getAttribute('linkend'),"\n";
	}
	$text.=">";
      } elsif (!$noformat and  $n->nodeName() eq 'typeref') {
	foreach (split /\s/,$n->getAttribute('types')) {
	  $text.=join ", ", sort map { get_name($_) } grep {defined($_)} $node->findnodes("//rules/rule[\@type='$_']");
	}
      } elsif ($n->nodeName() eq 'tab') {
	$text.="\t" x $n->getAttribute('count');
      }	elsif (!$noformat and $n->nodeName() eq 'userinput') {
	$text.="B<".get_text($n,1,$noformat).">";
      } elsif (!$noformat and $n->nodeName() eq 'literal') {
	$text.="B<".get_text($n,1,$noformat).">";
      } else {
	$text.=get_text($n,$no_strip,$noformat);
      }
    }
  }
  return $no_strip ? $text : strip_space($text);
}

sub max { ($_[0] > $_[1]) ? $_[0] : $_[1] }

sub  print_description {
  my ($desc,$indent,$bigindent)=@_;
  foreach my $c ($desc->childNodes()) {
    if ($c->nodeType == XML::LibXML::XML_ELEMENT_NODE) {
      if ($c->nodeName eq 'para') {
	my $t=get_text($c);
	$t=~s/\s+/ /g;
	print $t,"\n\n";
	$indent=$bigindent;
      } elsif ($c->nodeName eq 'section') {
	my ($title)=$c->findnodes('./title');
	if ($title) {
	  my $t=get_text($title);
	  print "\n\n=head2 $t\n\n";
	}
	print_description($c,$indent,$bigindent);
      } elsif ($c->nodeName eq 'example') {
	foreach (map { get_text($_) } $c->findnodes('./title')) {
	  s/\s+/ /g;
	  print "Example: $_\n";
	}
	unless ($c->findnodes('./title')) {
	  print "Example:\n";
	}
	print "\n";
	foreach (map { get_text($_,1,1) } $c->findnodes('./code')) {
 	  s/\n[ ]*/\n  /mg;
 	  s/\\\n/\\\n    /g;
 	  s/\t/  /g;
	  print "  $_\n";
	}
	print "\n";
      }
    }
  }
}

print <<'POSTAMB';

=head1 AUTHOR

Petr Pajas, pajas@matfyz.cz

=head1 SEE ALSO

L<xsh>, L<XML::XSH>, L<XML::LibXML>, L<XML::XUpdate>, L<http://xsh.sourceforge.net/doc>

=cut

POSTAMB
