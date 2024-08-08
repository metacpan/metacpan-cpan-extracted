package WebGPU::Direct::RenderPassEncoder
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Scalar::Util qw/blessed/;
  use Carp qw/croak/;

  sub setBindGroup (
    $self,
    $groupIndex,
    $group,
    $dynamicOffsets = [],
      )
  {
    return $self->_setBindGroup( $groupIndex, $group, $dynamicOffsets );
  }

  sub setIndexBuffer (
    $self,
    $buffer,
    $format,
    $offset = 0,
    $size   = $buffer->getSize() - $offset,
      )
  {
    return $self->_setIndexBuffer( $buffer, $format, $offset, $size );
  }

  sub setVertexBuffer (
    $self,
    $slot,
    $buffer,
    $offset = 0,
    $size   = $buffer->getSize - $offset,
      )
  {
    return $self->_setVertexBuffer( $slot, $buffer, $offset, $size );
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::RenderPassEncoder

=head2 Methods

=head3 beginOcclusionQuery

=over

=item * Arguments

=over

=item * queryIndex (Unsigned 32bit (uint32_t))

=back

=back

=head3 draw

=over

=item * Arguments

=over

=item * vertexCount (Unsigned 32bit (uint32_t))

=item * instanceCount (Unsigned 32bit (uint32_t)) Default: 1

=item * firstVertex (Unsigned 32bit (uint32_t)) Default: 0

=item * firstInstance (Unsigned 32bit (uint32_t)) Default: 0

=back

=back

=head3 drawIndexed

=over

=item * Arguments

=over

=item * indexCount (Unsigned 32bit (uint32_t))

=item * instanceCount (Unsigned 32bit (uint32_t)) Default: 1

=item * firstIndex (Unsigned 32bit (uint32_t)) Default: 0

=item * baseVertex (Signed 32bit (int32_t)) Default: 0

=item * firstInstance (Unsigned 32bit (uint32_t)) Default: 0

=back

=back

=head3 drawIndexedIndirect

=over

=item * Arguments

=over

=item * indirectBuffer (L<WebGPU::Direct::Buffer>)

=item * indirectOffset (Unsigned 64bit (uint64_t))

=back

=back

=head3 drawIndirect

=over

=item * Arguments

=over

=item * indirectBuffer (L<WebGPU::Direct::Buffer>)

=item * indirectOffset (Unsigned 64bit (uint64_t))

=back

=back

=head3 end

=head3 endOcclusionQuery

=head3 executeBundles

=over

=item * Arguments

=over

=item * bundleCount (Integer (size_t))

=item * bundles (L<WebGPU::Direct::RenderBundle>)

=back

=back

=head3 insertDebugMarker

=over

=item * Arguments

=over

=item * markerLabel (String (char *))

=back

=back

=head3 popDebugGroup

=head3 pushDebugGroup

=over

=item * Arguments

=over

=item * groupLabel (String (char *))

=back

=back

=head3 setBindGroup

=over

=item * Arguments

=over

=item * groupIndex (Unsigned 32bit (uint32_t))

=item * group (L<WebGPU::Direct::BindGroup>)

=item * dynamicOffsetCount (Integer (size_t))

=item * dynamicOffsets (Unsigned 32bit (uint32_t)) Default: []

=back

=back

=head3 setBlendConstant

=over

=item * Arguments

=over

=item * color (L<WebGPU::Direct::Color|WebGPU::Direct::Types/WebGPU::Direct::Color>)

=back

=back

=head3 setIndexBuffer

=over

=item * Arguments

=over

=item * buffer (L<WebGPU::Direct::Buffer>)

=item * format (L<WebGPU::Direct::IndexFormat|WebGPU::Direct::Constants/WebGPU::Direct::IndexFormat>)

=item * offset (Unsigned 64bit (uint64_t)) Default: 0

=item * size (Unsigned 64bit (uint64_t)) Default: buffer->getSize() - offset

=back

=back

=head3 setLabel

=over

=item * Arguments

=over

=item * label (String (char *))

=back

=back

=head3 setPipeline

=over

=item * Arguments

=over

=item * pipeline (L<WebGPU::Direct::RenderPipeline>)

=back

=back

=head3 setScissorRect

=over

=item * Arguments

=over

=item * x (Unsigned 32bit (uint32_t))

=item * y (Unsigned 32bit (uint32_t))

=item * width (Unsigned 32bit (uint32_t))

=item * height (Unsigned 32bit (uint32_t))

=back

=back

=head3 setStencilReference

=over

=item * Arguments

=over

=item * reference (Unsigned 32bit (uint32_t))

=back

=back

=head3 setVertexBuffer

=over

=item * Arguments

=over

=item * slot (Unsigned 32bit (uint32_t))

=item * buffer (L<WebGPU::Direct::Buffer>)

=item * offset (Unsigned 64bit (uint64_t)) Default: 0

=item * size (Unsigned 64bit (uint64_t)) Default: buffer->getSize() - offset

=back

=back

=head3 setViewport

=over

=item * Arguments

=over

=item * x (Float (float))

=item * y (Float (float))

=item * width (Float (float))

=item * height (Float (float))

=item * minDepth (Float (float))

=item * maxDepth (Float (float))

=back

=back

=head3 reference

=head3 release

