use strict;
use Test::More tests => 13;
use Text::Xatena;
use Data::Dumper;

sub p ($) { warn Dumper shift }

my $thx = Text::Xatena->new;
my $res;
sub same ($$) {
	my ($got, $expected) = @_;
	my $r = is_deeply $got, $expected;
	unless ($r) {
		p $got;
	}
}

$res = $thx->_parse(<<EOS);
foo
bar
EOS

same $res, {
	children => [
		"foo",
		"bar",
	]
};

$res = $thx->_parse(<<EOS);
foo
bar

baz
EOS

same $res, {
	children => [
		"foo",
		"bar",
		"",
		"baz",
	]
};

$res = $thx->_parse(<<EOS);
- foo
- bar
- baz
EOS

same $res, {
	children => [
		{
			children => [
				[ "- foo", "-", "foo"],
				[ "- bar", "-", "bar"],
				[ "- baz", "-", "baz"],
			]
		}
	]
};

$res = $thx->_parse(<<EOS);
- foo
- bar
- baz
piyo
EOS

same $res, {
	children => [
		{
			children => [
				[ "- foo", "-", "foo"],
				[ "- bar", "-", "bar"],
				[ "- baz", "-", "baz"],
			]
		},
		"piyo"
	]
};

$res = $thx->_parse(<<EOS);
- foo
- bar
- baz

piyo
EOS

same $res, {
	children => [
		{
			children => [
				[ "- foo", "-", "foo"],
				[ "- bar", "-", "bar"],
				[ "- baz", "-", "baz"],
			]
		},
		"",
		"piyo"
	]
};

$res = $thx->_parse(<<EOS);
|foo|bar|
|foo|bar|
|foo|bar|
EOS

same $res, {
	children => [
		{
			children => [
				"|foo|bar|",
				"|foo|bar|",
				"|foo|bar|",
			]
		}
	]
};

$res = $thx->_parse(<<EOS);
>||

foobar
baz
fooooo
<>&
>>
  baz
<<

||<
EOS

same $res, {
	children => [
		{
			lang => '',
			children => [
				q{
foobar
baz
fooooo
<>&
>>
  baz
<<
}
			]
		},
	]
};

$res = $thx->_parse(<<EOS);
>>
quote1
>>
quote2
<<
<<
EOS

same $res, {
	children => [
		{
			beginning => ['>>', ''],
			endofnode => ['<<', '1'],
			children => [
				"quote1",
				{
					beginning => ['>>', ''],
					endofnode => ['<<', '1'],
					children => [
						"quote2"
					],
				},
			],
		},
	]
};

$res = $thx->_parse(<<EOS);
>>
quote1
>|
pre
foo
|<
<<
EOS

same $res, {
	children => [
		{
			beginning => ['>>', ''],
			endofnode => ['<<', '1'],
			children => [
				"quote1",
				{
					children => [
						"pre",
						"foo",
						"",
					],
				},
			],
		},
	]
};
$res = $thx->_parse(<<EOS);
>>
quote1
>|
pre
foo
baz|<
<<
EOS

same $res, {
	children => [
		{
			beginning => ['>>', ''],
			endofnode => ['<<', '1'],
			children => [
				"quote1",
				{
					children => [
						"pre",
						"foo",
						"baz",
					],
				},
			],
		},
	]
};

$res = $thx->_parse(<<EOS);
><blockquote>
<p>
foobar<br/>
baz
</p>
<blockquote><
EOS

same $res, {
	children => [
		{
			children => [qw{
				<blockquote>
				<p>
				foobar<br/>
				baz
				</p>
				<blockquote>
			} ],
		},
	]
};

$res = $thx->_parse(<<EOS);
foobar

><ins><
foobar
></ins><
EOS

same $res, {
	children => [
		"foobar",
		"",
		{
			children => [qw{
				<ins>
			} ],
		},
		"foobar",
		{
			children => [qw{
				</ins>
			} ],
		},
	]
};


$res = $thx->_parse(<<EOS);
foobar

* head 1
content of head 1

** head 1.1
content of head 1.1

*** head 1.1.1
content of head 1.1.1

*** head 1.1.2
content of head 1.1.2

* head 2
content of head 2
EOS

same $res, {
	children => [
		"foobar",
		"",
		{
			level => 1,
			title => 'head 1',
			children => [
				'content of head 1',
				'',
				{
					level => 2,
					title => 'head 1.1',
					children => [
						'content of head 1.1',
						'',
						{
							level => 3,
							title => 'head 1.1.1',
							children => [
								'content of head 1.1.1',
								'',
							],
						},
						{
							level => 3,
							title => 'head 1.1.2',
							children => [
								'content of head 1.1.2',
								'',
							],
						},
					],
				},
			],
		},
		{
			level => 1,
			title => 'head 2',
			children => [
				'content of head 2',
			],
		},
	]
};
