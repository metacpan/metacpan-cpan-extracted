=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Types::Capabilities>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'Types::Capabilities';
use Test2::Tools::Spec;
use Data::Dumper;

use lib 't/lib';
use Local::Example::Mappable;
use Local::Example::Greppable;
use Local::Example::Sortable;
use Local::Example::Reversible;
use Local::Example::Countable;
use Local::Example::Joinable;
use Local::Example::Eachable;
use Local::Example::Enqueueable;
use Local::Example::Dequeueable;
use Local::Example::Peekable;
use Local::Example::Pushable;
use Local::Example::Poppable;

describe "class `$CLASS`" => sub {

	tests 'type Mappable' => sub {
		ok( Types::Capabilities->has_type( q[Mappable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Mappable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ map / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::ARRAYREF], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Mappable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[map] );

		is( [ $coerced->map( sub { uc $_ } ) ], [ qw/ FOO BAR BAZ / ], 'coerced object has a working `map` method' );
	};

	tests 'type Greppable' => sub {
		ok( Types::Capabilities->has_type( q[Greppable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Greppable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ grep / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::ARRAYREF], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Greppable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz/ ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[grep] );

		is( [ $coerced->grep( sub { /^b/ } ) ], [ qw/ bar baz / ], 'coerced object has a working `grep` method' );
	};

	tests 'type Sortable' => sub {
		ok( Types::Capabilities->has_type( q[Sortable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Sortable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ sort / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::ARRAYREF], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Sortable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[sort] );

		is( [ $coerced->sort( sub { $_[0] cmp $_[1] } ) ], [ qw/ bar baz foo / ], 'coerced object has a working `sort` method' );
	};

	tests 'type Reversible' => sub {
		ok( Types::Capabilities->has_type( q[Reversible] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Reversible] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ reverse / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::ARRAYREF], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Reversible];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[reverse] );

		is( [ $coerced->reverse ], [ qw/ baz bar foo / ], 'coerced object has a working `reverse` method' );
	};

	tests 'type Countable' => sub {
		ok( Types::Capabilities->has_type( q[Countable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Countable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ count / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::ARRAYREF], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Countable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[count] );

		is( scalar($coerced->count), 3, 'coerced object has a working `count` method' );
	};

	tests 'type Joinable' => sub {
		ok( Types::Capabilities->has_type( q[Joinable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Joinable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ join / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::ARRAYREF], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Joinable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[join] );

		is( scalar($coerced->join('!')), 'foo!bar!baz', 'coerced object has a working `join` method' );
		is( scalar($coerced->join()), 'foo,bar,baz', '... and the separator is optional' );
	};

	tests 'type Eachable' => sub {
		ok( Types::Capabilities->has_type( q[Eachable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Eachable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ each / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::ARRAYREF], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Eachable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[each] );

		my @got;
		$coerced->each( sub { push @got, [$_] } );
		is( \@got, [['foo'],['bar'],['baz']], 'coerced object has a working `each` method' );
	};

	tests 'type Enqueueable' => sub {
		ok( Types::Capabilities->has_type( q[Enqueueable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Enqueueable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ enqueue / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::QUEUE], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Enqueueable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::QUEUE] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[enqueue] );

		$coerced->enqueue( 'quux' );
		is( [ @$coerced ], [ qw/ foo bar baz quux / ], 'coerced object has a working `enqueue` method' );
	};

	tests 'type Dequeueable' => sub {
		ok( Types::Capabilities->has_type( q[Dequeueable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Dequeueable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ dequeue / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::QUEUE], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Dequeueable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::QUEUE] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[dequeue] );

		is( scalar($coerced->dequeue), 'foo', 'coerced object has a working `dequeue` method' );
		is( [ @$coerced ], [ qw/ bar baz / ], '... which removes the item from the queue' );
	};

	tests 'type Peekable' => sub {
		ok( Types::Capabilities->has_type( q[Peekable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Peekable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ peek / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::QUEUE], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Peekable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::QUEUE] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[peek] );

		is( scalar($coerced->peek), 'foo', 'coerced object has a working `peek` method' );
		is( [ @$coerced ], [ qw/ foo bar baz / ], '... which doesn\'t alter the queue' );
	};

	tests 'type Pushable' => sub {
		ok( Types::Capabilities->has_type( q[Pushable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Pushable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ push / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::STACK], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Pushable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::STACK] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[push] );

		$coerced->push( 'quux' );
		is( [ @$coerced ], [ qw/ foo bar baz quux / ], 'coerced object has a working `push` method' );
	};

	tests 'type Poppable' => sub {
		ok( Types::Capabilities->has_type( q[Poppable] ), 'type exists' );

		my $type = Types::Capabilities->get_type( q[Poppable] );
		isa_ok( $type, q[Types::Capabilities::Constraint] );
		isa_ok( $type, q[Type::Tiny::Duck] );
		is( [ sort @{ $type->methods } ], [ qw/ pop / ], 'requires the correct methods' );
		ok( $type->can_be_inlined, 'type can be inlined' );
		ok( $type->has_coercion, 'type has a coercion' );
		ok( $type->coercion->can_be_inlined, 'coercion can be inlined' );
		is( $type->{autobox}, q[Types::Capabilities::CoercedValue::STACK], 'type has correct autobox package' );

		my $eg_class = q[Local::Example::Poppable];
		ok(  $type->check( $eg_class->new ), 'example object passes type check' );
		ok( !$type->check(          undef ), 'undef fails type check' );
		ok( !$type->check(              0 ), 'zero fails type check' );
		ok( !$type->check(              1 ), 'one fails type check' );
		ok( !$type->check(             [] ), 'arrayref fails type check' );
		ok( !$type->check(             {} ), 'hashref fails type check' );

		ok( $type->coercion->has_coercion_for_value( [] ), 'an arrayref is theoretically coercible' );

		my $coerced = $type->coerce( [ qw/ foo bar baz / ] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::STACK] );
		isa_ok( $coerced, q[Types::Capabilities::CoercedValue::ARRAYREF] );
		ok( $type->check( $coerced ), 'coerced value passes type check' );
		can_ok( $coerced, q[pop] );

		is( scalar($coerced->pop), 'baz', 'coerced object has a working `pop` method' );
		is( [ @$coerced ], [ qw/ foo bar / ], '... which removes the item from the queue' );
	};
};

done_testing;
