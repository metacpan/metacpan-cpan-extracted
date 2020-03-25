use strict;
use warnings;
use Test::More;
use Test::Fatal;

package Geometry {
	use Zydeco;
	
	class Point {
		has *x ( is => rw, type => Int, default => 0 );
		has *y ( is => rw, type => Int, default => 0 );
		method clear () {
			$self->x(0);
			$self->y(0);
		}
	}
	
	class Point3D is Point {
		has *z ( is => rw, type => Int, default => 0 );
		after clear = $self->z(0);
	}
}

my $point = Geometry->new_point3d;
$point->x(1);
$point->y(2);
$point->z(3);

is(
	$point->x,
	1,
);

is(
	$point->y,
	2,
);

is(
	$point->z,
	3,
);

$point->clear;

is(
	$point->x,
	0,
);

is(
	$point->y,
	0,
);

is(
	$point->z,
	0,
);

isnt(
	exception { $point->clear("yeah") },
	undef,
);

done_testing;
