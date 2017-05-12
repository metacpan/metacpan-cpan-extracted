use Test::More;
use Test::Double;
use t::Utils;

subtest 'stub()' => sub {
    subtest 'should stub out method with coderef' => sub {
        my $foo = t::Foo->new;
        stub($foo)->bar(sub { 'BAR' });

        is $foo->bar => 'BAR';
    };

    subtest 'should stub out method without coderef' => sub {
        for ('BAR', 1, [], {}) {
            my $foo = t::Foo->new;
            stub($foo)->bar($_);

            is $foo->bar => $_;
        }
    };

    subtest 'should not stub out non-target method' => sub {
        my $foo = t::Foo->new;
        stub($foo)->bar(sub { 'BAR' });

        is $foo->baz => 'baz';
    };

    subtest 'should stub out using chain style' => sub {
        my $foo = t::Foo->new;
        stub($foo)->bar('BAR')->baz(sub { 'BAZ' });

        is $foo->bar => 'BAR';
        is $foo->baz => 'BAZ';
    };

    subtest 'should not effect other instance' => sub {
        my $foo = t::Foo->new;
        my $other = t::Foo->new;
        stub($foo)->bar(sub { 'BAR' });
        my $another = t::Foo->new;

        is $foo->bar => 'BAR';
        is $other->bar => 'bar';
        is $another->bar => 'bar';
    };
};

done_testing;
