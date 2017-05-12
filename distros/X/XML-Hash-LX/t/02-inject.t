#!/use/bin/perl -w

use strict;
use Test::More;
BEGIN {
	my $add = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; ++$add; 1 }
		or diag "Test::NoWarnings missed, skipping no warnings test";
	plan tests => 3 + $add;
}

use lib::abs '../lib';
use XML::LibXML;
use XML::Hash::LX ':inject';
use XML::Hash::LX ':inject'; # duplicate call shouldn't produce warning

our $xml = q{
	<root at="key">
		<nest>
			first
			<v>a</v>
			mid
			<v at="a">b</v>
			<vv></vv>
			last
		</nest>
	</root>
};

my $doc = XML::LibXML->new->parse_string($xml);
ok $doc->can('toHash'), 'doc->toHash';
ok $doc->documentElement->can('toHash'), 'elm->toHash';
ok ref $doc->toHash, 'hash';
