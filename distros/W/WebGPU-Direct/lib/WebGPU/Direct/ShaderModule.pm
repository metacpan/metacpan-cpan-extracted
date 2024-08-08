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

=item * Arguments

=over

=item * callback (WebGPU::Direct::CompilationInfoCallback (Code reference))

=item * userdata (Scalar (void *))

=back

=back

=head3 setLabel

=over

=item * Arguments

=over

=item * label (String (char *))

=back

=back

=head3 reference

=head3 release

