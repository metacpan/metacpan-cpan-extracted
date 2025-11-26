package WebGPU::Direct::RenderPipeline
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

WebGPU::Direct::RenderPipeline

=head2 Methods

=head3 getBindGroupLayout

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::BindGroupLayout>

=back

=item * Arguments

=over

=item * groupIndex (Unsigned 32bit (uint32_t))

=back

=back

=head3 setLabel

=over

=item * Arguments

=over

=item * label (L<WebGPU::Direct::StringView|WebGPU::Direct::Types/WebGPU::Direct::StringView>)

=back

=back

=head3 addRef

=head3 release

