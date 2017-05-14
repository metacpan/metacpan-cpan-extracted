use Test::Spec;

BEGIN { use_ok 'Test::Spec::RMock' };

describe 'Test::Spec::RMock' => sub {

    describe "calling unmocked methods" => sub {
        my ($mock);
        before each => sub {
            $mock = rmock('foo')->__cancel;
        };

        it "should fail when calling without any arguments" => sub {
            $mock->bar;
            is($mock->__check, "Unmocked method 'bar' called on 'foo' with ()");
        };

        it "should fail when calling with arguments" => sub {
            $mock->bar(1, 2, 3);
            is($mock->__check, "Unmocked method 'bar' called on 'foo' with ('1', '2', '3')");
        };
    };

    describe 'method stubs' => sub {
        my $mock;
        before each => sub {
            $mock = rmock('foo');
        };

        it "should take as arguments name and return value" => sub {
            $mock->stub('bar' => 1);
            is($mock->bar, 1);
        };

        it "should return the same value each time it is called" => sub {
            $mock->stub('bar' => 1);
            my @results = ();
            push @results, $mock->bar for 1..3;
            is_deeply(\@results, [1, 1, 1]);
        };

        it "should allow defining multiple stubbed methods with one call to stub()" => sub {
            $mock->stub(
                foo => 1,
                bar => 2,
                baz => 3,
            );
            my @results = ($mock->foo, $mock->bar, $mock->baz);
            is_deeply(\@results, [1, 2, 3]);
        };
    };

    describe 'stub chaining' => sub {
        it "should allow you to list methods to chain and let you set a return value for the last method" => sub {
            my $mock = rmock('foo');
            $mock->stub_chain(qw(one two three))->and_return('four');
            is($mock->one->two->three, 'four');
        };
    };

    context 'call constraints' => sub {
        describe 'at_least_once()' => sub {
            it 'should fail when called zero times' => sub {
                my $mock = rmock('foo')->__cancel;
                $mock->should_receive('bar')->at_least_once;
                is($mock->__check, "Expected 'bar' to be called at least once on 'foo', but called 0 times.");
            };

            it 'should pass when called one time' => sub {
                my $mock = rmock('foo');
                $mock->should_receive('bar')->at_least_once->and_return(1);
                is($mock->bar, 1);
            };

            it 'should pass when called more than one time' => sub {
                my $mock = rmock('foo');
                $mock->should_receive('bar')->at_least_once->and_return(1);
                my @results = ();
                push @results, $mock->bar for 1..4;
                is_deeply(\@results, [1, 1, 1, 1]);
            };
        };
    };

    describe 'should_not_receive()' => sub {
        it 'should pass when the mocked method is never called' => sub {
            my $mock = rmock('foo');
            $mock->should_not_receive('bar');
            is($mock->__check, '');
        };

        it 'should fail if the mocked method is called' => sub {
            my $mock = rmock('foo')->__cancel;
            $mock->should_not_receive('bar');
            $mock->bar;
            is($mock->__check, "Expected 'bar' to be called 0 times on 'foo', but it was called 1 time.");
        };
    };

    describe 'as_null_object' => sub {
        my ($mock);

        before each => sub {
            $mock = rmock('foo')->__cancel;
        };

        it 'should just return $self on calls to unmocked/unstubbed methods' => sub {
            my $mock = rmock('foo');
            $mock->as_null_object;
            is($mock->non_existing_method(), $mock);
        };

        it 'should report no errors on calls to unmocked/unstubbed methods' => sub {
            my $mock = rmock('foo')->__cancel;
            $mock->as_null_object;
            $mock->non_existing_method();
            $mock->another_non_existing_method(qw(with some arguments));
            is($mock->__check, '');
        };
    };

    describe 'argument matching' => sub {
        my ($mock);

        before each => sub {
            $mock = rmock('foo')->__cancel;
        };

        it "should pass when expecting no arguments and none are given" => sub {
            $mock->should_receive('bar')->with();
            $mock->bar;
            is($mock->__check, '');
        };

        it "should fail when there are arguments when none were expected" => sub {
            $mock->should_receive('bar')->with();
            $mock->bar(1);
            like($mock->__check, qr/^Argument matching failed.*got : array with 1 element.*expect : array with 0 element/s);
        };

        it "should pass when expecting the number '1' and it is given" => sub {
            $mock->should_receive('bar')->with(1);
            $mock->bar(1);
            is($mock->__check, '');
        };

        it "should pass when expecting the String 'BAZ' and it is given" => sub {
            $mock->should_receive('bar')->with('BAZ');
            $mock->bar('BAZ');
            is($mock->__check, '');
        };

        it "should fail when expecting the number '1' and '2' is given" => sub {
            $mock->should_receive('bar')->with(1);
            $mock->bar(2);
            like($mock->__check, qr/^Argument matching failed.*got : '2'.*expect : '1'/s);
        };

        it "should pass when expecting (1, 'two') and it is given" => sub {
            $mock->should_receive('bar')->with(1, 'two');
            $mock->bar(1, 'two');
            is($mock->__check, '');
        };
    };

    context 'multiple mocks for the same message' => sub {
        it 'should check the next matching expectation when the first fails' => sub {
            my $mock = rmock('foo');
            $mock->should_receive('bar');
            $mock->should_receive('bar');
            $mock->bar;
            $mock->bar;
            is($mock->__check, '');
        };

        it 'should pass when different argument matching is required' => sub {
            my $mock = rmock('foo');
            $mock->should_receive('bar')->with(1);
            $mock->should_receive('bar')->with(2);
            $mock->bar(2);
            $mock->bar(1);
            is($mock->__check, '');
        };

        it 'should fail when the combined call constraints are exhausted' => sub {
            my $mock = rmock('foo')->__cancel;
            $mock->should_receive('bar');
            $mock->should_receive('bar');
            $mock->bar;
            $mock->bar;
            $mock->bar;
            is($mock->__check, "Expected 'bar' to be called 1 time on 'foo', but it was called 2 times.");
        };
    };

};

runtests unless caller;

