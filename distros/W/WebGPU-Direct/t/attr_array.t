use strict;
use Test::More;

use WebGPU::Direct;

my $wgpu = WebGPU::Direct->new;

{
  my $a = $wgpu->VertexState->new(
    buffers => [
      {
        arrayStride => 10,
        stepMode    => $wgpu->VertexStepMode->vertex,
        attributes  => [
          {
            # position
            shaderLocation => 0,
            offset         => 0,
            format         => $wgpu->VertexFormat->float32x4,
          },
          {
            # uv
            shaderLocation => 1,
            offset         => 4,
            format         => $wgpu->VertexFormat->float32x2,
          },
        ],
      },
    ],
  );

  my $b = $wgpu->RenderPipelineDescriptor->new(
    {
      vertex => {
        buffers => [
          {
            arrayStride => 10,
            stepMode    => $wgpu->VertexStepMode->vertex,
            attributes  => [
              {
                # position
                shaderLocation => 0,
                offset         => 0,
                format         => $wgpu->VertexFormat->float32x4,
              },
              {
                # uv
                shaderLocation => 1,
                offset         => 4,
                format         => $wgpu->VertexFormat->float32x2,
              },
            ],
          },
        ],
      },
    }
  );

  is( $b->vertex->bufferCount,                  1, 'Buffer count is correct' );
  is( $b->vertex->buffers->[0]->attributeCount, 2, 'Attributes count is correct' );
  unlike( $b->vertex->bytes,               qr/^\0+$/, 'Vertex is not completely empty' );
  unlike( $b->vertex->buffers->[0]->bytes, qr/^\0+$/, 'Vertex buffer is not completely empty' );
}

# TODO Check unpack and pack both create blessed array
subtest 'Enum array', sub
{
  my $window_nic = eval { WebGPU::Direct->new_window_x11( 1, 1 ) };

  if ( !$window_nic )
  {
    plan skip_all => 'Test requires working window';
  }

  my $surface = $wgpu->createSurface( { nextInChain       => WebGPU::Direct->new_window( 1, 1 ) } );
  my $adapter = $wgpu->createAdapter( { compatibleSurface => $surface } );
  my $sc      = $wgpu->SurfaceCapabilities->new;
  $surface->getCapabilities( $adapter, $sc );

  isa_ok( $sc, 'WebGPU::Direct::SurfaceCapabilities', 'SurfaceCapabilities object is still blessed' );

  # PresentMode must include at least 1 item: Fifo
  isnt( $sc->presentModeCount, 0, 'Present Mode Count is at least one' );

  isa_ok( $sc->presentModes, 'WebGPU::Direct::PresentMode::Array', 'Array of Present Modes is blessed' );
  is( $sc->presentModeCount, scalar( $sc->presentModes->@* ), 'Present Mode Count matches the array count' );

  foreach my $pm ( $sc->presentModes->@* )
  {
    is( ref $pm, '', "Enum $pm is not blessed" );
    isnt( 0 + $pm, "$pm", "Enum $pm is dualvar" );
    is( WebGPU::Direct::PresentMode->new($pm), $pm, "Enum $pm is the same PresentMode enum from new" );
  }

  # Test pack, since it's already unpacked it
  my %existing = $sc->%*;      # Do not check the arrays
  my $sc_bytes = $sc->bytes;

  #TODO: my $pm_bytes = $sc->presentModes->bytes;
  $sc->pack;

  # After a pack, the pointers in ->bytes may change, so we do not check them
  #is( $sc->bytes, $sc_bytes, 'SurfaceCapabilities in memory has not changed with pack' );
  #TODO: is( $sc->presentModes->bytes, $pm_bytes, 'PresentModes in memory has not changed with pack');

  foreach my $key (qw/alphaModeCount formatCount presentModeCount/)
  {
    is( $sc->$key, $existing{$key}, "Count of $key did not change" );
  }

  push $sc->presentModes->@*, WebGPU::Direct::PresentMode->new('immediate');
  my $pm_count = scalar( $sc->presentModes->@* );
  is( $sc->presentModeCount, $pm_count - 1, 'Present Mode Count now does not match' );

  $sc->pack;

  #is( $sc->bytes, $sc_bytes, 'SurfaceCapabilities in memory has not changed with pack' );
  #TODO: is( $sc->presentModes->bytes, $pm_bytes, 'PresentModes in memory has not changed with pack');

  is( $sc->presentModeCount, scalar( $sc->presentModes->@* ), 'Present Mode Count has updated' );

  $sc->unpack;
  #TODO: is( $sc->bytes, $sc_bytes, 'SurfaceCapabilities in memory has not changed with pack' );

  #TODO: is( $sc->presentModes->bytes, $pm_bytes, 'PresentModes in memory has not changed with pack');
  is( $sc->presentModeCount, scalar( $sc->presentModes->@* ), 'Present Mode Count is still correct after unpack' );
  is( $sc->presentModeCount, $pm_count, 'Present Mode Count included Immediate' );
  is( $sc->presentModes->[-1], WebGPU::Direct::PresentMode->new('immediate'), 'Immediate is still in the list' );

  foreach my $key (qw/alphaModeCount formatCount/)
  {
    is( $sc->$key, $existing{$key}, "Count of $key did not change" );
  }

  $sc->presentModes->@* = ();
  $sc->pack;

  is( scalar( $sc->presentModes->@* ), 0, 'Present Mode is an empty array' );
  is( $sc->presentModeCount,           0, 'Present Mode Count is now 0' );

  $sc->unpack;
  is( scalar( $sc->presentModes->@* ), 0, 'Present Mode is still an empty array after unpack' );
  is( $sc->presentModeCount,           0, 'Present Mode Count is still 0 after unpack' );
};

# TODO ? Check opaque arrays

done_testing;
