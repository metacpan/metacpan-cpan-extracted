#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Mockingbird;
use Test::Mockingbird::DeepMock qw(deep_mock);

# A simple test package we can safely mutate
{
	package DMTest;
	our $VALUE = 10;

	sub greet  { "orig" }
	sub double { ($_[1] // 0) * 2 }
	sub getval { $VALUE }
	sub setval { $VALUE = $_[1] }
}

subtest 'basic mock replaces method' => sub {
	deep_mock(
		{
			mocks => [
				{
					target => 'DMTest::greet',
					type   => 'mock',
					with   => sub { "mocked" },
				},
			],
		},
		sub {
			is DMTest::greet(), 'mocked', 'greet() was mocked';
		}
	);

	is DMTest::greet(), 'orig', 'mock restored after deep_mock';
};

subtest 'spy captures calls and arguments' => sub {
	deep_mock(
		{
			mocks => [
				{
					target => 'DMTest::double',
					type   => 'spy',
					tag	=> 'dbl',
				},
			],
			expectations => [
				{
					tag   => 'dbl',
					calls => 2,
				},
			],
		},
		sub {
			DMTest::double(2);
			DMTest::double(5);
		}
	);
};

subtest 'inject replaces value or behavior' => sub {
	deep_mock(
		{
			mocks => [
				{
					target => 'DMTest::getval',
					type   => 'inject',
					with   => 999,
				},
			],
		},
		sub {
			is DMTest::getval(), 999, 'inject replaced getval';
		}
	);

	is DMTest::getval(), 10, 'inject restored after deep_mock';
};

subtest 'multiple mocks + spy + expectations' => sub {
	deep_mock(
		{
			mocks => [
				{
					target => 'DMTest::greet',
					type   => 'mock',
					with   => sub { "hi" },
				},
				{
					target => 'DMTest::double',
					type   => 'spy',
					tag	=> 'dbl',
				},
			],
			expectations => [
				{
					tag   => 'dbl',
					calls => 3,
				},
			],
		},
		sub {
			is DMTest::greet(), 'hi', 'greet mocked';
			DMTest::double(1);
			DMTest::double(2);
			DMTest::double(3);
		}
	);
};

subtest 'argument pattern expectations' => sub {
	deep_mock(
		{
			mocks => [
				{
					target => 'DMTest::double',
					type   => 'spy',
					tag	=> 'dbl',
				},
			],
			expectations => [
				{
					tag	  => 'dbl',
					calls	=> 2,
					args_like => [
						[ qr/^10$/ ],
						[ qr/^20$/ ],
					],
				},
			],
		},
		sub {
			DMTest::double(10);
			DMTest::double(20);
		}
	);
};

subtest 'restore_on_scope_exit => 0 keeps mocks active' => sub {
	deep_mock(
		{
			globals => { restore_on_scope_exit => 0 },
			mocks   => [
				{
					target => 'DMTest::greet',
					type   => 'mock',
					with   => sub { "persist" },
				},
			],
		},
		sub {
			is DMTest::greet(), 'persist', 'mock active inside deep_mock';
		}
	);

	is DMTest::greet(), 'persist', 'mock persists after deep_mock';

	Test::Mockingbird::restore_all();
	is DMTest::greet(), 'orig', 'manual restore_all works';
};

subtest 'unknown mock type throws error' => sub {
	dies_ok {
		deep_mock(
			{
				mocks => [
					{
						target => 'DMTest::greet',
						type   => 'wut',   # invalid
					},
				],
			},
			sub { }
		);
	} 'unknown mock type dies';
};

subtest 'missing spy tag in expectation dies' => sub {
	dies_ok {
		deep_mock(
			{
				mocks => [
					{
						target => 'DMTest::double',
						type   => 'spy',
						tag	=> 'dbl',
					},
				],
				expectations => [
					{
						calls => 1,   # missing tag
					},
				],
			},
			sub { DMTest::double(1) }
		);
	} 'missing tag in expectation dies';
};

subtest 'args_eq works' => sub {
	{
		package DM_EQ;
		sub foo { $_[1] }
	}

	deep_mock(
		{
			mocks => [
				{ target => 'DM_EQ::foo', type => 'spy', tag => 's' },
			],
			expectations => [
				{
					tag	 => 's',
					args_eq => [
						[ 'alpha' ],
						[ 'beta'  ],
					],
				},
			],
		},
		sub {
			DM_EQ::foo('alpha');
			DM_EQ::foo('beta');
		}
	);
};

subtest 'args_deeply works' => sub {
	{
		package DM_DEEP;
		sub foo { $_[1] }
	}

	deep_mock(
		{
			mocks => [
				{ target => 'DM_DEEP::foo', type => 'spy', tag => 's' },
			],
			expectations => [
				{
					tag		 => 's',
					args_deeply => [
						[ { a => 1, b => [2,3] } ],
						[ { x => 9 } ],
					],
				},
			],
		},
		sub {
			DM_DEEP::foo({ a => 1, b => [2,3] });
			DM_DEEP::foo({ x => 9 });
		}
	);
};

subtest 'never works' => sub {

    {
        package DM_NEVER;
        sub foo { $_[1] }
    }

    deep_mock(
        {
            mocks => [
                { target => 'DM_NEVER::foo', type => 'spy', tag => 's' },
            ],
            expectations => [
                { tag => 's', never => 1 },
            ],
        },
        sub {
            # Intentionally do NOT call DM_NEVER::foo
        }
    );
};

subtest 'combined mock_return + mock_exception + mock_sequence' => sub {
    {
        package Edge::Service;
        sub status { return 'ok' }
    }

    mock_return    'Edge::Service::status' => 'warmup';
    mock_sequence  'Edge::Service::status' => ('retry1', 'retry2', 'steady');
    mock_exception 'Edge::Service::status' => 'fatal';

    dies_ok { Edge::Service::status() } 'topmost mock_exception wins';
    like $@, qr/fatal/, 'fatal error seen';

    restore_all();

    is Edge::Service::status(), 'ok', 'original restored';
};

subtest 'mock_once with retry logic' => sub {
    {
        package Edge::Service;
        sub ping { return 'ok' }
    }

    mock_once 'Edge::Service::ping' => sub { 'fail' };

    is Edge::Service::ping(), 'fail', 'first call fails';
    is Edge::Service::ping(), 'ok',   'second call succeeds';

    restore_all();
};

subtest 'restore interacts correctly with mock_once and mock_sequence' => sub {
    {
        package Edge::Restore;
        sub c { return 'orig' }
    }

    mock_sequence 'Edge::Restore::c' => (10, 20);
    mock_once     'Edge::Restore::c' => sub { 99 };

    is Edge::Restore::c(), 99, 'mock_once fires first';

    restore 'Edge::Restore::c';

    is Edge::Restore::c(), 'orig', 'restore removes all layers';

    restore_all();
};

subtest 'diagnose_mocks integrates with spy and inject' => sub {
    {
        package DM::I1;
        sub c { 1 }
        sub dep { 2 }
    }

    spy 'DM::I1::c';
    inject 'DM::I1::dep' => sub { 99 };

    my $diag = diagnose_mocks();

    ok exists $diag->{'DM::I1::c'}, 'spy recorded';
    ok exists $diag->{'DM::I1::dep'}, 'inject recorded';

    restore_all();
};


done_testing();
