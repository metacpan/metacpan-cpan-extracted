use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;

# ------------------------------------------------------------
# Dummy package for testing
# ------------------------------------------------------------
{
    package Dummy::Thing;

    sub foo { return "original foo" }
    sub bar { return "original bar" }

    package Dummy::Dep;

    sub value { return "real dependency" }
}

# ------------------------------------------------------------
# Test shorthand mock syntax
# ------------------------------------------------------------
subtest 'mock shorthand' => sub {

    mock 'Dummy::Thing::foo' => sub { "mocked foo" };

    is Dummy::Thing::foo(), "mocked foo", 'mock shorthand replaced method';

    unmock 'Dummy::Thing::foo';

    is Dummy::Thing::foo(), "original foo", 'unmock shorthand restored method';
};

# ------------------------------------------------------------
# Test spy shorthand
# ------------------------------------------------------------
subtest 'spy shorthand' => sub {

    my $spy = spy 'Dummy::Thing::bar';

    Dummy::Thing::bar('a', 'b');

    my @calls = $spy->();

    is scalar(@calls), 1, 'spy captured one call';
    is_deeply $calls[0], ['Dummy::Thing::bar', 'a', 'b'], 'spy captured correct args';

    unmock 'Dummy::Thing::bar';
};

# ------------------------------------------------------------
# Test inject shorthand
# ------------------------------------------------------------
subtest 'inject shorthand' => sub {

    my $fake = bless { val => 123 }, 'FakeDep';

    inject 'Dummy::Dep::value' => $fake;

    my $obj = Dummy::Dep::value();

    isa_ok $obj, 'FakeDep', 'inject returned fake dependency';
    is $obj->{val}, 123, 'fake dependency has correct value';

    restore_all 'Dummy::Dep';

    is Dummy::Dep::value(), "real dependency", 'restore_all(package) restored dependency';
};

# ------------------------------------------------------------
# Test restore_all global
# ------------------------------------------------------------
subtest 'restore_all global' => sub {

    mock 'Dummy::Thing::foo' => sub { "globally mocked" };
    mock 'Dummy::Thing::bar' => sub { "globally mocked bar" };

    is Dummy::Thing::foo(), "globally mocked", 'foo mocked';
    is Dummy::Thing::bar(), "globally mocked bar", 'bar mocked';

    restore_all();

    is Dummy::Thing::foo(), "original foo", 'foo restored globally';
    is Dummy::Thing::bar(), "original bar", 'bar restored globally';
};

done_testing();
