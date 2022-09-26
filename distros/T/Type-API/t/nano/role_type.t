use strict;
use warnings;
use Test::More;

use Type::Nano qw( role_type );

{
	package Local::DoesXyz;
	sub DOES { $_[1] eq 'Xyz' }
}

my $r1 = role_type 'Xyz';
ok $r1->check( bless {}, 'Local::DoesXyz' );
ok !$r1->check( bless {}, 'Local::DoesXyz2' );

done_testing;
