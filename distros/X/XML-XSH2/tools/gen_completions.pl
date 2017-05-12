#!/usr/bin/perl

# $Id: gen_completions.pl,v 2.1 2004-12-02 19:26:40 pajas Exp $

use strict;
use XML::LibXML;
use Text::Wrap qw(wrap);

if ($ARGV[0]=~'^(-h|--help)?$') {
  print <<EOF;
Generates a command-list module from RecDescentXML source.

Usage: $0 <source.xml>

EOF
  exit;
}

print <<'EOF';
package XML::XSH2::CompletionList;

use strict;
use vars qw(@XSH_COMMANDS @XSH_NOXPATH_COMMANDS);

@XSH_COMMANDS=qw(
EOF

sub get_name {
  my ($r)=@_;
  return $r->getAttribute('name') ne ""
    ? $r->getAttribute('name')
      : $r->getAttribute('id');
}

my $parser=XML::LibXML->new();
$parser->load_ext_dtd(1);
$parser->validation(1);
my $dom=$parser->parse_file($ARGV[0]);

my $doc=$dom->getDocumentElement();

foreach (sort map { get_name($_) }
	 $doc->findnodes('./rules/rule[@type="command"]'),
	 $doc->findnodes('./rules/rule[@type="command"]/aliases/alias')) {
  print "$_\n";
}

print ");\n\n1;\n";

