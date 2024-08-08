package WebGPU::Direct::CommandEncoder
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Scalar::Util qw/blessed/;
  use Carp qw/croak/;

  sub beginComputePass (
    $self,
    $descriptor = {}
      )
  {
    return $self->_beginComputePass($descriptor);
  }

  sub clearBuffer (
    $self,
    $buffer,
    $offset = 0,
    $size   = $buffer->getSize() - $offset,
      )
  {
    return $self->_clearBuffer( $buffer, $offset, $size );
  }

  sub finish (
    $self,
    $descriptor = {}
      )
  {
    return $self->_finish($descriptor);
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::CommandEncoder

=head2 Methods

=head3 beginComputePass

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::ComputePassEncoder>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::ComputePassDescriptor|WebGPU::Direct::Types/WebGPU::Direct::ComputePassDescriptor>) Default: {}

=back

=back

=head3 beginRenderPass

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::RenderPassEncoder>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::RenderPassDescriptor|WebGPU::Direct::Types/WebGPU::Direct::RenderPassDescriptor>)

=back

=back

=head3 clearBuffer

=over

=item * Arguments

=over

=item * buffer (L<WebGPU::Direct::Buffer>)

=item * offset (Unsigned 64bit (uint64_t)) Default: 0

=item * size (Unsigned 64bit (uint64_t)) Default: buffer->getSize() - offset

=back

=back

=head3 copyBufferToBuffer

=over

=item * Arguments

=over

=item * source (L<WebGPU::Direct::Buffer>)

=item * sourceOffset (Unsigned 64bit (uint64_t))

=item * destination (L<WebGPU::Direct::Buffer>)

=item * destinationOffset (Unsigned 64bit (uint64_t))

=item * size (Unsigned 64bit (uint64_t))

=back

=back

=head3 copyBufferToTexture

=over

=item * Arguments

=over

=item * source (L<WebGPU::Direct::ImageCopyBuffer|WebGPU::Direct::Types/WebGPU::Direct::ImageCopyBuffer>)

=item * destination (L<WebGPU::Direct::ImageCopyTexture|WebGPU::Direct::Types/WebGPU::Direct::ImageCopyTexture>)

=item * copySize (L<WebGPU::Direct::Extent3D|WebGPU::Direct::Types/WebGPU::Direct::Extent3D>)

=back

=back

=head3 copyTextureToBuffer

=over

=item * Arguments

=over

=item * source (L<WebGPU::Direct::ImageCopyTexture|WebGPU::Direct::Types/WebGPU::Direct::ImageCopyTexture>)

=item * destination (L<WebGPU::Direct::ImageCopyBuffer|WebGPU::Direct::Types/WebGPU::Direct::ImageCopyBuffer>)

=item * copySize (L<WebGPU::Direct::Extent3D|WebGPU::Direct::Types/WebGPU::Direct::Extent3D>)

=back

=back

=head3 copyTextureToTexture

=over

=item * Arguments

=over

=item * source (L<WebGPU::Direct::ImageCopyTexture|WebGPU::Direct::Types/WebGPU::Direct::ImageCopyTexture>)

=item * destination (L<WebGPU::Direct::ImageCopyTexture|WebGPU::Direct::Types/WebGPU::Direct::ImageCopyTexture>)

=item * copySize (L<WebGPU::Direct::Extent3D|WebGPU::Direct::Types/WebGPU::Direct::Extent3D>)

=back

=back

=head3 finish

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::CommandBuffer>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::CommandBufferDescriptor|WebGPU::Direct::Types/WebGPU::Direct::CommandBufferDescriptor>) Default: {}

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

=head3 resolveQuerySet

=over

=item * Arguments

=over

=item * querySet (L<WebGPU::Direct::QuerySet>)

=item * firstQuery (Unsigned 32bit (uint32_t))

=item * queryCount (Unsigned 32bit (uint32_t))

=item * destination (L<WebGPU::Direct::Buffer>)

=item * destinationOffset (Unsigned 64bit (uint64_t))

=back

=back

=head3 setLabel

=over

=item * Arguments

=over

=item * label (String (char *))

=back

=back

=head3 writeTimestamp

=over

=item * Arguments

=over

=item * querySet (L<WebGPU::Direct::QuerySet>)

=item * queryIndex (Unsigned 32bit (uint32_t))

=back

=back

=head3 reference

=head3 release

