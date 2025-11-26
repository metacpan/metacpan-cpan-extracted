#!/usr/bin/env perl

# Game of Life, adapted from WebGPU sample:
# https://webgpu.github.io/webgpu-samples/?sample=gameOfLife#main.ts

use v5.30;
use Data::Dumper;
use Time::HiRes qw/time/;
use WebGPU::Direct qw/:all/;

my $wgpu = WebGPU::Direct->new;

my $width  = 600;
my $height = 600;

my $wgsl = do { local $/; <DATA> };
my ( $computeWGSL, $vertWGSL, $fragWGSL ) = split /^---\n/xms, $wgsl;

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

my $GameOptions = {
  width         => 128,
  height        => 128,
  timestep      => 1,
  workgroupSize => 8,
};

my $computeShader = $device->createShaderModule( { code => $computeWGSL } );

my $bindGroupLayoutCompute = $device->createBindGroupLayout(
  {
    entries => [
      {
        binding    => 0,
        visibility => ShaderStage->compute,
        buffer     => {
          type => 'readOnlyStorage',
        },
      },
      {
        binding    => 1,
        visibility => ShaderStage->compute,
        buffer     => {
          type => 'readOnlyStorage',
        },
      },
      {
        binding    => 2,
        visibility => ShaderStage->compute,
        buffer     => {
          type => 'storage',
        },
      },
    ],
  }
);

my @squareVertices = ( 0, 0, 0, 1, 1, 0, 1, 1 );
my $squareBuffer   = $device->createBuffer(
  {
    size             => BYTES_PER_u32 * scalar(@squareVertices),
    usage            => BufferUsage->vertex,
    mappedAtCreation => 1,
  }
);

$squareBuffer->getMappedRange->buffer_u32(@squareVertices);
$squareBuffer->unmap();

my $squareStride = {
  arrayStride => 2 * BYTES_PER_u32,
  stepMode    => 'vertex',
  attributes  => [
    {
      shaderLocation => 1,
      offset         => 0,
      format         => 'uint32x2',
    },
  ],
};

my $vertexShader   = $device->createShaderModule( { code => $vertWGSL } );
my $fragmentShader = $device->createShaderModule( { code => $fragWGSL } );
my $commandEncoder;

my $bindGroupLayoutRender = $device->createBindGroupLayout(
  {
    entries => [
      {
        binding    => 0,
        visibility => ShaderStage->vertex,
        buffer     => {
          type => 'uniform',
        },
      },
    ],
  }
);

my $cellsStride = {
  arrayStride => BYTES_PER_u32,
  stepMode    => 'instance',
  attributes  => [
    {
      shaderLocation => 0,
      offset         => 0,
      format         => 'uint32',
    },
  ],
};

my $wholeTime = 0;
my $loopTimes = 0;
my $buffer0;
my $buffer1;
my $render = sub { };

