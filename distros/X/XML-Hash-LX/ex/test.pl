#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
#BEGIN{ $XML::LibXML::Hash::X2H{trim} = 0; }

use XML::Hash::LX;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Useqq = 1;

# xml to hash options
$XML::Hash::LX::X2H{trim}  = 0;    # don't trim whitespace
$XML::Hash::LX::X2H{attr}  = '+';  # make attributes as keys with prefix '+';
$XML::Hash::LX::X2H{text}  = '~';  # make text node as key '~';
#$XML::Hash::LX::X2H{join}  = ' ';  # join all whitespaces with ' ';
#$XML::Hash::LX::X2H{join}  = undef;# don't join text nodes
$XML::Hash::LX::X2H{cdata} = '#';  # separate cdata sections from common values and save it under key '#';
$XML::Hash::LX::X2H{comm}  = '//'; # keep comments and store under key '//';

# array cast
$XML::Hash::LX::X2A{nest} = 1;     # node with name 'nest' should be always stored as array
#$XML::Hash::LX::X2A = 1;         # all nodes should be always stored as array
#$XML::Hash::LX::X2H{order}  = 1; # keep order strictly

my $hash = xml2hash
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
	attr => '.', # locally override attr to be prefixed with '.'
;
print +Dumper $hash;

# hash to xml options
$XML::Hash::LX::H2X{trim}  = 1;    # ignore whitespace
$XML::Hash::LX::H2X{attr}  = '+';  # keys, starting from '+' are attributes
$XML::Hash::LX::H2X{text}  = '~';  # key '~' is text node
$XML::Hash::LX::H2X{cdata} = '#';  # key '#' is CDATA node
$XML::Hash::LX::H2X{comm}  = '//'; # key '//' is comment node

# scalarref is treated as raw xml
$hash->{root}{inject} = \('<rawnode attr="zzz" />');
# refref is treated as XML::LibXML elements, and will be cloned and inserted
$hash->{root}{add} = \( XML::LibXML::Element->new('test') );

print hash2xml
	$hash,
	attr => '.', # locally override attr to be prefixed with '.'
;
