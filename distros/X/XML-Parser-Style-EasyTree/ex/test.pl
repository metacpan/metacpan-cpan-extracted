#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use XML::Parser;
use Data::Dumper;

our $parser = XML::Parser->new( Style => 'ETree' );

$Data::Dumper::Indent = 1;
$Data::Dumper::Useqq = 1;

# xml to hash options
$XML::Parser::Style::ETree::TEXT{TRIM}  = 0;    # don't trim whitespace
$XML::Parser::Style::ETree::TEXT{ATTR}  = '+';  # make attributes as keys with prefix '+';
$XML::Parser::Style::ETree::TEXT{NODE}  = '~';  # make text node as key '~';
$XML::Parser::Style::ETree::TEXT{JOIN}  = ' ';  # join all whitespaces with ' ';

# array cast
$XML::Parser::Style::ETree::FORCE_ARRAY{nest} = 1;     # node with name 'nest' should be always stored as array
#$XML::Hash::LX::X2A = 1;         # all nodes should be always stored as array
#$XML::Hash::LX::X2H{order}  = 1; # keep order strictly

my $hash = $parser->parse(
	q{<root at="key">
		<nest>
			<!-- something commented -->
			first
			<v>a</v>
			mid
			<!-- something commented -->
			<v at="a">b</v>
			<vv><![CDATA[ cdata <<>> content ]]></vv>
			last
		</nest>
	</root>},
);
print +Dumper $hash;

