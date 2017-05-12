#!/usr/bin/perl -T

use strict;
use warnings;

# smartmatch dependency
use 5.010001;

# These tests are to make sure that no unexpected argument matches occur
# because we are using smartmatching

use Test::More tests => 11;

BEGIN { use_ok 'Test::Mocha' }

subtest 'X ~~ Array' => sub {
    my $mock = mock;

    $mock->array( [ 1, 2, 3 ] );
    called_ok { $mock->array( [ 1, 2, 3 ] ) } 'Array ~~ Array';
    called_ok { $mock->array( [ 1, 2 ] ) } &times(0),
      'Array.size != Array.size';

    $mock->hash( { a => 1 } );
    called_ok { $mock->hash( [qw/a b c/] ) } &times(0), 'Hash ~~ Array';

    $mock->regexp(qr/^hell/);
    called_ok { $mock->regexp( [qw/hello/] ) } &times(0), 'Regexp ~~ Array';

    $mock->undef(undef);
    called_ok { $mock->undef( [ undef, 'anything' ] ) } &times(0),
      'Undef ~~ Array';

    $mock->any(1);
    called_ok { $mock->any( [ 1, 2, 3 ] ) } &times(0), 'Any ~~ Array';
};

subtest 'X ~~ Array (nested)' => sub {
    my $mock = mock;

    $mock->nested_array( [ 1, 2, [ 3, 4 ] ] );
    called_ok { $mock->nested_array( [ 1, 2, [ 3, 4 ] ] ) }
    'Array[Array] ~~ Array[Array]';

    $mock->nested_hash( [ 1, 2, { 3 => 4 } ] );
    called_ok { $mock->nested_hash( [ 1, 2, { 3 => 4 } ] ) }
    'Array[Hash] ~~ Array[Hash]';

    $mock->array( [ 1, 2, 3 ] );
    called_ok { $mock->array( [ 1, 2, [ 3, 4 ] ] ) } &times(0),
      'Array ~~ Array[Array]';

    called_ok { $mock->array( [ 1, 2, { 3 => 4 } ] ) } &times(0),
      'Array ~~ Array[Hash]';
};

subtest 'X ~~ Hash' => sub {
    my $mock = mock;

    $mock->hash( { a => 1, b => 2, c => 3 } );
    called_ok { $mock->hash( { c => 3, b => 2, a => 1 } ) } 'Hash ~~ Hash';

    called_ok { $mock->hash( { a => 3, b => 2, d => 1 } ) } &times(0),
      'Hash ~~ Hash - different keys';

    called_ok { $mock->hash( { a => 3, b => 2, c => 1 } ) } &times(0),
      'Hash ~~ Hash - same keys, different values';

    $mock->array( [qw/a b c/] );
    called_ok { $mock->array( { a => 1 } ) } &times(0), 'Array ~~ Hash';

    $mock->regexp(qr/^hell/);
    called_ok { $mock->regexp( { hello => 1 } ) } &times(0), 'Regexp ~~ Hash';

    $mock->any('a');
    called_ok { $mock->any( { a => 1, b => 2 } ) } &times(0), 'Any ~~ Hash';
};

subtest 'X ~~ Code' => sub {
    my $mock = mock;

    $mock->array( [ 1, 2, 3 ] );
    called_ok {
        $mock->array( sub { 1 } );
    }
    &times(0), 'Array ~~ Code';

    # empty arrays always match
    $mock->array( [] );
    called_ok {
        $mock->array( sub { 0 } );
    }
    &times(0), 'Array(empty) ~~ Code';

    $mock->hash( { a => 1, b => 2 } );
    called_ok {
        $mock->hash( sub { 1 } );
    }
    &times(0), 'Hash ~~ Code';

    # empty hashes always match
    $mock->hash( {} );
    called_ok {
        $mock->hash( sub { 0 } );
    }
    &times(0), 'Hash(empty) ~~ Code';

    $mock->code('anything');
    called_ok {
        $mock->code( sub { 1 } );
    }
    &times(0), 'Any ~~ Code';

    $mock->code( sub { 0 } );
    called_ok {
        $mock->code( sub { 1 } );
    }
    &times(0), 'Code ~~ Code';

    # same coderef should match
    $mock = mock;
    my $sub = sub { 0 };
    $mock->code($sub);
    called_ok { $mock->code($sub) } 'Code == Code';
};

subtest 'X ~~ Regexp' => sub {
    my $mock = mock;

    $mock->array( [qw/hello bye/] );
    called_ok { $mock->array(qr/^hell/) } &times(0), 'Array ~~ Regexp';

    $mock->hash( { hello => 1 } );
    called_ok { $mock->hash(qr/^hell/) } &times(0), 'Array ~~ Regexp';

    $mock->any('hello');
    called_ok { $mock->any(qr/^hell/) } &times(0), 'Any ~~ Regexp';
};

subtest 'X ~~ Undef' => sub {
    my $mock = mock;

    $mock->undef(undef);
    called_ok { $mock->undef(undef) } 'Undef ~~ Undef';

    $mock->any(1);
    called_ok { $mock->any(undef) } &times(0), 'Any ~~ Undef';

    called_ok { $mock->undef(1) } &times(0), 'Undef ~~ Any';
};

{

    package My::Object;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    package My::Overloaded;
    use overload '~~' => 'match', 'bool' => sub { 1 };

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub match {
        no warnings;  # suppress smartmatch warnings
        my ( $self, $other ) = @_;
        return $self->{value} ~~ $other;
    }
}

subtest 'X ~~ Object (overloaded)' => sub {
    my $mock = mock;
    my $overloaded = My::Overloaded->new( value => 5 );

    $mock->any( [ 1, 3, 5 ] );
    called_ok { $mock->any($overloaded) } &times(0), 'Any ~~ Object';

    $mock->object($overloaded);
    called_ok { $mock->object($overloaded) } 'Object == Object';
};

subtest 'X ~~ Object (non-overloaded)' => sub {
    my $mock = mock;
    my $obj = My::Object->new( value => 5 );

    $mock->object($obj);
    called_ok { $mock->object($obj) } 'Object == Object';

    $mock->mock($mock);
    called_ok { $mock->mock($mock) } 'Mock == Mock';

    # This scenario won't invoke the overload method because smartmatching
    # rules take precedence over overloading. The comparison is meant to be
    # `$obj eq 'My::Object` but this doesn't seem to be happening
    $mock->object($obj);
    called_ok { $mock->object('My::Object') } &times(0), 'Object ~~ Any';
};

subtest 'X ~~ Num' => sub {
    my $mock = mock;

    $mock->int(5);
    called_ok { $mock->int(5) } 'Int == Int';
    called_ok { $mock->int(5.0) } 'Int == Num';

    $mock->str('42x');
    called_ok { $mock->str(42) } &times(0), 'Str ~~ Num (42x == 42)';
};

subtest 'X ~~ Str' => sub {
    my $mock = mock;

    $mock->str('foo');
    called_ok { $mock->str('foo') } 'Str eq Str';
    called_ok { $mock->str('Foo') } &times(0), 'Str ne Str';
    called_ok { $mock->str('bar') } &times(0), 'Str ne Str';

    $mock->int(5);
    called_ok { $mock->int("5.0") } 'Int ~~ Num-like';
    called_ok { $mock->int("5x") } &times(0), 'Int !~ Num-like (5 eq 5x)';

  TODO: {
        local $TODO = "string still looks_like_number in spite of whitespace";
        called_ok { $mock->int("5\n") } &times(0),
          'Int !~ Num-like (5 eq 5\\n)';
    }
};
