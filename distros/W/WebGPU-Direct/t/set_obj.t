use v5.30;
use Test::More;
use Scalar::Util qw/refaddr/;

use WebGPU::Direct;

my $wgpu = WebGPU::Direct->new;

my $h = {
  x => 1,
  y => 2,
  z => 3,
};
my $obj = $wgpu->Origin3D->new($h);

my $rl_pack    = \&WebGPU::Direct::Origin3D::pack;
my $pack_calls = 0;
local *WebGPU::Direct::Origin3D::pack = sub { $pack_calls++; $rl_pack->(@_) };

my $rl_unpack    = \&WebGPU::Direct::Origin3D::unpack;
my $unpack_calls = 0;
local *WebGPU::Direct::Origin3D::unpack = sub { $unpack_calls++; $rl_unpack->(@_) };

isnt( refaddr $h, refaddr %$obj, 'Original hash does not share an address' );
ok( explain($h),   'The original hash can be iterated without segfault' );
ok( explain($obj), 'The obj can be iterated without segfault' );
unlike( $obj->bytes, qr/^\0+$/, 'Bytes are not all empty' );

{
  $pack_calls   = 0;
  $unpack_calls = 0;
  my $a = $wgpu->TexelCopyTextureInfo->new( origin => $h );

  is( $pack_calls,   1, 'Limits pack was only called once with a hash' );
  is( $unpack_calls, 0, 'Limits unpack was never called with a hash' );
  isnt( refaddr $h, refaddr $a->origin->%*, 'Original hash does not share an address from set_obj' );
  ok( explain($h), 'The original hash can be iterated without segfault' );
  ok( explain($a), 'The obj can be iterated without segfault' );

  is( $a->origin->x, 1, 'set_obj got a good value' );
  is( $a->origin->y, 2, 'set_obj got a good value' );
  is( $a->origin->z, 3, 'set_obj got a good value' );
  unlike( $a->origin->bytes, qr/^\0+$/, 'Bytes are not all empty' );
}

{
  $pack_calls   = 0;
  $unpack_calls = 0;
  my $a = $wgpu->TexelCopyTextureInfo->new( origin => $obj );

  is( $pack_calls,   0, 'Limits pack was not called since it is copying' );
  is( $unpack_calls, 1, 'Limits unpack was never called with a hash' );
  isnt( refaddr $obj, refaddr $a->origin->%*, 'Original hash does not share an address from set_obj' );
  ok( explain($obj), 'The original obj can be iterated without segfault' );
  ok( explain($a),   'The obj can be iterated without segfault' );

  is( $a->origin->x, 1, 'set_obj got a good value' );
  is( $a->origin->y, 2, 'set_obj got a good value' );
  is( $a->origin->z, 3, 'set_obj got a good value' );
  unlike( $a->origin->bytes, qr/^\0+$/, 'Bytes are not all empty' );

  $obj->x(0);
  is( $a->origin->x, 1, 'set_obj made a real copy' );
  unlike( $obj, qr/^\0+$/, 'Source bytes are not all empty' );
}

# Defaults with inline structs
{
  my $a = $wgpu->RenderPipelineDescriptor->new;

  unlike( $a->bytes,              qr/^\0+$/, 'Default object is not all empty' );
  unlike( $a->multisample->bytes, qr/^\0+$/, 'Default object is not all empty' );
  is( $a->multisample->count, 1, 'Default used the default of inline struct' );
}

done_testing;
