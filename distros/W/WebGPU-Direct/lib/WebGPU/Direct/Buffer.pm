package WebGPU::Direct::Buffer
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';
  use Carp;

  sub getConstMappedRange (
    $self,
    $offset = 0,
    $size   = $self->getSize - $offset,
      )
  {
    return $self->_getConstMappedRange( $offset, $size );
  }

  sub getMappedRange (
    $self,
    $offset = 0,
    $size   = $self->getSize - $offset,
      )
  {
    return $self->_getMappedRange( $offset, $size );
  }

  sub mapAsync (
    $self,
    $mode,
    $offset   = 0,
    $size     = $self->getSize - $offset,
    $callback = '',
    $userdata = {},
      )
  {
    croak "callback must be provided"
        if !$callback;

    return $self->_mapAsync( $mode, $offset, $size, $callback, $userdata );
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Buffer

=head2 Methods

=head3 destroy

=head3 getConstMappedRange

=over

=item * Return Type

=over

=item * Scalar (void *)

=back

=item * Arguments

=over

=item * offset (Integer (size_t)) Default: 0

=item * size (Integer (size_t)) Default: GetSize() - offset

=back

=back

=head3 getMapState

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::BufferMapState|WebGPU::Direct::Constants/WebGPU::Direct::BufferMapState>

=back

=back

=head3 getMappedRange

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::MappedBuffer>

=back

=item * Arguments

=over

=item * offset (Integer (size_t)) Default: 0

=item * size (Integer (size_t)) Default: GetSize() - offset

=back

=back

=head3 getSize

=over

=item * Return Type

=over

=item * Unsigned 64bit (uint64_t)

=back

=back

=head3 getUsage

=over

=item * Return Type

=over

=item * L<WGPUBufferUsageFlags|WebGPU::Direct::Constants/WebGPU::Direct::BufferUsage>

=back

=back

=head3 mapAsync

=over

=item * Arguments

=over

=item * mode (L<WGPUMapModeFlags|WebGPU::Direct::Constants/WebGPU::Direct::MapMode>)

=item * offset (Integer (size_t)) Default: 0

=item * size (Integer (size_t)) Default: GetSize() - offset

=item * callback (WebGPU::Direct::BufferMapCallback (Code reference))

=item * userdata (Scalar (void *)) Default: {}

=back

=back

=head3 setLabel

=over

=item * Arguments

=over

=item * label (String (char *))

=back

=back

=head3 unmap

=head3 reference

=head3 release

