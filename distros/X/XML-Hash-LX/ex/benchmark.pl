#!/usr/bin/env perl

use lib::abs '../lib';
use XML::Hash::LX;
use XML::Hash;
use XML::Simple;
use XML::Twig;
use XML::Bare;
use Benchmark qw(:all);
use Data::Dumper;

my $xml_converter = XML::Hash->new();
#my $twig = XML::Twig->new();
my $xml = do 'xml.pl';
my $xh_hash = $xml_converter->fromXMLStringtoHash($xml);
my $lx_hash = xml2hash($xml);
my $xs_hash = XMLin($xml);

=for rem
cmpthese timethese 1000, {
	'Bare' => sub {
		my $root = XML::Bare->new( text => $xml )->parse;
	},
	'Hash' => sub {
		my $xml_hash = $xml_converter->fromXMLStringtoHash($xml);
	},
	'Twig' => sub {
		XML::Twig->new()->parse($xml);
	},
	'Simple' => sub {
		my $xml_hash = XMLin($xml);
	},
	'Hash::LX' => sub {
		my $xml_hash = xml2hash($xml);
	},
};
=for rem
=cut

#=for rem
cmpthese timethese 100, {
	'Hash' => sub {
		my $oxml = $xml_converter->fromHashtoXMLString($xh_hash);
	},
	'Simple' => sub {
		my $oxml = XMLout($xs_hash);
	},
	'Hash::LX' => sub {
		my $oxml = hash2xml($lx_hash);
	},
};
=for rem
=cut
