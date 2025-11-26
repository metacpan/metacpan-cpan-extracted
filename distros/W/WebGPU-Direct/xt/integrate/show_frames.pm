use v5.30;
no warnings qw(experimental::signatures);
use feature 'signatures';

require Test::More;
use WebGPU::Direct qw/BufferUsage TextureFormat PrimitiveTopology LoadOp StoreOp/;

my $wgslSource              = join( '', <DATA> );

sub test_frames ( $window, $xw = 10, $yh = 10 )
{
  my $wgpu    = WebGPU::Direct->new;
  my $surface = $wgpu->createSurface( $window );
  my $adapter = $wgpu->createAdapter( { compatibleSurface => $surface } );
  my $device  = $adapter->createDevice;

  my $vertexStride   = 8 * 4;
  my $vertexDataSize = $vertexStride * 3;

  my $vertexDataBufferDescriptor = {
    size  => $vertexDataSize,
    usage => BufferUsage->vertex,
  };
  my $vertexBuffer = $device->createBuffer($vertexDataBufferDescriptor);

  my $shaderModule            = $device->createShaderModule( { code => $wgslSource } );
  my $vertexStageDescriptor   = { module => $shaderModule, entryPoint => 'vsmain' };
  my $fragmentStageDescriptor = {
    module     => $shaderModule,
    entryPoint => "fsmain",
    targets    => { format => TextureFormat->BGRA8Unorm, },
  };

  my $renderPipelineDescriptor = {
    layout    => $device->createPipelineLayout( {} ),
    vertex    => $vertexStageDescriptor,
    fragment  => $fragmentStageDescriptor,
    primitive => { topology => PrimitiveTopology->triangleList },
  };
  my $renderPipeline = $device->createRenderPipeline($renderPipelineDescriptor);

  $surface->configure(
    {
      width  => $xw,
      height => $yh,
      device => $device,
      format => TextureFormat->BGRA8Unorm,
    }
  );

  my $currentTexture;
  my $renderAttachment;
  my $darkBlue                  = { r => 0.15, g => 0.15, b => 0.5, a => 1 };
  my $colorAttachmentDescriptor = {
    view       => $renderAttachment,
    loadOp     => LoadOp->clear,
    storeOp    => StoreOp->store,
    clearColor => $darkBlue,
  };

  for ( 0 .. 1 )
  {
    $wgpu->processEvents;

    # GPURenderPassDescriptor
    my $renderPassDescriptor = { colorAttachments => [$colorAttachmentDescriptor] };

    # GPUCommandEncoder
    my $commandEncoder = $device->createCommandEncoder;

    # GPURenderPassEncoder
    $currentTexture = $surface->getCurrentTexture;
    use Data::Dumper;
    warn Data::Dumper::Dumper($currentTexture, $wgpu);
    $colorAttachmentDescriptor->{view} = $currentTexture->texture->createView;
    my $renderPassEncoder = $commandEncoder->beginRenderPass($renderPassDescriptor);

    $renderPassEncoder->setPipeline($renderPipeline);
    my $vertexBufferSlot = 0;
    $renderPassEncoder->setVertexBuffer( $vertexBufferSlot, $vertexBuffer );
    $renderPassEncoder->draw( 3, 1, 0, 0 );    # 3 vertices, 1 instance, 0th vertex, 0th instance.
    $renderPassEncoder->end;

    # GPUComamndBuffer
    my $commandBuffer = $commandEncoder->finish;

    # GPUQueue
    my $queue = $device->getQueue;
    $queue->submit( [$commandBuffer] );
    is( $surface->present, 1, "Able to present a frame ($_)" );
  }
}

__DATA__
struct Vertex {
    @builtin(position) Position: vec4<f32>,
    @location(0) color: vec4<f32>,
}

@vertex fn vsmain(@builtin(vertex_index) VertexIndex: u32) -> Vertex
{
    var pos: array<vec2<f32>, 3> = array<vec2<f32>, 3>(
        vec2<f32>( 0.0,  0.5),
        vec2<f32>(-0.5, -0.5),
        vec2<f32>( 0.5, -0.5)
    );
    var vertex_out : Vertex;
    vertex_out.Position = vec4<f32>(pos[VertexIndex], 0.0, 1.0);
    vertex_out.color = vec4<f32>(pos[VertexIndex] + vec2<f32>(0.5, 0.5), 0.0, 1.0);
    return vertex_out;
}

@fragment fn fsmain(in: Vertex) -> @location(0) vec4<f32>
{
    return in.color;
}
