#!/usr/bin/env perl

# Rotating Cube, adapted from WebGPU sample:
# https://webgpu.github.io/webgpu-samples/?sample=rotatingCube

use v5.30;
use Data::Dumper;
use Time::HiRes qw/time/;
use WebGPU::Direct qw/:all/;

use Math::Trig qw/:pi tan/;
use Math::3Space qw/space vec3 perspective_projection/;

use FindBin qw/$Bin $Script/;
my $cube = require "$Bin/$Script.cube.pl";

my $wgpu = WebGPU::Direct->new;

my $width  = 600;
my $height = 600;

my $wgsl = do { local $/; <DATA> };
my ( $basicVertWGSL, $vertexPositionColorWGSL ) = split /^---\n/xms, $wgsl;

my $context = $wgpu->createSurface(
  {
    nextInChain => WebGPU::Direct->new_window( $width, $height ),
  }
);

my $adapter = $wgpu->createAdapter( { compatibleSurface => $context } );
my $device  = $adapter->createDevice;

my $presentationFormat = $context->getPreferredFormat($adapter);

$context->configure(
  {
    device => $device,
    format => $presentationFormat,
    width  => $width,
    height => $height,
  }
);

# Create a vertex buffer from the cube data.
my $verticesBuffer = $device->createBuffer(
  {
    size             => $cube->{cubeVertexCount} * 10 * BYTES_PER_f32,
    usage            => BufferUsage->vertex,
    mappedAtCreation => 1,
  }
);

$verticesBuffer->getMappedRange->buffer_f32( $cube->{cubeVertexArray}->@* );
$verticesBuffer->unmap;

my $pipeline = $device->createRenderPipeline(
  {
    layout => undef,
    vertex => {
      entryPoint => 'main',
      module     => $device->createShaderModule(
        {
          code => $basicVertWGSL,
        }
      ),
      buffers => [
        {
          arrayStride => $cube->{cubeVertexSize},
          attributes  => [
            {
              # position
              shaderLocation => 0,
              offset         => $cube->{cubePositionOffset},
              format         => 'float32x4',
            },
            {
              # uv
              shaderLocation => 1,
              offset         => $cube->{cubeUVOffset},
              format         => 'float32x2',
            },
          ],
        },
      ],
    },
    fragment => {
      entryPoint => 'main',
      module     => $device->createShaderModule(
        {
          entryPoint => 'main',
          code       => $vertexPositionColorWGSL,
        }
      ),
      targets => [
        {
          format => $presentationFormat,
        },
      ],
    },
    primitive => {
      topology => 'triangleList',

      # Backface culling since the cube is solid piece of geometry.
      # Faces pointing away from the camera will be occluded by faces
      # pointing toward the camera.
      cullMode => 'back',
    },

    # Enable depth testing so that the fragment closest to the camera
    # is rendered in front.
    depthStencil => {
      depthWriteEnabled => 1,
      depthCompare      => 'less',
      format            => 'depth24Plus',
    },
  }
);

my $depthTexture = $device->createTexture(
  {
    size   => [ $width, $height ],
    format => 'depth24Plus',
    usage  => TextureUsage->renderAttachment,
  }
);

my $uniformBufferSize = BYTES_PER_f32 * 16;      # 4x4 matrix
my $uniformBuffer     = $device->createBuffer(
  {
    size  => $uniformBufferSize,
    usage => BufferUsage->uniform | BufferUsage->copyDst,
  }
);

my $uniformBindGroup = $device->createBindGroup(
  {
    layout  => $pipeline->getBindGroupLayout(0),
    entries => [
      {
        binding => 0,
        buffer  => $uniformBuffer,
      },
    ],
  }
);

my $renderPassDescriptor = {
  colorAttachments => [
    {
      view => undef,    # Assigned later

      clearValue => [ 0.5, 0.5, 0.5, 1.0 ],
      loadOp     => 'clear',
      storeOp    => 'store',
    },
  ],
  depthStencilAttachment => {
    view => $depthTexture->createView,

    depthClearValue => 1.0,
    depthLoadOp     => 'clear',
    depthStoreOp    => 'store',
  },
};

my $aspect           = $width / $height;
my $projectionMatrix = perspective_projection( pi2 / 5, $aspect, 1, 100.0 );

sub getTransformationMatrix
{
  my $viewMatrix = space;
  $viewMatrix->translate( 0, 0, -4 );
  my $now = time;
  $viewMatrix->rotate( 1 / pi2, [ sin($now), cos($now), 0 ] );

  return pack( 'f*', $projectionMatrix->get_gl_matrix($viewMatrix) );
}

sub frame
{
  my $transformationMatrix = getTransformationMatrix;
  my $queue                = $device->getQueue;

  $queue->writeBuffer(
    $uniformBuffer,
    0,
    $transformationMatrix
  );

  my $currentView = $context->getCurrentTexture->texture->createView;
  $renderPassDescriptor->{colorAttachments}->[0]->{view} = $currentView;

  my $commandEncoder = $device->createCommandEncoder;
  my $passEncoder    = $commandEncoder->beginRenderPass($renderPassDescriptor);
  $passEncoder->setPipeline($pipeline);
  $passEncoder->setBindGroup( 0, $uniformBindGroup );
  $passEncoder->setVertexBuffer( 0, $verticesBuffer );
  $passEncoder->draw( $cube->{cubeVertexCount} );
  $passEncoder->end;
  $queue->submit( [ $commandEncoder->finish ] );

  $context->present;
}

my $start  = time;
my $frames = 1000;
for ( 1 .. $frames )
{
  $wgpu->processEvents;
  frame();
}

my $total = time - $start;
warn "Took $total Seconds for $frames frames:\n";
warn "  FPS: " . ( $frames / $total ) . "\n";

__DATA__
struct Uniforms {
  modelViewProjectionMatrix : mat4x4f,
}
@binding(0) @group(0) var<uniform> uniforms : Uniforms;

struct VertexOutput {
  @builtin(position) Position : vec4f,
  @location(0) fragUV : vec2f,
  @location(1) fragPosition: vec4f,
}

@vertex
fn main(
  @location(0) position : vec4f,
  @location(1) uv : vec2f,
) -> VertexOutput {
var pos: array<vec2<f32>, 3> = array<vec2<f32>, 3>(
        vec2<f32>( 0.0,  0.5),
        vec2<f32>(-0.5, -0.5),
        vec2<f32>( 0.5, -0.5)
    );

  var output : VertexOutput;
  output.Position = uniforms.modelViewProjectionMatrix * position;
  output.fragUV = uv;
  output.fragPosition = 0.5 * (position + vec4(1.0, 1.0, 1.0, 1.0));
  return output;
}

---

@fragment
fn main(
  @location(0) fragUV: vec2f,
  @location(1) fragPosition: vec4f
) -> @location(0) vec4f {
  return fragPosition;
}
