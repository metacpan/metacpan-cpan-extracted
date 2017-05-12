#!/usr/bin/env perl -w

use strict;
use warnings;
use lib::abs '../lib';
use Test::More tests => 26;
use Test::NoWarnings ();
use XML::Declare;

my $doc;my $back;
{
	my $warn = 0;
	local $SIG{__WARN__} = sub { $warn++ };
	is + ($doc = doc {}), qq{<?xml version="1.0" encoding="utf-8"?>\n}, 'empty doc';
	is $warn, 1, 'have warn'; $warn = 0;
	is + ($doc = doc {} '1.1'), qq{<?xml version="1.1" encoding="utf-8"?>\n}, 'empty doc 1.1';
	is $warn, 1, 'have warn'; $warn = 0;
	is + ($doc = doc {} undef,'cp1251'), qq{<?xml version="1.0" encoding="cp1251"?>\n}, 'empty doc cp1251';
	is $warn, 1, 'have warn'; $warn = 0;
	is + ($doc = doc {} '1.1','cp1251'), qq{<?xml version="1.1" encoding="cp1251"?>\n}, 'empty doc 1.1 cp1251';
	is $warn, 1, 'have warn'; $warn = 0;
	is + ($doc = doc { comment 'test'; }), qq{<?xml version="1.0" encoding="utf-8"?>\n<!--test-->\n}, 'empty doc with comment';
	is $warn, 1, 'have warn'; $warn = 0;
}

is 
	$doc = doc { element 'test'; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test/>\n},
	'doc + element'
	or diag $doc;

XML::LibXML->new->parse_string("$doc");

eval { $doc = doc { element '<'; } };
ok $@, 'bad node name' or diag "No error: $doc";
eval { $doc = doc { element t => sub { attr '<' => 'attrval'; }; } };
ok $@, 'bad attr name' or diag "No error: $doc";


is 
	$doc = doc { element 'test', 'text', a => 'attrval'; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text</test>\n},
	'doc + element + attrs'
	or diag $doc;

XML::LibXML->new->parse_string("$doc");

is 
	$doc = doc { element test => a => 'attrval', sub { text 'text'; }; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text</test>\n},
	'doc + element-sub'
	or diag $doc;

XML::LibXML->new->parse_string("$doc");

# Element have overloaded 'eq' magic, so force stringify
is +
	''.($doc = element( test => a => 'attrval', sub { element "a","b";text 'text';element "x","y"; } )),
	qq{<test a="attrval"><a>b</a>text<x>y</x></test>},
	'nodoc element + element-sub'
	or diag $doc;

XML::LibXML->new->parse_string("$doc");

is 
	$doc = doc { element test => sub { text 'text'; attr a => 'attrval'; }; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text</test>\n},
	'doc + element-sub + attr'
	or diag $doc;

XML::LibXML->new->parse_string("$doc");

is 
	$doc = doc { element test => sub { text 'text'; attr a => 'attrval'; comment 'zzzz'; cdata 'something <![CDATA[:)]]>'; }; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text<!--zzzz--><![CDATA[something <![CDATA[:)]]]]><![CDATA[>]]></test>\n},
	'doc + element-sub + attr,comm,cdata';

XML::LibXML->new->parse_string("$doc");

eval { $doc = doc { element test => sub { comment '--'; } } };
like $@, qr/double-hyphen.* MUST NOT occur within/i, 'comment with --' or diag "No error: $doc";

eval { $doc = doc { element test => sub { comment 'test-'; } } };
like $@, qr/MUST NOT end with .*hyphen/i, 'comment with -' or diag "No error: $doc";

$doc = doc { element test => sub { comment '-B, B+, B, or B- '; }; };
$back = XML::LibXML->new->parse_string("$doc");
is $back->documentElement->firstChild->textContent, "-B, B+, B, or B- ", 'comment parsed back';

$doc = doc { element test => sub { cdata '<![CDATA[:)]]>'; } };
$back = XML::LibXML->new->parse_string("$doc");
is $back->documentElement->firstChild->textContent, '<![CDATA[:)]]>', 'cdata parsed back';

Test::NoWarnings::had_no_warnings();

local $SIG{__WARN__} = sub {
	diag "warned:  @_";
};

is 
	$doc = doc { text 'x'; element test => 'root'; text 'x'; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test>root</test>\n},
	'doc + text,element,text';

is 
	$doc = doc { text 'x'; element test => 'root'; element dummy => "dummy"; text 'x'; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test>root</test>\n},
	'doc + text,element,text';

is 
	$doc = doc { text ' ';element test => 'root'; text ' '; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test>root</test>\n},
	'doc + wsp,element,wsp';

exit;
require Test::NoWarnings; # Stupid hack for cpants::kwalitee
