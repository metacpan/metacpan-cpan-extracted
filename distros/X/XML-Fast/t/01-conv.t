#!/use/bin/perl -w

use strict;
use Test::More;
BEGIN {
	my $add = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; ++$add; 1 }
		or diag "Test::NoWarnings missed, skipping no warnings test";
	plan tests => 26 + $add;
	eval {require Data::Dumper;Data::Dumper::Dumper(1)}
		and *dd = sub ($) { Data::Dumper->new([$_[0]])->Indent(0)->Terse(1)->Quotekeys(0)->Useqq(1)->Purity(1)->Dump }
		or  *dd = \&explain;
}

use XML::Fast 'xml2hash';

# Parsing

our $xml1 = q{
	<root at="key">
		<!-- test -->
		<nest>
			<![CDATA[first]]>
			<v>a</v>
			mid
			<v at="a">b</v>
			<vv></vv>
			last
		</nest>
	</root>
};

our $xml2 = q{
	<root at="key">
		<nest>
			first &amp; mid &amp; last
		</nest>
	</root>
};

our $xml3 = q{
	<root at="key">
		<nest>
			first &amp; <v>x</v> &amp; last
		</nest>
	</root>
};


our $data;
{
	is_deeply
		$data = xml2hash($xml1),
		{root => {'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'default (1)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1, cdata => '#cdata'),
		{root => {'-at' => 'key',nest => {'#cdata' => 'first','#text' => 'midlast',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'default (1)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml2),
		{root => {'-at' => 'key',nest => 'first & mid & last'}},
		'default (2)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml3),
		{root => {'-at' => 'key',nest => {'#text' => 'first && last',v => 'x'}}},
		'default (3)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml2, join => '+'),
		{root => {'-at' => 'key',nest => 'first & mid & last'}},
		'join => + (2)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml3, join => '+'),
		{root => {'-at' => 'key',nest => { '#text' => 'first &+& last', v => 'x' } }},
		'join => + (3)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1, array => ['root']),
		{root => [{'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}]},
		'array => root (1)',
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1, array => ['nest']),
		{root => {'-at' => 'key',nest => [{'#text' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}]}},
		'array => nest (1)',
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1, array => 1),
		{root => [{'-at' => 'key',nest => [{'#text' => 'firstmidlast',vv => [''],v => ['a',{'-at' => 'a','#text' => 'b'}]}]}]},
		'array => 1 (1)',
	or diag dd($data),"\n";
}
{
	no utf8;
	use bytes;
	is_deeply
		$data = xml2hash("<?xml encoding='UtF-8'?><text>С‚РµСЃС‚&#x2622;</text>"),
		{text => "\x{442}\x{435}\x{441}\x{442}\x{2622}"},
		'utf8.1',
	or diag explain($data),"\n";
	ok utf8::is_utf8($data->{text}), "utf flag ok";
	
	is_deeply
		$data = xml2hash("<?xml encoding='UtF-8'?><text>С‚РµСЃС‚</text>", bytes => 1),
		{text => "С‚РµСЃС‚"},
		'utf8.2',
	or diag explain($data),"\n";
	ok !utf8::is_utf8($data->{text}), "utf flag not set";

	is_deeply
		$data = xml2hash("<?xml encoding='windows-1251'?><text>тест</text>", bytes => 1),
		{text => "тест"},
		'utf8.3',
	or diag explain($data),"\n";
	ok !utf8::is_utf8($data->{text}), "utf flag not set";

	is_deeply
		$data = xml2hash("<?xml encoding='windows-1251'?><text>тест</text>"),
		{text => "\x{442}\x{435}\x{441}\x{442}"},
		'utf8.4',
	or diag explain($data),"\n";
	ok utf8::is_utf8($data->{text}), "utf flag set";

	is_deeply
		$data = xml2hash("<?xml encoding='windows-1251'?><text>тест&#x30;</text>"),
		{text => "\x{442}\x{435}\x{441}\x{442}0"},
		'1251 + low entity',
	or diag explain($data),"\n";
	ok utf8::is_utf8($data->{text}), "utf flag set";

	{
		is_deeply
			$data = xml2hash("<?xml encoding='windows-1251'?><text>тест&#x2622;\"&quot;</text>"),
			{text => "\x{442}\x{435}\x{441}\x{442}\x{2622}\"\""},
			'1251 + high entity (char mode)',
		or diag explain($data),"\n";
		ok utf8::is_utf8($data->{text}), "utf flag set";
	}

	{
		is_deeply
			$data = xml2hash("<?xml encoding='windows-1251'?><text>тест&#x2622;</text>", bytes => 1, nowarn => 1),
			{text => "тест?"},
			'1251 + high entity (bytes mode)',
		or diag explain($data),"\n";
		ok !utf8::is_utf8($data->{text}), "utf flag not set";
	}
	{
		is_deeply
			$data = xml2hash("<?xml encoding='windows-1251'?><text>тест&#xAB;</text>", bytes => 1),
			{text => "тест«"},
			'1251 + high entity (bytes mode), fits to charset',
		or diag explain($data),"\n";
		ok !utf8::is_utf8($data->{text}), "utf flag not set";
	}
}
{
	is_deeply
		$data = xml2hash($xml1, array => 1),
		{root => [{'-at' => 'key',nest => [{'#text' => 'firstmidlast',vv => [''],v => ['a',{'-at' => 'a','#text' => 'b'}]}]}]},
		'array => 1 (1)',
	or diag explain($data),"\n";
}
__END__

=for rem hash casting is useless and not implemented
{
	is_deeply
		$data = xml2hash($xml1, hash => ['vv']  ),
		{root => {'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => {'#text' => ''},v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'hash => vv (1)',
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1, hash => 1),
		{root => {'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => {'#text' => ''},v => [{ '#text' => 'a'},{'-at' => 'a','#text' => 'b'}]}}},
		'hash => 1 (1)',
	or diag dd($data),"\n";
}
=cut
{
	is_deeply
		$data = xml2hash($xml1, attr => '+'),
		{root => {'+at' => 'key',nest => {'#text' => 'firstmidlast',vv => '',v => ['a',{'+at' => 'a','#text' => 'b'}]}}},
		'attr => + (1)'
	or diag dd($data),"\n";
}
{
	local $X2H{attr} = '+';
	is_deeply
		$data = xml2hash($xml1),
		{root => {'+at' => 'key',nest => {'#text' => 'firstmidlast',vv => '',v => ['a',{'+at' => 'a','#text' => 'b'}]}}},
		'X2H.attr = + (1)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1, text => ''),
		{root => {'-at' => 'key',nest => {'' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','' => 'b'}]}}},
		'text => "" (1)'
	or diag dd($data),"\n";
}
{
	local $X2H{text} = '';
	is_deeply
		$data = xml2hash($xml1),
		{root => {'-at' => 'key',nest => {'' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','' => 'b'}]}}},
		'X2H.text = "" (1)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash($xml1, join => ' '),
		{root => {'-at' => 'key',nest => {'#text' => 'first mid last',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'join => " " (1)'
	or diag dd($data),"\n";
}
{
	local $X2H{join} = ' ';
	is_deeply
		$data = xml2hash($xml1),
		{root => {'-at' => 'key',nest => {'#text' => 'first mid last',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'X2H.join = " " (1)'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash(q{<root><!--test--></root>}, comm => '#comment'),
		{root => {'#comment' => 'test'}},
		'comment node'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash(q{<root x="1">test</root>}, text => '#textnode'),
		{root => { -x => 1, '#textnode' => 'test' }},
		'text node'
	or diag dd($data),"\n";
}
{
	is_deeply
		$data = xml2hash(q{<root x="1"><![CDATA[test]]></root>}, cdata => '#cdata'),
		{root => { -x => 1, '#cdata' => 'test' }},
		'cdata node'
	or diag dd($data),"\n";
}


# Composing
# Due to unpredictable order of hash keys
#   { node => { a => 1, b => 2 } }
# could be one of:
#   <node><a>1</a><b>2</b></node>
#   <node><b>2</b><a>1</a></node>
# So, in tests used more complex form with predictable order:
#   { node => [ { a => 1 }, { b => 2 } ] }
# which produce always
#   <node><a>1</a><b>2</b></node>

our $xml = qq{<?xml version="1.0" encoding="utf-8"?>\n};

{
	is
		$data = hash2xml( { node => [ { -attr => "test" }, { sub => 'test' }, { tx => { '#text' => ' zzzz ' } } ] } ),
		qq{$xml<node attr="test"><sub>test</sub><tx>zzzz</tx></node>\n},
		'default 1',
	;
}
{
	is
		$data = hash2xml( { node => [ { _attr => "test" }, { sub => 'test' }, { tx => { '#text' => 'zzzz' } } ] }, attr => '_' ),
		qq{$xml<node attr="test"><sub>test</sub><tx>zzzz</tx></node>\n},
		'attr _',
	;
}
{
	is
		$data = hash2xml( { node => [ { -attr => "test" }, { sub => 'test' }, { tx => { '~' => 'zzzz' } } ] }, text => '~' ),
		qq{$xml<node attr="test"><sub>test</sub><tx>zzzz</tx></node>\n},
		'text ~',
	;
}
{
	is
		$data = hash2xml( { node => { sub => [ " \t\n", 'test' ] } }, trim => 1 ),
		qq{$xml<node><sub>test</sub></node>\n},
		'trim 0',
	;
	is
		$data = hash2xml( { node => { sub => [ " \t\n", 'test' ] } }, trim => 0 ),
		qq{$xml<node><sub> \t\ntest</sub></node>\n},
		'trim 1',
	;
}
{
	is
		$data = hash2xml( { node => { sub => { '@' => 'test' } } }, cdata => '@' ),
		qq{$xml<node><sub><![CDATA[test]]></sub></node>\n},
		'cdata @',
	;
}
{
	is
		$data = hash2xml( { node => { sub => { '/' => 'test' } } },comm => '/' ),
		qq{$xml<node><sub><!--test--></sub></node>\n},
		'comm /',
	;
}
