use Test::Instruction qw/all/;

{
	package Foo;

	sub new {
		bless {}, shift;
	}

	sub false { 0 }

	sub true { 1 }

	sub chain { { a => "b" } }

	sub hash { { a => { a => 1 } } }

	sub array { [ 'a', [ 1, 2, 3 ], 'b' ] }

	1;
}

instructions(
    name => 'Checking Many Things',
    build => {
        class => 'Foo', 
    },
    run => [
        {
		test => 'hash',
		expected => {}
        },
        {
		test => 'true',
		meth => 'true',
        },
        { 
		test => 'false',
		meth => 'false',
        },
	{
		test => 'ok',
		meth => "chain",
		instructions => [
			{
				test => 'hash',
				expected => {
					a => "b"
				}
			}
		]
	},
	{
		test => 'ok',
		meth => 'hash',
		instructions => [
			{
				test => 'ok',
				ref_key => 'a',
				instructions => [
					{
						test => 'hash',
						expected => { a => 1 }
					}
				]
			}
		]
	},
	{
		test => 'ok',
		meth => 'array',
		instructions => [
			{
				test => 'ref_index_scalar',
				index => 0,
				expected => 'a'
			},
			{
				test => 'ok',
				ref_index => 0,
				instructions => [
					{
						test => 'scalar',
						expected => 'a'
					}
				]
			},
			{
				test => 'ok',
				ref_index => 1,
				instructions => [
					{
						test => 'array',
						expected => [1, 2, 3]
					}
				]
			},
			{
				test => 'ref_index_scalar',
				index => 2,
				expected => 'b'
			},
			{
				test => 'ok',
				ref_index => 2,
				instructions => [
					{
						test => 'scalar',
						expected => 'b'
					}
				]
			},
		]
	}

    ],
);

finish(33);
