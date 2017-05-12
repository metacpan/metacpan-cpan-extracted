use lib qw(t/lib);
use Test::Tester; # should load before Test::More

use t::Utils;
use Test::Double;
use Test::More;

subtest 'verify faile' => sub {
    subtest 'with' => sub {
        check_test( sub {
                        my $foo = t::Foo->new;
                        mock($foo)->expects('bar')->with(1)->returns(2);
                        $foo->bar(2);
                        Test::Double->verify;
                        Test::Double->reset;
                    },{
                        ok => 0,
                        name => 'Expected method must be called with 1',
                        diag => "",
                        depth => 4,
                    }
                );

        check_test( sub {
                        my $foo = t::Foo->new;
                        mock($foo)->expects('baz')->with('foo')->returns(2);
                        $foo->baz;
                        Test::Double->verify;
                        Test::Double->reset;
                    },{
                        ok => 0,
                        name => 'Expected method must be called with foo',
                        diag => "",
                        depth => 4,
                    }
                );

        check_test( sub {
                        my $foo = t::Foo->new;
                        mock($foo)->expects('baz')->with('foo')->returns(2);
                        $foo->baz(3);
                        Test::Double->verify;
                        Test::Double->reset;
                    },{
                        ok => 0,
                        name => 'Expected method must be called with foo',
                        diag => "",
                        depth => 4,
                    }
                );

        check_test( sub {
                        my $foo = t::Foo->new;
                        mock($foo)->expects('baz')->with('foo')->returns(2);
                        $foo->baz('foo', 3);
                        Test::Double->verify;
                        Test::Double->reset;
                    },{
                        ok => 0,
                        name => 'Expected method must be called with foo',
                        diag => "",
                        depth => 4,
                    }
                );
    };

    subtest 'at_most' => sub {
        check_test( sub {
                        my $foo = t::Foo->new;
                        mock($foo)->expects('baz')->at_most(2)->returns('foo');
                        $foo->baz;
                        $foo->baz;
                        $foo->baz;
                        Test::Double->verify;
                        Test::Double->reset;
                    },{
                        ok => 0,
                        name => 'Expected method must be called at most 2',
                        diag => "",
                        depth => 4,
                    }
                );
    };

    subtest 'times' => sub {
        check_test( sub {
                        my $foo = t::Foo->new;
                        mock($foo)->expects('baz')->times(2)->returns('foo');
                        $foo->baz;
                        Test::Double->verify;
                        Test::Double->reset;
                    },{
                        ok => 0,
                        name => 'Expected method must be called 2 times',
                        diag => "",
                        depth => 4,
                    }
                );
    };

    subtest 'at least' => sub {
        check_test( sub {
                        my $foo = t::Foo->new;
                        mock($foo)->expects('baz')->at_least(2)->returns('foo');
                        $foo->baz;
                        Test::Double->verify;
                        Test::Double->reset;
                    },{
                        ok => 0,
                        name => 'Expected method must be called at least 2',
                        diag => "",
                        depth => 4,
                    }
                );
    };
};

done_testing;
