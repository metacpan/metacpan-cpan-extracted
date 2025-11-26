use v5.30;
use Test::More;
use Scalar::Util qw/refaddr/;

use WebGPU::Direct;

my $ref        = {};
my $addr       = refaddr($ref);
my $opaque_obj = WebGPU::Direct::Opaque::__wrap( int $addr );

my $obj = WebGPU::Direct::SurfaceSourceXlibWindow->new(
  {
    sType   => WebGPU::Direct::SType->surfaceSourceXlibWindow,
    display => $opaque_obj,
    window  => 42,
  }
);

is( $$opaque_obj,      $addr, 'Object is just a ref to address' );
is( $obj->display->$*, $addr, 'New obj maintains address' );

$obj->pack;
is( $obj->display->$*, $addr, 'Obj maintains address after a pack' );

$obj->unpack;
is( $obj->display->$*, $addr, 'Obj maintains address after an unpack' );

$obj->pack;
is( $obj->display->$*, $addr, 'Obj maintains address after a second pack' );

$obj->unpack;
is( $obj->display->$*, $addr, 'Obj maintains address after a second unpack' );

done_testing;
