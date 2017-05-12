use lib qw(t/lib);
use Test::Double;
use Test::More;
use t::Utils;
use Data::Dumper;

subtest 'at_most' => sub {
    my $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_most(2);
    $foo->bar;
    $foo->bar;
    Test::Double->verify;

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_most(2);
    $foo->bar;
    Test::Double->verify;

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('bar')->at_most(2);
    $foo->bar;
    $foo->bar;
    $foo->bar;
    my $result = Test::Double->verify_result;
    is $result->{bar}->{at_most}, 0;
};

done_testing;
