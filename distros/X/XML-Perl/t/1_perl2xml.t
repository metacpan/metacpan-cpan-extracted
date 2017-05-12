use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/..";

use Test::More tests => 3;

BEGIN { use_ok( 'XML::Perl' ); }


{
my $xml = <<EOD;
<a f="foo">
	<aa a="b">11</aa>
	<ab a="1">12</ab>
	<ab a="2">13</ab>
</a>
<b>
	<c>4</c>
	<d>5</d>
</b>
<b>
	<c>6</c>
	<d>7</d>
</b>
EOD


my $perl = {
	'a' => {
		'@f' => 'foo',
		'aa' => { '@a' => 'b',  '' => 11 },
		'ab' => [
			{'@a' => '1',  '' => 12},
			{'@a' => '2',  '' => 13},
		],
	},
	'b' => [
		{
			'c' => '4',
			'd' => '5',
		},
		{
			'c' => '6',
			'd' => '7',
		},
	],
};


is perl2xml($perl), $xml, "perl2xml 1";
}


{
my $xml = <<EOD;
<test>
	<array hidden="secret" perl="awesome">
		<item index="0"/>
		<item index="1"/>
		<item index="2"/>
	</array>
	<censored foo="secret"/>
	<data attr1="test">some test text</data>
	<empty a="b">
		<inner c="d"/>
	</empty>
	<key>value</key>
	<private some="value"/>
</test>
EOD

my $data = {
	test => {
		key      => 'value',
		data     => { '@attr1' => 'test', '' => 'some test text' },
		empty    => { '@a' => 'b', '' => { inner => { '@c' => 'd' } } },
		private  => { '@some' => 'value' },
		censored => { '@foo' => 'secret' },
		array    => { '@perl' => 'awesome', '@hidden' => 'secret', '' => {
				item => [ 
					{ '@index' => 0 },
					{ '@index' => 1 },
					{ '@index' => 2 },
				] 
			}},
	},
};

# print perl2xml($data, 0, "\t");
# print perl2xml($data, 0, " ");
# print perl2xml($data, 0, "");
is perl2xml($data), $xml, "perl2xml 2";
}
