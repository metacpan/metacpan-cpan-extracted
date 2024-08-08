use strict;
use Test::More;

use WebGPU::Direct;

my $c;
my @s;

@s = qw/r g b a/;

$c = WebGPU::Direct::Color->new;
foreach (@s)
{
  is( $c->$_, 0, "$_ is set to a default" );
}

$c = WebGPU::Direct::Color->new( [1] );
is( $c->r, 1, "r is set to array value" );
foreach (qw/g b a/)
{
  is( $c->$_, 0, "$_ is set to a default" );
}

$c = WebGPU::Direct::Color->new( [ 1, 2, 3, 4 ] );
foreach ( keys @s )
{
  my $n = $s[$_];
  is( $c->$n, 1 + $_, "$_ is set to a provided value" );
}

@s = qw/width height depthOrArrayLayers/;

$c = WebGPU::Direct::Extent3D->new;
is( $c->width, 0, 'width is set to a default value' );
foreach (qw/height depthOrArrayLayers/)
{
  is( $c->$_, 1, "$_ is set to a default value" );
}

$c = WebGPU::Direct::Extent3D->new( [ 2, 3, 4 ] );
foreach ( keys @s )
{
  my $n = $s[$_];
  is( $c->$n, 2 + $_, "$_ is set to a provided value" );
}

done_testing;
