use Test::More;
eval "use Test::Memory::Cycle";
plan skip_all => "Test::Memory::Cycle required for testing memory leaks" if $@;
plan skip_all => "set TEST_MEMORY or TEST_ALL to enable this test"
    unless $ENV{TEST_MEMORY} or $ENV{TEST_ALL};

use Test::Double;
use t::Utils;

{
    my $stub = t::Foo->new;
    stub($stub)->bar('BAR');
    memory_cycle_ok($stub);
}

{
    my $mock = t::Foo->new;
    mock($mock)->expects('bar')->returns('BAR');
    memory_cycle_ok($mock);
}

done_testing;
