use lib qw(t/lib);
use Test::Double;
use Test::More;
use t::Utils;

subtest 'at least' => sub {
    my $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_least(2)->returns('foo');
    $foo->bar;
    $foo->bar;
    Test::Double->verify;

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_least(2)->returns('foo');
    $foo->bar;
    my $result = Test::Double->verify_result;
    is $result->{bar}->{at_least}, 0;
};

done_testing;
