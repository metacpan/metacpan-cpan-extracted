package WebGPU::Direct::Queue
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Queue

=head2 Methods

=head3 onSubmittedWorkDone

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=item * Arguments

=over

=item * callbackInfo (L<WebGPU::Direct::QueueWorkDoneCallbackInfo|WebGPU::Direct::Types/WebGPU::Direct::QueueWorkDoneCallbackInfo>)

=back

=back

=head3 setLabel

=over

=item * Arguments

=over

=item * label (L<WebGPU::Direct::StringView|WebGPU::Direct::Types/WebGPU::Direct::StringView>)

=back

=back

=head3 submit

=over

=item * Arguments

=over

=item * commandCount (Integer (size_t))

=item * commands (L<WebGPU::Direct::CommandBuffer>)

=back

=back

=head3 writeBuffer

=over

=item * Arguments

=over

=item * buffer (L<WebGPU::Direct::Buffer>)

=item * bufferOffset (Unsigned 64bit (uint64_t))

=item * data (Scalar (void *))

=item * size (Integer (size_t))

=back

=back

=head3 writeTexture

=over

=item * Arguments

=over

=item * destination (L<WebGPU::Direct::TexelCopyTextureInfo|WebGPU::Direct::Types/WebGPU::Direct::TexelCopyTextureInfo>)

=item * data (Scalar (void *))

=item * dataSize (Integer (size_t))

=item * dataLayout (L<WebGPU::Direct::TexelCopyBufferLayout|WebGPU::Direct::Types/WebGPU::Direct::TexelCopyBufferLayout>)

=item * writeSize (L<WebGPU::Direct::Extent3D|WebGPU::Direct::Types/WebGPU::Direct::Extent3D>)

=back

=back

=head3 addRef

=head3 release

