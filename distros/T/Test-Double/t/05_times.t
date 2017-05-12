use lib qw(t/lib);
use Test::Double;
use Test::More;
use t::Utils;

subtest 'times' => sub {
    my $foo = t::Foo->new;
    mock($foo)->expects('bar')->times(2);
    $foo->bar;
    $foo->bar;
    Test::Double->verify;

    Test::Double->reset;
    $foo = t::Foo->new;
    mock($foo)->expects('bar')->times(2);
    $foo->bar;
    my $result = Test::Double->verify_result;
    is $result->{bar}->{times}, 0;
};

done_testing;
