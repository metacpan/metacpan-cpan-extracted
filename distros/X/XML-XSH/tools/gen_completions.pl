#!/usr/bin/perl

# $Id: gen_completions.pl,v 1.5 2003/08/07 15:15:41 pajas Exp $

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
package XML::XSH::CompletionList;

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

print "\@XSH_NOXPATH_COMMANDS=qw(\n";

foreach my $r ($doc->findnodes(q{rules/rule[@type='command' and
                                 contains(@id,'_command') and
                                 not(production[*[2]/@type='commit' and contains(*[3]/@ref,'xpath')
   			             or contains(*[2]/@ref,'xpath') ])]})) {
  foreach (map { get_name($_) } $r,$r->findnodes('aliases/alias')) {
    s/([.?])/\\$1/;
    print "$_\n";
  }
}


print ");\n\n1;\n";
