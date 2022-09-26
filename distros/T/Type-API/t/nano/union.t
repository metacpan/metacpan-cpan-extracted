use strict;
use warnings;
use Test::More;

use Type::Nano qw( HashRef ArrayRef union );

my $u1 = union 'ArrayOrHashRef' => [ ArrayRef, HashRef ];
ok  $u1->check( [] );
ok  $u1->check( {} );
ok !$u1->check( \0 );

my $u2 = union [ ArrayRef, HashRef ];
ok  $u2->check( [] );
ok  $u2->check( {} );
ok !$u2->check( \0 );

done_testing;
