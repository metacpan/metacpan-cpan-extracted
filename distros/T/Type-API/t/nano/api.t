use strict;
use warnings;
use Test::More;

use Type::Nano qw( type );

my $type1 = type 'Foo', sub { defined $_ and $_ eq 'Foo' };

ok  $type1->check( 'Foo' );
ok !$type1->check( 'Bar' );
is $type1->get_message( undef ), 'Undef did not pass type constraint Foo';
is $type1->get_message( 'Bar' ), 'Value "Bar" did not pass type constraint Foo';
like $type1->get_message( [] ), qr/Reference ARRAY\S+ did not pass type constraint Foo/;
ok $type1->( 'Foo' );
ok !eval { $type1->( undef ); 1 };
is "$type1", "Foo";
ok $type1->DOES( 'Type::API::Constraint' );

my $type2 = type sub { defined $_[0] and $_[0] eq 'Bar' };

ok !$type2->check( 'Foo' );
ok  $type2->check( 'Bar' );
is $type2->get_message( undef ), 'Undef did not pass type constraint __ANON__';
is $type2->get_message( 'Foo' ), 'Value "Foo" did not pass type constraint __ANON__';
like $type2->get_message( [] ), qr/Reference ARRAY\S+ did not pass type constraint __ANON__/;
ok $type2->( 'Bar' );
ok !eval { $type2->( undef ); 1 };
is "$type2", "__ANON__";
ok $type2->DOES( 'Type::API::Constraint' );

done_testing;
