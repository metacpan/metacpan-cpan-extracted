#!perl -T
use strict;
use warnings;

# smartmatch dependency
use 5.010001;

# These tests are to make sure that no unexpected argument matches occur
# because we are using smartmatching

use Test::More;
use Test::Magpie qw( mock inspect );

use constant Invocation => 'Test::Magpie::Invocation';

subtest 'Array' => sub {
    my $mock = mock;

    $mock->array( [1, 2, 3] );
    isa_ok inspect($mock)->array( [1, 2, 3] ), Invocation, 'Array ~~ Array';

    $mock->hash( {a => 1} );
    is inspect($mock)->hash( [qw/a b c/] ), undef, 'Hash ~~ Array';

    $mock->regexp( qr/^hell/ );
    is inspect($mock)->regexp( [qw/hello/] ), undef, 'Regexp ~~ Array';

    $mock->undef(undef);
    is inspect($mock)->undef( [undef, 'anything'] ), undef, 'Undef ~~ Array';

    $mock->any(1);
    is inspect($mock)->any( [1,2,3] ), undef, 'Any ~~ Array';
};

subtest 'Array (nested)' => sub {
    my $mock = mock;

    $mock->nested_array( [1, 2, [3, 4]] );
    isa_ok inspect($mock)->nested_array( [1, 2, [3, 4]] ), Invocation,
        'Array[Array] ~~ Array[Array]';

    $mock->nested_hash( [1, 2, {3 => 4}] );
    isa_ok inspect($mock)->nested_hash( [1, 2, {3 => 4}] ), Invocation,
        'Array[Hash] ~~ Array[Hash]';

    $mock->array( [1, 2, 3] );
    is inspect($mock)->array( [1, 2, [3, 4]] ), undef,
        'Array ~~ Array[Array]';

    is inspect($mock)->array( [1, 2, {3 => 4}] ), undef,
        'Array ~~ Array[Hash]';

};

subtest 'Hash' => sub {
    my $mock = mock;

    $mock->hash( {a => 1, b => 2, c => 3} );
    isa_ok inspect($mock)->hash( {c => 3, b => 2, a => 1} ), Invocation,
        'Hash ~~ Hash';

    is inspect($mock)->hash( {a => 3, b => 2, c => 1} ), undef,
        'Hash ~~ Hash - same keys, different values';

    $mock->array( [qw/a b c/] );
    is inspect($mock)->array( {a => 1} ), undef, 'Array ~~ Hash';

    $mock->regexp(qr/^hell/);
    is inspect($mock)->regexp( {hello => 1} ), undef, 'Regexp ~~ Hash';

    $mock->any('a');
    is inspect($mock)->any( {a => 1, b => 2} ), undef, 'Any ~~ Hash';
};

subtest 'Code' => sub {
    my $mock = mock;

    $mock->array( [1, 2, 3] );
    is inspect($mock)->array( sub {1} ), undef, 'Array ~~ Code';

    # empty arrays always match
    $mock->array( [] );
    is inspect($mock)->array( sub {0} ), undef, 'Array(empty) ~~ Code';

    $mock->hash( {a => 1, b => 2} );
    is inspect($mock)->hash( sub {1} ), undef, 'Hash ~~ Code';

    # empty hashes always match
    $mock->hash( {} );
    is inspect($mock)->hash( sub {0} ), undef, 'Hash(empty) ~~ Code';

    $mock->code('anything');
    is inspect($mock)->code( sub {1} ), undef, 'Any ~~ Code';

    $mock->code( sub {0} );
    is inspect($mock)->code( sub {1} ), undef, 'Code ~~ Code';

    # same coderef should match
    $mock = mock;
    my $sub = sub {0};
    $mock->code($sub);
    isa_ok inspect($mock)->code($sub), Invocation,  'Code == Code';
};

subtest 'Regexp' => sub {
    my $mock = mock;

    $mock->array( [qw/hello bye/] );
    is inspect($mock)->array( qr/^hell/ ), undef, 'Array ~~ Regexp';

    $mock->hash( {hello => 1} );
    is inspect($mock)->hash( qr/^hell/ ), undef, 'Array ~~ Regexp';

    $mock->any('hello');
    is inspect($mock)->any( qr/^hell/ ), undef, 'Any ~~ Regexp';
};

subtest 'Undef' => sub {
    my $mock = mock;

    $mock->undef(undef);
    isa_ok inspect($mock)->undef(undef), Invocation, 'Undef ~~ Undef';

    $mock->any(1);
    is inspect($mock)->any(undef), undef, 'Any ~~ Undef';

    is inspect($mock)->undef(1), undef, 'Undef ~~ Any'
};

{
    package My::Object;
    use Moose;
    has 'value' => (is => 'ro', required => 1);

    package My::Overloaded;
    use Moose;
    use overload '~~' => 'match', 'bool' => sub {1};
    has 'value' => (is => 'ro', required => 1);
    sub match {
        no warnings; # suppress smartmatch warnings
        my ($self, $other) = @_;
        return $self->value ~~ $other;
    }
}

subtest 'Object (overloaded)' => sub {
    my $mock = mock;
    my $overloaded = My::Overloaded->new(value => 5);

    $mock->any( [1,3,5] );
    is inspect($mock)->any($overloaded), undef, 'Any ~~ Object';

    $mock->object($overloaded);
    isa_ok inspect($mock)->object($overloaded), Invocation, 'Object == Object';
};

subtest 'Object (non-overloaded)' => sub {
    my $mock = mock;
    my $obj = My::Object->new(value => 5);

    $mock->object($obj);
    isa_ok inspect($mock)->object($obj), Invocation, 'Object == Object';

    $mock->mock($mock);
    isa_ok inspect($mock)->mock($mock), Invocation, 'Mock == Mock';

    # This scenario won't invoke the overload method because smartmatching
    # rules take precedence over overloading. The comparison is meant to be
    # `$obj eq 'My::Object` but this doesn't seem to be happening
    $mock->object($obj);
    is inspect($mock)->object('My::Object'), undef, 'Object ~~ Any';

};

subtest 'Num' => sub {
    my $mock = mock;

    $mock->int(5);
    isa_ok inspect($mock)->int(5), Invocation, 'Int == Int';
    isa_ok inspect($mock)->int(5.0), Invocation, 'Int == Num';

    $mock->str('42x');
    is inspect($mock)->str(42), undef, 'Str ~~ Num (42x == 42)';
};

subtest 'Str' => sub {
    my $mock = mock;

    $mock->str('foo');
    isa_ok inspect($mock)->str('foo'), Invocation, 'Str eq Str';
    is inspect($mock)->str('Foo'), undef, 'Str ne Str';
    is inspect($mock)->str('bar'), undef, 'Str ne Str';

    $mock->int(5);
    isa_ok inspect($mock)->int("5.0"), Invocation, 'Int ~~ Num-like';
    is inspect($mock)->int("5x"), undef, 'Int !~ Num-like (5 eq 5x)';

    TODO: {
        local $TODO = "string still looks_like_number in spite of whitespace";
        is inspect($mock)->int("5\n"), undef, 'Int !~ Num-like (5 eq 5\\n)';
    }
};

done_testing(10);
