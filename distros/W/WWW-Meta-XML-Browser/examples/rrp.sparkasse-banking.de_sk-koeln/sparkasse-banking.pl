#!/usr/local/bin/perl -w

use strict;

use WWW::Meta::XML::Browser;
use XML::LibXML;
use XML::LibXSLT;



my $term_readkey = 1;
eval "use Term::ReadKey;";
$term_readkey = 0 if $@;

my $kontonr = $ARGV[0];
if (!defined($kontonr)) {
	print "Bitte die Kontonummer eingeben: ";
	$kontonr = <STDIN>;
	chomp($kontonr);
}

my $pin = $ARGV[1];
if (!defined($pin)) {
	ReadMode('noecho') if $term_readkey;
	print "ACHTUNG! Die PIN wird auf dem Schirm ausgegeben, da Term::ReadKey nicht installiert ist.\n" if !$term_readkey;
	print "Bitte die PIN eingeben: \n";
	$pin = <STDIN>;
	chomp($pin);
	ReadMode(0) if $term_readkey;
}

my $browser = WWW::Meta::XML::Browser->new(
	args =>		{
					"kontonr"	=> $kontonr,
					"pin"		=> $pin
				},
	debug =>	1
);
$browser->process_file('sparkasse-banking.xml');
$browser->process_all_request_nodes();



my $xml_p = XML::LibXML->new();
my $xslt_p = XML::LibXSLT->new();

my $xml_doc = $browser->get_request_result(1,0);
my $xsl_doc = $xml_p->parse_file('umsatz2pbml.xsl');
my $stylesheet = $xslt_p->parse_stylesheet($xsl_doc);
my $result_doc = $stylesheet->transform($xml_doc);	

print $result_doc->toString();