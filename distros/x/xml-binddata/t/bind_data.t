use strict;
use warnings;

use Test::More;

use_ok 'XML::BindData';

my $tests = [
	[
		'<foo tmpl-bind="foo"/>', { foo => 'bar' },
		'<foo>bar</foo>', 'Single binding'
	],

	[
		'<foo tmpl-bind="foo"/>', { foo => undef },
		'<foo></foo>', 'Single binding, undefined - get empty string'
	],

	[
		'<foo tmpl-bind="foo" tmpl-default="baz"/>', { foo => 'bar' },
		'<foo>bar</foo>', 'Single binding, with default (unused)'
	],

	[
		'<foo tmpl-bind="foo" tmpl-default="baz"/>', {},
		'<foo>baz</foo>', 'Single binding, with default (used)'
	],

	[
		'<foo><multi tmpl-each="foo"/></foo>', { foo => [(1) x 3] },
		'<foo><multi></multi><multi></multi><multi></multi></foo>',
		'Each over multiple entities'
	],

	[
		'<foo><bar tmpl-each="bar" tmpl-bind="this"/></foo>',
		{ bar => [ 1, 2, 3 ] },
		'<foo><bar>1</bar><bar>2</bar><bar>3</bar></foo>',
		'This binds inside each'
	],

	[
		'<foo tmpl-attr-map="bar:baz"/>', { baz => 'quux' },
		'<foo bar="quux"></foo>', 'Attribute binds'
	],

	[
		'<foo tmpl-attr-map="a:aaa,b:bbb"/>', { aaa => 1, bbb => 2 },
		'<foo a="1" b="2"></foo>', 'Multiple attributes bind'
	],

	[
		'<foo tmpl-attr-map="a:aaa,b:bbb,d:ddd" tmpl-attr-defaults="a:zzz,c:123,d:456"/>', { aaa => 1, bbb => 2 },
		'<foo a="1" b="2" c="123" d="456"></foo>', 'Attribute defaults'
    ],

	[
		'<foo tmpl-attr-map="a:aaa,b:bbb" tmpl-attr-defaults="a:zzz,c:0"/>', { aaa => 0, bbb => 2 },
		'<foo a="0" b="2" c="0"></foo>', 'Attribute defaults with false values'
	],

	[
		'<foo tmpl-attr-map="a:aaa,b:bbb" tmpl-attr-defaults="a:zzz,c:foo\,bar,d:foo\:bar"/>', { aaa => 0, bbb => 2 },
		'<foo a="0" b="2" c="foo,bar" d="foo:bar"></foo>', 'Attribute defaults with commas and colons'
	],

	[
		'<foo><bar tmpl-each="bar"><baz tmpl-each="this" tmpl-bind="this"/></bar></foo>',
		{
			bar => [
				[ qw/ 1 2 / ],
				[ qw/ 3 4 / ],
			]
		},
		'<foo><bar><baz>1</baz><baz>2</baz></bar><bar><baz>3</baz><baz>4</baz></bar></foo>',
		'Nested arrays'
	],

	[
		'<foo><bar tmpl-each="bar"><id tmpl-bind="id"/></bar></foo>',
		{
			bar => [
				{ id => 1 },
				{ id => 2 },
			]
		},
		'<foo><bar><id>1</id></bar><bar><id>2</id></bar></foo>',
		'Each uses individual items as context'
	],

	[
		'<foo tmpl-bind="foo.bar.baz"/>',
		{ foo => { bar => { baz => 1 } } },
		'<foo>1</foo>', 'Dot notation references nested hashes'
	],

	[
		'<foo><bar tmpl-if="show">bar</bar></foo>', { show => 1 },
		'<foo><bar>bar</bar></foo>', 'If true keeps node'
	],

	[
		'<foo><bar tmpl-if="show">bar</bar></foo>', { show => undef },
		'<foo></foo>', 'If false removes node'
	],
    
    [
		'<foo><bar tmpl-if="show">bar</bar></foo>', { },
		'<foo></foo>', 'If false removes node'
	],

	[
		'<foo><bar tmpl-if="!show">bar</bar></foo>', { show => undef },
		'<foo><bar>bar</bar></foo>', 'If not false keeps node'
	],

	[
		'<foo><bar tmpl-if="!show">bar</bar></foo>', { show => 1 },
		'<foo></foo>', 'If not true removes node'
	],

	[
		'<foo><bar tmpl-if="show" tmpl-each="bar" tmpl-bind="this"/></foo>',
		{
			show => 1,
			bar  => [ 1, 2, 3 ],
		},
		'<foo><bar>1</bar><bar>2</bar><bar>3</bar></foo>',
		'If + each + this all on one tag works'
	],

    [
        '<foo><bar tmpl-each="list" tmpl-bind="this"/><baz tmpl-if="num" tmpl-bind="num" /></foo>',
        {
            list => [ 1, 2 ],
            num => 3,
        },
        '<foo><bar>1</bar><bar>2</bar><baz>3</baz></foo>',
        'XML order retained when using varying types',
    ],
    [
        '<foo><bar tmpl-each="list" tmpl-bind="this"/><baz tmpl-if="num" tmpl-bind="num" /></foo>',
        {
            list => [ 0, 1 ],
            num => 0,
        },
        '<foo><bar>0</bar><bar>1</bar><baz>0</baz></foo>',
        'Number 0 is a valid value and passes if conditionals',
    ],
    [
        '<foo><bar tmpl-bind="num" /><!-- preserve comment --></foo>',{ num => 4 },
        '<foo><bar>4</bar><!-- preserve comment --></foo>',
        'Preserve comments'
    ]
];

foreach my $t (@$tests) {
	my ($source_xml, $data, $output, $msg) = @$t;
	is(XML::BindData->bind($source_xml, $data), $output, $msg);
}

done_testing;
