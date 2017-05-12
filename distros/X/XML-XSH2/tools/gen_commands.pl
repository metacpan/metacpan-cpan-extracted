#!/usr/bin/perl

# $Id: gen_commands.pl,v 2.3 2007-11-13 21:54:18 pajas Exp $

use strict;
use XML::LibXML;

if ($ARGV[0]=~'^(-h|--help)?$') {
  print <<EOF;
Generates XSH commands specifications RecDescentXML source.

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

print "# This file was automatically generated from $ARGV[0] on \n# ",scalar(localtime),"\n";

print "package XML::XSH2::Functions;\n\n";
print "%COMMANDS = (\n";
foreach my $r ($rules->findnodes('./rule[command]')) {
  print_command($r);
}
print ");\n\n1;\n";

exit;

## ================================================

sub print_command {
  my ($rule) = @_;
  my $name = $rule->getAttribute('name');
  foreach ($rule->findnodes(q{aliases/alias/@name})) {
    print "'",$_->value(),"' => '$name',\n";
  }
  my ($cmd) = $rule->findnodes(q{command});
  print "'$name' => [";
#  print "\\\&",$cmd->getAttribute('func');
  print "'",$cmd->getAttribute('func'),"'";
  print ", ",($cmd->getAttribute('minargs') ne "" ? $cmd->getAttribute('minargs') : 0);
  print ", ",($cmd->getAttribute('maxargs') ne "" ? $cmd->getAttribute('maxargs') : "undef");
  my @params = $cmd->findnodes(q{param});
  if (@params) {
    print ",\n\t{\n\t";
    foreach my $param (@params) {
      if ($param->getAttribute('short') ne "") {
	print " '".$param->getAttribute('short')."' => '",
	  $param->getAttribute('name')
	  ,"',\n\t";
	print " '".$param->getAttribute('name')."' => ",
	  ($param->getAttribute('argument') ne "" ? "'".$param->getAttribute('type')."'" 
	   : "''"),",\n\t";
      }
    }
    print "}"
  } else {
    print ",undef";
  }
  if ($cmd->getAttribute('extraargs') ne "") {
    print ", ".$cmd->getAttribute('extraargs');
  }
  print "],\n";
}

