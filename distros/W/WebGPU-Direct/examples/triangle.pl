#!/usr/bin/env perl

# Triangle Example, adapted from wgpu-native:
# https://github.com/gfx-rs/wgpu-native/blob/trunk/examples/triangle/main.c

use v5.30;
use Data::Dumper;
use Time::HiRes qw/time/;
use WebGPU::Direct qw/:all/;

my $wgpu = WebGPU::Direct->new;

# Create instance
my $instance = $wgpu->createInstance( $wgpu->InstanceDescriptor->new );

# Build X11 Surface
my $window     = WebGPU::Direct->new_window;
my $descriptor = $wgpu->SurfaceDescriptor->new( nextInChain => $window );

# Build surface
my $surface = $instance->createSurface($descriptor);

# Acquire an adapter and device
my $ra_opt = $wgpu->RequestAdapterOptions->new( compatibleSurface => $surface );

my $adapter;
my $device;

sub handle_request_adapter
{
  my $status = shift;
  $adapter = shift;
  my $msg  = shift;
  my $data = shift;

  if ( $status == RequestAdapterStatus->success )
  {
    $data->{adapter} = $adapter;
  }
  else
  {
    warn
        sprintf( "request_adapter status=%#.8x message=%s\n", $status, $msg );
  }
}

sub handle_request_device
{
  my $status = shift;
  $device = shift;
  my $msg  = shift;
  my $data = shift;

  if ( $status == RequestDeviceStatus->success )
  {
    $data->{device} = $device;
  }
  else
  {
    warn sprintf( "request_device status=%#.8x message=%s\n", $status, $msg );
  }
}

$instance->requestAdapter( $ra_opt, \&handle_request_adapter, {} );
my $supported_limits = $wgpu->SupportedLimits->new;

$adapter->getLimits($supported_limits);
my $limits = $supported_limits->limits;

my $req_limits = $wgpu->RequiredLimits->new( { limits => $limits } );
my $devdesc    = $wgpu->DeviceDescriptor->new( requiredLimits => $req_limits );
$adapter->requestDevice( $devdesc, \&handle_request_device, {} );

my $queue = $device->getQueue;

# Build the shader
my $shaderdesc = $wgpu->ShaderModuleDescriptor->new(
  {
    label       => 'shader.wsgl',
    nextInChain => $wgpu->ShaderModuleWGSLDescriptor->new(
      {
        sType => SType->shaderModuleWGSLDescriptor,
        code  => join( '', <DATA> ),
      }
    ),
  }
);

my $shader = $device->createShaderModule($shaderdesc);

# Build the pipeline pieces
my $pl_desc         = $wgpu->PipelineLayoutDescriptor->new( label => 'pipeline_layout' );
my $pipeline_layout = $device->createPipelineLayout($pl_desc);

my $tex_fmt              = $surface->getPreferredFormat($adapter);
my $surface_capabilities = $wgpu->SurfaceCapabilities->new;
$surface->getCapabilities( $adapter, $surface_capabilities );

my $rpd = $wgpu->RenderPipelineDescriptor->new(
  label  => 'render_pipeline',
  layout => $pipeline_layout,
  vertex => $wgpu->VertexState->new(
    module     => $shader,
    entryPoint => 'vs_main',
  ),
  fragment => $wgpu->FragmentState->new(
    module     => $shader,
    entryPoint => 'fs_main',
    targets    => $wgpu->ColorTargetState->new(
      format    => $surface_capabilities->formats->[0],
      writeMask => ColorWriteMask->all,
    ),
  ),
  primitive => $wgpu->PrimitiveState->new(
    topology => PrimitiveTopology->triangleList,
  ),
  multisample => $wgpu->MultisampleState->new(
    count => 1,
    mask  => 0xFFFFFFFF,
  ),
);

my $pipeline = $device->createRenderPipeline($rpd);

my $sc_config = $wgpu->SurfaceConfiguration->new(
  device      => $device,
  usage       => TextureUsage->renderAttachment,
  format      => $surface_capabilities->formats->[0],
  presentMode => PresentMode->fifo,
  alphaMode   => $surface_capabilities->alphaModes->[0],
  width       => 640,
  height      => 360,
);

$surface->configure($sc_config);

# Precreate some objects used in the loop
my $passcolor = $wgpu->RenderPassColorAttachment->new(
  loadOp     => LoadOp->clear,
  storeOp    => StoreOp->store,
  clearValue => $wgpu->Color->new(
    r => 0.0,
    g => 1.0,
    b => 0.0,
    a => 1.0,
  ),
);

my $passdesc = $wgpu->RenderPassDescriptor->new(
  label            => "render_pass_encoder",
  colorAttachments => $passcolor,
);

my $cwdesc          = $wgpu->CommandEncoderDescriptor->new;
my $cbdesc          = $wgpu->CommandBufferDescriptor->new;
my $surface_texture = $wgpu->SurfaceTexture->new;
my $status          = $wgpu->SurfaceGetCurrentTextureStatus;

my $start  = time;
my $frames = 1000;
for ( 1 .. 1000 )
{
  $surface->getCurrentTexture($surface_texture);

  for ( $surface_texture->status )
  {
    if ( $_ == $status->success )
    {
      # All good, could check for `surface_texture.suboptimal` here.
      last;
    }
    if ( $_ == $status->timeout
      || $_ == $status->outdated
      || $_ == $status->lost )
    {
      # Skip this frame, and re-configure surface.
      # This is a bit different from the reference example since we can't get
      # the window size. This could result in an infinte loop
      if ( defined $surface_texture->texture )
      {
        $surface_texture->texture->release;
      }
      $sc_config->width(640);
      $sc_config->height(360);
      $surface->configure($sc_config);
      redo;
    }
    if ( $_ == $status->outOfMemory
      || $_ == $status->deviceLost
      || $_ == $status->force32 )
    {
      # Fatal error
      die "get_current_texture status=$_";
    }
  }

  my $frame = $surface_texture->texture->createView;

  my $cmdenc = $device->createCommandEncoder($cwdesc);

  $passcolor->view($frame);
  my $passenc = $cmdenc->beginRenderPass($passdesc);

  $passenc->setPipeline($pipeline);
  $passenc->draw( 3, 1, 0, 0 );
  $passenc->end;

  my $cmdbuf = $cmdenc->finish($cbdesc);

  $queue->submit( [$cmdbuf] );
  $surface->present;
}

my $total = time - $start;
warn "Took $total Seconds for $frames frames:\n";
warn "  FPS: " . ( $frames / $total ) . "\n";

__DATA__
@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
    let x = f32(i32(in_vertex_index) - 1);
    let y = f32(i32(in_vertex_index & 1u) * 2 - 1);
    return vec4<f32>(x, y, 0.0, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
    return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
