use lib qw(t/lib);
use Test::Double;
use Test::More;
use t::Utils;

subtest 'with' => sub {
    my $foo = t::Foo->new;
    mock($foo)->expects('bar')->with(1)->returns(2);
    is $foo->bar(1), 2, "with 1";
    Test::Double->verify;

    $foo = t::Foo->new;
    mock($foo)->expects('baz')->with('foo')->returns(2);
    is $foo->baz('foo'), 2, "return 2";
    Test::Double->verify;

    $foo = t::Foo->new;
    my $bar = t::Bar->new;
    mock($foo)->expects('baz')->with($bar)->returns(2);
    is $foo->baz($bar), 2;
    Test::Double->verify;

    $foo = t::Foo->new;
    mock($foo)->expects('baz')->with('foo', 'bar', [1, 2, 3])->returns(2);
    is $foo->baz('foo', 'bar', [1, 2, 3]), 2;
    Test::Double->verify;

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('baz')->with('foo', 'bar', [1, 2, 3])->returns(2);
    $foo->baz('foo', 'bar', [1, 2, 3, 4]);
    my $result = Test::Double->verify_result;
    is $result->{baz}->{with}->{1}, 0;
};

done_testing;
