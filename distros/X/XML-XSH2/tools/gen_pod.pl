#!/usr/bin/perl

# $Id: gen_pod.pl,v 2.3 2007-01-02 22:03:21 pajas Exp $

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

my $output;
sub pprint (@) { $output .= join '',@_ };

pprint "=for comment\n  This file was automatically generated from $ARGV[0]\n  on ",scalar(localtime),"\n";
pprint "\n=head1 NAME\n\nXSH - scripting language for XPath-based editing of XML\n\n";

foreach my $sec ($dom->findnodes('/recdescent-xml/doc/section')) {
  my $name=$sec->getAttribute('id');

  ($title)=$sec->findnodes('./title');
  my $t= $title ? get_text($title,0,2) : $name;
  pprint "\n=head1 ",uc($t),"\n\n";
  print_description($sec,"","");

  my @commands=$dom->findnodes("//rules/rule[\@type='command' and ".
			       "documentation[contains(\@sections,'$name')]]");
  if (@commands) {
    pprint "\n\n=head2 RELATED COMMANDS\n\n";
    pprint join ", ", sort map { get_name($_) }
	       @commands;
    pprint "\n\n";
  }

}

#pprint "\n=head1 COMMAND REFERENCE\n\n=over 5\n\n";
#foreach ($dom->findnodes("//rules/rule[\@type='command' and documentation]")) {
#  pprint "\n\n=item B<".get_name($_).">\n\n";
#  pprint get_text($_->findnodes('documentation/shortdesc'));
#}
#pprint "\n=back\n\n";

#pprint "\n=head1 ARGUMENT TYPES\n\n";
#pprint wrap("    ","    ",
#	   join ", ", sort map { get_name($_) } 
#	   grep {defined($_)} 
#	   $dom->findnodes("//rules/rule[\@type='argtype']")),
#  "\n\n";


pprint "\n=head1 COMMAND REFERENCE\n\n";

foreach my $r (sort {get_name($a) cmp get_name($b)} 
	       $rules->findnodes('./rule[@type="command"]')) {
  print_rule_desc($r);
}

pprint "\n=head1 ARGUMENT TYPE REFERENCE\n\n";
pprint "=over 4\n\n";

foreach my $r (sort {get_name($a) cmp get_name($b)} 
	       $rules->findnodes('./rule[@type="argtype"]')) {
  ($desc)=$r->findnodes('./documentation/description');
  if ($desc) {
    pprint "\n\n=item B<".get_name($r).">\n\n";
    print_description($desc,'','');
  }
}
pprint "\n\n=back\n\n";

pprint "\n=head1 XPATH EXTENSION FUNCTION REFERENCE\n\n";
foreach my $r (sort {get_name($a) cmp get_name($b)}
	       $rules->findnodes('./rule[@type="function"]')) {
  print_rule_desc($r);
}

pprint "\n";

pprint join "\n", map { /^:?(.*)/mg }  << 'POSTAMB'; # Hide pod from PAUSE indexer.

:=head1 AUTHOR

Petr Pajas, pajas@matfyz.cz

:=head1 SEE ALSO

L<xsh>, L<XML::XSH2>, L<XML::XSH2::Compile>, L<XML::LibXML>, L<XML::XUpdate>, L<http://xsh.sourceforge.net/doc>

:=cut

POSTAMB

# normalize lines
$output=~s/(\n[ \t]*){1,}\n/\n\n/sg;
# lazily fix nested B<...>
1 while $output=~s/(B<[^>]*)B<([^>]*)>([^>]*>)/$1$2$3/sg;
print($output);

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
  pprint "\n\n=head2 ",$name,"\n\n";
  pprint "\n\n=over 4\n\n";

  @usage=$ruledoc->findnodes('./usage');
  if (@usage) {
    pprint "\n\n=item Usage:\n\n";
    foreach (@usage) {
      my $usage=get_text($_);
      $usage=~s/\s+/ /;
      pprint $usage,"\n             ";
    }
    pprint "\n";
  }
  @aliases=grep {defined($_)} $r->findnodes('./aliases/alias');
  if (@aliases) {
    pprint "\n\n=item Aliases:\n\n";
    pprint join " ",map { get_name($_) } @aliases;
    pprint "\n\n";
  }
  ($desc)=$ruledoc->findnodes('./description');
  if ($desc) {
    pprint "\n\n=item Description:\n\n";
    print_description($desc,'','');
  }
  @seealso=grep {defined($_)} $ruledoc->findnodes('./see-also/ruleref');
  if (@seealso) {
    pprint "\n\n=item See also:\n\n";
    pprint join " ", grep {defined($_)}
      map { $_->getAttribute('ref') } @seealso;
    pprint "\n\n";
  }
  pprint "\n\n=back\n\n";
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
      $data=~s/([\/\|><])/"E<$enc{$1}>"/eg unless $noformat>1;
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
	  pprint STDERR "Reference to undefined identifier: ",$n->getAttribute('linkend'),"\n";
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

sub print_description {
  my ($desc)=@_;
  foreach my $c ($desc->childNodes()) {
    if ($c->nodeType == XML::LibXML::XML_ELEMENT_NODE) {
      my $name = $c->nodeName;
      if ($name eq 'title') {
	# handled per-case
      } elsif ($name eq 'para') {
	my $t=get_text($c);
	$t=~s/\s+/ /g;
	pprint $t,"\n\n";
      } elsif ($name eq 'section') {
	my ($title)=$c->findnodes('./title');
	if ($title) {
	  my $t=get_text($title);
	  pprint "\n\n=head2 $t\n\n";
	}
	print_description($c);
      } elsif ($name eq 'example') {
	foreach (map { get_text($_) } $c->findnodes('./title')) {
	  s/\s+/ /g;
	  pprint "Example: $_\n";
	}
	unless ($c->findnodes('./title')) {
	  pprint "Example:\n";
	}
	print_description($c);
      } elsif ($name eq 'code') {
      	pprint "\n";
	for (get_text($c,1,2)) {
 	  s/\n[ ]*/\n  /mg;
 	  s/\\\n/\\\n    /g;
 	  s/\t/  /g;
	  pprint "  $_\n";
	}
	pprint "\n";
      } elsif ($name eq 'enumerate') {
      	pprint "\n\n=over 4";
	my $i=1;
	foreach my $item ($c->findnodes('./listitem')) {
	  pprint "\n\n=item ",$i++,"\n\n";
	  print_description($item);
	}
	pprint "\n\n=back\n\n";
      } else {
	warn $0." no rule for tag ".$name."\n";
      }
    }
  }
}


