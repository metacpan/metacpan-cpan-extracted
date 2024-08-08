package WebGPU::Direct::ComputePassEncoder
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  sub setBindGroup (
    $self,
    $index,
    $bindGroup,
    $dynamicOffsets = [],
      )
  {
    return $self->_setBindGroup( $index, $bindGroup, $dynamicOffsets );
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::ComputePassEncoder

=head2 Methods

=head3 dispatchWorkgroups

=over

=item * Arguments

=over

=item * workgroupCountX (Unsigned 32bit (uint32_t))

=item * workgroupCountY (Unsigned 32bit (uint32_t)) Default: 1

=item * workgroupCountZ (Unsigned 32bit (uint32_t)) Default: 1

=back

=back

=head3 dispatchWorkgroupsIndirect

=over

=item * Arguments

=over

=item * indirectBuffer (L<WebGPU::Direct::Buffer>)

=item * indirectOffset (Unsigned 64bit (uint64_t))

=back

=back

=head3 end

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

=item * pipeline (L<WebGPU::Direct::ComputePipeline>)

=back

=back

=head3 reference

=head3 release