sub resetGameData
{
  # compute pipeline
  my $computePipeline = $device->createComputePipeline(
    {
      layout => $device->createPipelineLayout(
        {
          bindGroupLayouts => [$bindGroupLayoutCompute],
        }
      ),
      compute => {
        module     => $computeShader,
        entryPoint => 'main',
        constants  => {
          blockSize => $GameOptions->{workgroupSize},
        },
      },
    }
  );
  my $sizeBuffer = $device->createBuffer(
    {
      size             => 2 * BYTES_PER_u32,
      usage            => BufferUsage->storage | BufferUsage->uniform | BufferUsage->copyDst | BufferUsage->vertex,
      mappedAtCreation => 1,
    }
  );

  $sizeBuffer->getMappedRange->buffer_i32( $GameOptions->{width}, $GameOptions->{height} );
  $sizeBuffer->unmap();

  my $cell_length = $GameOptions->{width} * $GameOptions->{height};
  my @cells       = ( map { rand() < 0.25 ? 1 : 0 } 1 .. $cell_length );

  $buffer0 = $device->createBuffer(
    {
      size             => scalar(@cells) * BYTES_PER_u32,
      usage            => BufferUsage->storage | BufferUsage->vertex,
      mappedAtCreation => 1,
    }
  );

  $buffer0->getMappedRange->buffer_i32(@cells);
  $buffer0->unmap();

  $buffer1 = $device->createBuffer(
    {
      size  => scalar(@cells) * BYTES_PER_u32,
      usage => BufferUsage->storage | BufferUsage->vertex,
    }
  );

  my $bindGroup0 = $device->createBindGroup(
    {
      layout  => $bindGroupLayoutCompute,
      entries => [
        { binding => 0, buffer => $sizeBuffer },
        { binding => 1, buffer => $buffer0 },
        { binding => 2, buffer => $buffer1 },
      ],
    }
  );

  my $bindGroup1 = $device->createBindGroup(
    {
      layout  => $bindGroupLayoutCompute,
      entries => [
        { binding => 0, buffer => $sizeBuffer },
        { binding => 1, buffer => $buffer1 },
        { binding => 2, buffer => $buffer0 },
      ],
    }
  );

  my $renderPipeline = $device->createRenderPipeline(
    {
      layout => $device->createPipelineLayout(
        {
          bindGroupLayouts => [$bindGroupLayoutRender],
        }
      ),
      primitive => {
        topology => 'triangleStrip',
      },
      vertex => {
        module     => $vertexShader,
        entryPoint => 'main',
        buffers    => [ $cellsStride, $squareStride ],
      },
      fragment => {
        module     => $fragmentShader,
        entryPoint => 'main',
        targets    => [
          {
            format => $presentationFormat,
          },
        ],
      },
    }
  );

  my $uniformBindGroup = $device->createBindGroup(
    {
      layout  => $renderPipeline->getBindGroupLayout(0),
      entries => [
        {
          binding => 0,
          buffer  => $sizeBuffer,
          offset  => 0,
          size    => 2 * BYTES_PER_u32,
        },
      ],
    }
  );

  $loopTimes = 0;
  $render    = sub
  {
    $wgpu->processEvents;

    my $currentTexture = $context->getCurrentTexture;
    my $view           = $currentTexture->texture->createView();
    my $renderPass     = {
      colorAttachments => [
        {
          view       => $view,
          loadOp     => 'clear',
          storeOp    => 'store',
          clearColor => { r => 0.15, g => 0.15, b => 0.5, a => 1 },
        },
      ],
    };
    $commandEncoder = $device->createCommandEncoder();

    # compute
    my $passEncoderCompute = $commandEncoder->beginComputePass();
    $passEncoderCompute->setPipeline($computePipeline);
    $passEncoderCompute->setBindGroup( 0, $loopTimes ? $bindGroup1 : $bindGroup0 );
    $passEncoderCompute->dispatchWorkgroups(
      $GameOptions->{width} / $GameOptions->{workgroupSize},
      $GameOptions->{height} / $GameOptions->{workgroupSize}
    );
    $passEncoderCompute->end();

    # render
    my $passEncoderRender = $commandEncoder->beginRenderPass($renderPass);
    $passEncoderRender->setPipeline($renderPipeline);
    $passEncoderRender->setVertexBuffer( 0, $loopTimes ? $buffer1 : $buffer0 );
    $passEncoderRender->setVertexBuffer( 1, $squareBuffer );
    $passEncoderRender->setBindGroup( 0, $uniformBindGroup, [] );
    $passEncoderRender->draw( 4, $cell_length );
    $passEncoderRender->end();

    $device->getQueue->submit( [ $commandEncoder->finish() ] );
    $context->present;
  };
}

resetGameData();

my $start  = time;
my $frames = 1000;
for ( 1 .. $frames )
{
  if ( $GameOptions->{timestep} )
  {
    $wholeTime++;
    if ( $wholeTime >= $GameOptions->{timestep} )
    {
      $render->();
      $wholeTime -= $GameOptions->{timestep};
      $loopTimes = 1 - $loopTimes;
    }
  }
}

my $total = time - $start;
warn "Took $total Seconds for $frames frames:\n";
warn "  FPS: " . ( $frames / $total ) . "\n";

__DATA__
@binding(0) @group(0) var<storage, read> size: vec2u;
@binding(1) @group(0) var<storage, read> current: array<u32>;
@binding(2) @group(0) var<storage, read_write> next: array<u32>;

const blockSize = 8;

fn getIndex(x: u32, y: u32) -> u32 {
  let h = size.y;
  let w = size.x;

  return (y % h) * w + (x % w);
}

fn getCell(x: u32, y: u32) -> u32 {
  return current[getIndex(x, y)];
}

fn countNeighbors(x: u32, y: u32) -> u32 {
  return getCell(x - 1, y - 1) + getCell(x, y - 1) + getCell(x + 1, y - 1) +
         getCell(x - 1, y) +                         getCell(x + 1, y) +
         getCell(x - 1, y + 1) + getCell(x, y + 1) + getCell(x + 1, y + 1);
}

@compute @workgroup_size(blockSize, blockSize)
fn main(@builtin(global_invocation_id) grid: vec3u) {
  let x = grid.x;
  let y = grid.y;
  let n = countNeighbors(x, y);
  next[getIndex(x, y)] = select(u32(n == 3u), u32(n == 2u || n == 3u), getCell(x, y) == 1u);
}

---

struct Out {
  @builtin(position) pos: vec4f,
  @location(0) cell: f32,
}

@binding(0) @group(0) var<uniform> size: vec2u;

@vertex
fn main(@builtin(instance_index) i: u32, @location(0) cell: u32, @location(1) pos: vec2u) -> Out {
  let w = size.x;
  let h = size.y;
  let x = (f32(i % w + pos.x) / f32(w) - 0.5) * 2. * f32(w) / f32(max(w, h));
  let y = (f32((i - (i % w)) / w + pos.y) / f32(h) - 0.5) * 2. * f32(h) / f32(max(w, h));

  return Out(vec4f(x, y, 0., 1.), f32(cell));
}

---

@fragment
fn main(@location(0) cell: f32) -> @location(0) vec4f {
  return vec4f(cell, cell, cell, 1.);
}

