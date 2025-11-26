package WebGPU::Direct::ShaderModule
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

WebGPU::Direct::ShaderModule

=head2 Methods

=head3 getCompilationInfo

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=item * Arguments

=over

=item * callbackInfo (L<WebGPU::Direct::CompilationInfoCallbackInfo|WebGPU::Direct::Types/WebGPU::Direct::CompilationInfoCallbackInfo>)

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

