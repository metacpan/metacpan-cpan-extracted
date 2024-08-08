use strict;
use Test::More;

use WebGPU::Direct;

my $wgpu = WebGPU::Direct->new;

my $adapter = $wgpu->requestAdapter( { compatibleSurface => undef } );
my $device  = $adapter->requestDevice;

my @cubeVertexArray = (
  #<<<
  # float4 position, float4 color, float2 uv,
  1, -1, 1, 1,       1, 0, 1, 1,   0, 1,
  -1, -1, 1, 1,      0, 0, 1, 1,   1, 1,
  #>>>
);

my $cube = {
  cubeVertexSize     => 4 * 10,                           # Byte size of one cube vertex.
  cubePositionOffset => 0,                                # Byte offset of cube position attribute
  cubeColorOffset    => 4 * 4,                            # Byte offset of cube vertex color attribute.
  cubeUVOffset       => 4 * 8,                            # Byte offset of cube UV attribute
  cubeVertexCount    => scalar @cubeVertexArray,
  cubeVertexArray    => pack( "f*", @cubeVertexArray ),
};

# Create a vertex buffer from the cube data.
my $verticesBuffer = $device->createBuffer(
  {
    size             => length( $cube->{cubeVertexArray} ),
    usage            => $wgpu->BufferUsage->vertex,
    mappedAtCreation => 1,
  }
);

my $poison = (0xff) x ( length( $cube->{cubeVertexArray} ) );
my $null   = "\0" x ( length( $cube->{cubeVertexArray} ) );
my $mb     = $verticesBuffer->getMappedRange;

is( $mb->{buffer}, $null, 'Buffer was correctly sized' );
is( $mb->{size}, length( $cube->{cubeVertexArray} ), 'Reported size is correct' );

$mb->buffer($poison);
is( $mb->{buffer}, $poison, 'Able to save the buffer' );
is( $mb->buffer,   $poison, 'Buffer fn returns the value' );

$mb->{buffer} = $cube->{cubeVertexArray};
is( $mb->{buffer}, $cube->{cubeVertexArray}, 'Buffer in hash what is expected' );

$mb->unpack;
is( $mb->buffer, $poison, 'Setting buffer manually disappears after unpack' );

$mb->{buffer} = $cube->{cubeVertexArray};
$mb->pack;
is( $mb->{buffer}, $cube->{cubeVertexArray}, 'Buffer in hash what is expected after pack' );

$mb->unpack;
is( $mb->{buffer}, $cube->{cubeVertexArray}, 'Calling unpack preserves the buffer' );
is( $mb->buffer,   $cube->{cubeVertexArray}, 'Buffer fn agrees with hash' );

$mb->buffer('');
is( $mb->buffer, $null, 'Setting a buffer to "" empties it' );
is( length( $mb->buffer ), length( $cube->{cubeVertexArray} ), 'Emptying buffer maintains the size' );

done_testing;
