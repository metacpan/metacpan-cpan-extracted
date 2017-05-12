use Test::Mini::Unit;

# The following test cases don't actually prove anything; the side effects do.
our @calls = ();

case Top {
    setup { push @calls, [ __PACKAGE__, 'first setup' ] }
    setup { push @calls, [ __PACKAGE__, 'second setup' ] }

    test it { push @calls, [ __PACKAGE__, 'test' ]; skip('Fixture') }

    teardown { push @calls, [ __PACKAGE__, 'first teardown' ] }
    teardown { push @calls, [ __PACKAGE__, 'second teardown' ] }

    case Nested {
        setup { push @calls, [ __PACKAGE__, 'first setup' ] }
        setup { push @calls, [ __PACKAGE__, 'second setup' ] }

        test it { push @calls, [ __PACKAGE__, 'test' ]; skip('Fixture') }

        teardown { push @calls, [ __PACKAGE__, 'first teardown' ] }
        teardown { push @calls, [ __PACKAGE__, 'second teardown' ] }

        case Deeply {
            setup { push @calls, [ __PACKAGE__, 'first setup' ] }
            setup { push @calls, [ __PACKAGE__, 'second setup' ] }

            test it { push @calls, [ __PACKAGE__, 'test' ]; skip('Fixture') }

            teardown { push @calls, [ __PACKAGE__, 'first teardown' ] }
            teardown { push @calls, [ __PACKAGE__, 'second teardown' ] }
        }
    }
}

# Begin actual tests
####################
package t::Test::Mini::Unit::Sugar::TestCase::Advice;
use base 'Test::Mini::TestCase';

use Test::Mini::Assertions;

sub assert_calls {
    my ($pkg, $expectations) = @_;
    no strict 'refs';
    @calls = ();
    $pkg->new(name => 'test_it')->run(Test::Mini::Logger->new());
    assert_equal(\@calls, $expectations);
}

sub test_top_level_cases {
    assert_calls('Top', [
        [ 'Top', 'first setup'     ],
        [ 'Top', 'second setup'    ],
        [ 'Top', 'test'            ],
        [ 'Top', 'second teardown' ],
        [ 'Top', 'first teardown'  ],
    ]);
}

sub test_nested_cases {
    assert_calls('Top::Nested', [
        [ 'Top',         'first setup'     ],
        [ 'Top',         'second setup'    ],
        [ 'Top::Nested', 'first setup'     ],
        [ 'Top::Nested', 'second setup'    ],
        [ 'Top::Nested', 'test'            ],
        [ 'Top::Nested', 'second teardown' ],
        [ 'Top::Nested', 'first teardown'  ],
        [ 'Top',         'second teardown' ],
        [ 'Top',         'first teardown'  ],
    ]);
}

sub test_deeply_nested_cases {
    assert_calls('Top::Nested::Deeply', [
        [ 'Top',                 'first setup'     ],
        [ 'Top',                 'second setup'    ],
        [ 'Top::Nested',         'first setup'     ],
        [ 'Top::Nested',         'second setup'    ],
        [ 'Top::Nested::Deeply', 'first setup'     ],
        [ 'Top::Nested::Deeply', 'second setup'    ],
        [ 'Top::Nested::Deeply', 'test'            ],
        [ 'Top::Nested::Deeply', 'second teardown' ],
        [ 'Top::Nested::Deeply', 'first teardown'  ],
        [ 'Top::Nested',         'second teardown' ],
        [ 'Top::Nested',         'first teardown'  ],
        [ 'Top',                 'second teardown' ],
        [ 'Top',                 'first teardown'  ],
    ]);
}

1;
