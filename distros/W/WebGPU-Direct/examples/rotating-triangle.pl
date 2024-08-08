#!/usr/bin/env perl

# Hello Triangle, rotating, adapted from webkit:
# https://webkit.org/demos/webgpu/scripts/hello-triangle.js

use v5.30;
use Data::Dumper;
use Time::HiRes qw/time/;
use WebGPU::Direct qw/:all/;

use Math::3Space qw/space/;

my $wgpu = WebGPU::Direct->new;

my $width  = 600;
my $height = 600;

my $gpuContext = $wgpu->createSurface(
  {
    nextInChain => WebGPU::Direct->new_window( $width, $height ),
  }
);

my $adapter = $wgpu->requestAdapter({ compatibleSurface => $gpuContext });
my $device  = $adapter->requestDevice;

#*** Vertex Buffer Setup ***

my @vertex = (
  ( 0.0, 0.5, 0.0, 1.0 ),
  ( -0.5, -0.5, 0.0, 1.0 ),
  ( 0.5,  -0.5, 0.0, 1.0 )
);
my $vertex_data = pack( 'f*', @vertex );

my $vertexBuffer = $device->createBuffer(
  {
    size             => length($vertex_data),
    usage            => BufferUsage->vertex,
    mappedAtCreation => 1,
  }
);

$vertexBuffer->getMappedRange->buffer($vertex_data);
$vertexBuffer->unmap;

#*** Shader Setup ***
my $wgslSource   = join( '', <DATA> );
my $shaderModule = $device->createShaderModule( { code => $wgslSource } );

# GPUPipelineStageDescriptors
my $vertexStageDescriptor = {
  module     => $shaderModule,
  entryPoint => 'vsmain',
  buffers    => [
    {
      arrayStride => ( length($vertex_data) / ( @vertex / 4 ) ),
      stepMode    => $wgpu->VertexStepMode->vertex,
      attributes  => [
        {
          # position
          shaderLocation => 0,
          offset         => 0,
          format         => $wgpu->VertexFormat->float32x4,
        },
      ],
    },
  ],

};

my $fragmentStageDescriptor = {
  module     => $shaderModule,
  entryPoint => "fsmain",
  targets    => { format => TextureFormat->BGRA8Unorm, },
};

# GPURenderPipelineDescriptor

my $renderPipelineDescriptor = {

  #layout    => $device->createPipelineLayout( {} ),
  vertex    => $vertexStageDescriptor,
  fragment  => $fragmentStageDescriptor,
  primitive => { topology => PrimitiveTopology->triangleList },
};

# GPURenderPipeline
my $renderPipeline = $device->createRenderPipeline($renderPipelineDescriptor);

my $uniformBufferSize = 4 * 16;                  # 4x4 matrix
my $uniformBuffer     = $device->createBuffer(
  {
    size  => $uniformBufferSize,
    usage => $wgpu->BufferUsage->uniform | $wgpu->BufferUsage->copyDst,
  }
);

$renderPipeline->getBindGroupLayout(0);
my $uniformBindGroup = $device->createBindGroup(
  {
    layout  => $renderPipeline->getBindGroupLayout(0),
    entries => [
      {
        binding => 0,
        buffer  => $uniformBuffer,
      },
    ],
  }
);

#*** Swap Chain Setup ***

# GPUCanvasConfiguration
my $canvasConfiguration = {
  width  => $width,
  height => $height,
  device => $device,
  format => TextureFormat->BGRA8Unorm,
};
$gpuContext->configure($canvasConfiguration);

# GPUTexture
# This is done in the render loop
my $currentTexture;    # = $gpuContext->getCurrentTexture;

#*** Render Pass Setup ***

# Acquire Texture To Render To

# GPUTextureView
# This is done in the render loop
my $renderAttachment;    # = $currentTexture->texture->createView;

# GPUColor
my $darkBlue = { r => 0.15, g => 0.15, b => 0.5, a => 1 };

# GPURenderPassColorATtachmentDescriptor
my $colorAttachmentDescriptor = {
  view       => $renderAttachment,
  loadOp     => LoadOp->clear,
  storeOp    => StoreOp->store,
  clearColor => $darkBlue,
};

#*** Rendering ***

my $start  = time;
my $frames = 1000;
for ( 1 .. 1000 )
{
  # GPURenderPassDescriptor
  my $renderPassDescriptor = { colorAttachments => [$colorAttachmentDescriptor] };

  # GPUCommandEncoder
  my $commandEncoder = $device->createCommandEncoder;

  my $uniform = space;
  $uniform->rot_z( ( time - $start ) / 2 );
  $device->getQueue->writeBuffer(
    $uniformBuffer,
    0,
    pack( "f*", $uniform->get_gl_matrix ),
  );

  # GPURenderPassEncoder
  $currentTexture = $gpuContext->getCurrentTexture;
  $colorAttachmentDescriptor->{view} = $currentTexture->texture->createView;
  my $renderPassEncoder = $commandEncoder->beginRenderPass($renderPassDescriptor);

  $renderPassEncoder->setPipeline($renderPipeline);
  my $vertexBufferSlot = 0;
  $renderPassEncoder->setBindGroup( 0, $uniformBindGroup, [] );
  $renderPassEncoder->setVertexBuffer( $vertexBufferSlot, $vertexBuffer );
  $renderPassEncoder->draw( 3, 1, 0, 0 );    # 3 vertices, 1 instance, 0th vertex, 0th instance.
  $renderPassEncoder->end;

  # GPUComamndBuffer
  my $commandBuffer = $commandEncoder->finish;

  # GPUQueue
  my $queue = $device->getQueue;
  $queue->submit( [$commandBuffer] );
  $gpuContext->present;
}

my $total = time - $start;
warn "Took $total Seconds for $frames frames:\n";
warn "  FPS: " . ( $frames / $total ) . "\n";

__DATA__
struct Uniforms {
  rotate : mat4x4<f32>,
}
@binding(0) @group(0) var<uniform> uniforms : Uniforms;

struct Vertex {
    @builtin(position) Position: vec4<f32>,
    @location(0) color: vec4<f32>,
}

@vertex fn vsmain(
  @builtin(vertex_index) VertexIndex: u32,
  @location(0) position : vec4<f32>
) -> Vertex
{
    var pos: array<vec2<f32>, 3> = array<vec2<f32>, 3>(
        vec2<f32>( 0.0,  0.5),
        vec2<f32>(-0.5, -0.5),
        vec2<f32>( 0.5, -0.5)
    );
    var vertex_out : Vertex;
    //vertex_out.Position = vec4<f32>(pos[VertexIndex], 0.0, 1.0);
    vertex_out.Position = position * uniforms.rotate;
    vertex_out.color = vec4<f32>(pos[VertexIndex] + vec2<f32>(0.5, 0.5), 0.0, 1.0);
    return vertex_out;
}

@fragment fn fsmain(in: Vertex) -> @location(0) vec4<f32>
{
    return in.color;
}
