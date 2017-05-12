#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Validate::Tiny;

my $rules = {
    fields => [qw/a b/],
    checks => [ a => sub { $_[0] < 5 ? undef : 'Error' } ]
};
my $result = Validate::Tiny->check( { a=> 1 }, $rules );
my $r2 = Validate::Tiny::validate( { a => 1 }, $rules );

# Sanity
{
    local $@;
    eval { $result->something };
    ok $@, "wrong accessor";

    eval { $result->data('something') };
    ok $@, "wrong data field";

    eval { $result->error('something') };
    ok $@, "wrong error field";
}

# Empty fields list
{
    my $rules = { fields => [] };
    my $result = Validate::Tiny->check( { a => 1 }, $rules );
    is $result->data('a'), 1;
    is $result->data('b'), undef;
}

ok( $result->success, 'success' );
is( $result->data('a'), 1, 'functional access data' );
is( $result->data->{a}, 1, 'hash access data' );
is( $result->data('b'), undef, 'return undef if field has no value 1' );
is( $result->data->{b}, undef, 'return undef if field has no value 2' );
eval { $result->data('c') };
ok($@, 'croaks if the field has not been defined');
is( $result->data->{c}, undef, 'returns undef on undefined field via hash' );

is_deeply( $result->data,    $r2->{data}, 'data match' );
$result->data->{a} = 'foo';
is_deeply( $result->data,    $r2->{data}, 'can not change data' );

is_deeply( $result->error,   $r2->{error}, 'error match' );
$result->error->{a} = 'foo';
is_deeply( $result->error,   $r2->{error}, 'can not change error' );

is_deeply( $result->success, $r2->{success}, 'success match' );
is_deeply( $result->to_hash, $r2, 'to_hash match' );

$result = Validate::Tiny->check( { a => 11 }, $rules );
$r2 = Validate::Tiny::validate( { a => 11 }, $rules );
is( $result->error('a'), 'Error', 'functional error' );
is( $result->error->{a}, 'Error', 'hash error' );
is_deeply( $result->data,    $r2->{data} );
is_deeply( $result->error,   $r2->{error} );
is_deeply( $result->success, $r2->{success} );
is_deeply( $result->to_hash, $r2 );

$rules->{checks} = [
    a => sub { $_[0] < 5 ? undef : 'ErrorA' },
    b => sub { $_[0] < 2 ? undef : 'ErrorB' }
];

# New and filters
{
    my $v = Validate::Tiny->new(
        filters => {
            only_digits => sub {
                my $val = shift;
                return unless defined $val;
                $val =~ s/\D//g;
                return $val;
            }
        }
    );

    my $rules = {
        fields  => ['a'],
        filters => [ a => Validate::Tiny::filter( 'trim', 'only_digits' ) ]
    };
    $v->check( { a => ' abc123 ' }, $rules );

    is $v->data->{a}, '123';
}

done_testing;
