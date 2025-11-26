use v5.30;
use Test::More;

use WebGPU::Direct;

my $wgpu = WebGPU::Direct->new;

my $renderPassDescriptor = {
  colorAttachments => [
    {
      view       => undef,
      clearValue => [ 0.5, 0.5, 0.5, 1.0 ],
      loadOp     => 'clear',
      storeOp    => 'store',
    },
  ],
  depthStencilAttachment => {
    view => undef,
    depthClearValue => 1.0,
    depthLoadOp     => 'clear',
    depthStoreOp    => 'store',
  },
};

my $rpd = $wgpu->newRenderPassDescriptor($renderPassDescriptor);

is(ref $renderPassDescriptor->{colorAttachments}, 'ARRAY', 'Array stayed array, was not blessed');
is(ref $renderPassDescriptor->{colorAttachments}->[0], 'HASH', 'Hash inside array stayed hash, was not blessed');
is(ref $renderPassDescriptor->{depthStencilAttachment}, 'HASH', 'Hash stayed hash, was not blessed');
is($renderPassDescriptor->{colorAttachments}->[0]->{storeOp}, 'store', 'Hash inside array preserved value');

#$renderPassDescriptor->{colorAttachments}->[0]->{storeOp} = 'undefined';
$rpd->colorAttachments->[0]->storeOp('undefined');
$rpd->depthStencilAttachment->depthStoreOp('undefined');
is( $renderPassDescriptor->{colorAttachments}->[0]->{storeOp}, 'store', 'Pack on object does not effect hash in array');
is( $renderPassDescriptor->{depthStencilAttachment}->{depthStoreOp}, 'store', 'Pack on object does not effect hash');

$renderPassDescriptor->{colorAttachments}->[0]->{storeOp} = 'discard';
$renderPassDescriptor->{depthStencilAttachment}->{depthStoreOp} = 'discard';
$rpd->unpack;
is( $rpd->colorAttachments->[0]->storeOp, 'WGPUStoreOp_Undefined', 'Setting Hash of array value does not effect object');
is( $rpd->depthStencilAttachment->depthStoreOp, 'WGPUStoreOp_Undefined', 'Setting Hash value does not effect object');
is( $renderPassDescriptor->{colorAttachments}->[0]->{storeOp}, 'discard', 'Unpack on object does not effect hash in array');
is( $renderPassDescriptor->{depthStencilAttachment}->{depthStoreOp}, 'discard', 'Unpack on object does not effect hash');

done_testing;
