use strict;
use warnings;
use Test::More;

{
	package MockFoo;
	sub isa {
		return 1 if $_[1] eq 'Foo';
		shift->isa( @_ );
	}
}

{
	package FooChild;
	our @ISA = qw( Foo );
}

use Type::Tiny::XS;
my $check = Type::Tiny::XS::get_coderef_for('InstanceOf[Foo]');

ok(   $check->( bless [], "Foo" ) );
ok(   $check->( bless [], "MockFoo" ) );
ok(   $check->( bless [], "FooChild" ) );
ok( ! $check->( bless [], "Bar" ) );

done_testing;
