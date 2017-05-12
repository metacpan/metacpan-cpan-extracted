use lib qw(t/lib);
use Test::Double;
use Test::More;
use t::Utils;

subtest 'verify_result' => sub {
    my $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_least(2)->returns('foo');
    $foo->bar;
    $foo->bar;
    my $result = Test::Double->verify_result;
    ok $result->{bar}->{at_least};

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_most(2)->returns('foo');
    $foo->bar;
    $foo->bar;
    $result = Test::Double->verify_result;
    ok $result->{bar}->{at_most};

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('bar')->times(2)->returns('foo');
    $foo->bar;
    $foo->bar;
    $result = Test::Double->verify_result;
    ok $result->{bar}->{times};

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_least(2)->returns('foo');
    mock($foo)->expects('hoo')->at_least(2)->returns('foo');
    $foo->bar;
    $foo->hoo;

    mock($foo)->expects('yoo')->times(2)->returns('foo');
    $foo->yoo;
    $foo->yoo;
    $foo->yoo;

    $result = Test::Double->verify_result;
    ok ! $result->{bar}->{at_least};
    ok ! $result->{hoo}->{at_least};
    ok ! $result->{yoo}->{times};
};

done_testing;
