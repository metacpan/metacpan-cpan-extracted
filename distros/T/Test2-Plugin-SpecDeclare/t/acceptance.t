use Test2::Bundle::Extended;
use Test2::Tools::Spec qw{
    describe
    tests it
    case
    before_all  around_all  after_all
    before_case around_case after_case
    before_each around_each after_each
    mini
    iso   miso
    async masync
};
use Test2::Plugin::SpecDeclare;

tests no_parse => sub { ok(1, "no parse") };

tests simple(mini => 1) {
    ok(1, "simple");
}

mini mini {
    ok(1, "mini");
}

iso iso {
    ok(1, "iso");
}

describe outer {
    my $x;
    before_all before { ok(1) }
    after_all after { ok(1) }
    around_all around(mini => 0) { shift->() }

    before_each before { ok(1) }
    after_each after { ok(1) }
    around_each around(mini => 0) { shift->() }

    case a { $x = 'a' }
    case b { $x = 'b' }

    tests x { is($x, in_set('a', 'b'), "got x") }
}

done_testing;
