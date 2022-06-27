use Test::Instruction qw/all/;

{
	package Foo;

	sub new {
		bless {}, shift;
	}

	sub false { 0 }

	sub true { 1 }

	sub chain { { a => "b" } }

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
	}
    ],
);

finish(9);
