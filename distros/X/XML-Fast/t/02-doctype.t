#!/use/bin/perl -w

use strict;
use Test::More;
BEGIN {
	my $add = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; ++$add; 1 }
		or diag "Test::NoWarnings missed, skipping no warnings test";
	plan tests => 3 + $add;
	
	eval {require Data::Dumper;Data::Dumper::Dumper(1)}
		and *dd = sub ($) { Data::Dumper->new([$_[0]])->Indent(0)->Terse(1)->Quotekeys(0)->Useqq(1)->Purity(1)->Dump }
		or  *dd = \&explain;
}

use XML::Fast 'xml2hash';

# Parsing

my $xml0 = q{<!DOCTYPE>};
my $xml1 = q{<?xml?>
	<!DOCTYPE greeting [
		<!ELEMENT greeting (#PCDATA)>
	]>
	<greeting>Hello!</greeting>
};
my $xml2 = q{<?xml?><!DOCTYPE test><greeting>Hello!</greeting>};

our $data;
{
	is_deeply
		$data = xml2hash($xml0),
		{},
		'doctype 0'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1),
		{ greeting => 'Hello!' },
		'doctype 1'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml2),
		{ greeting => 'Hello!' },
		'doctype 2'
	or diag dd($data),"\n";
}
