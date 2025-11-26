package WebGPU::Direct::Surface
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  sub getCurrentTexture (
    $self,
    $surfaceTexture = undef,
      )
  {
    if ( !defined $surfaceTexture )
    {
      $surfaceTexture = WebGPU::Direct->SurfaceTexture->new;
    }

    $self->_getCurrentTexture($surfaceTexture);

    return $surfaceTexture;
  }

  sub getCapabilities (
    $self,
    $adapter,
    $capabilities = undef,
      )
  {
    if ( !defined $capabilities )
    {
      $capabilities = WebGPU::Direct::SurfaceCapabilities->new;
    }

    $self->_getCapabilities( $adapter, $capabilities );

    return $capabilities;
  }

  sub getPreferredFormat (
    $self,
    $adapter,
      )
  {
    my $capabilities = $self->getCapabilities($adapter);

    return $capabilities->formats->[0];
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Surface

=head2 Methods

=head3 configure

=over

=item * Arguments

=over

=item * config (L<WebGPU::Direct::SurfaceConfiguration|WebGPU::Direct::Types/WebGPU::Direct::SurfaceConfiguration>)

=back

=back

=head3 getCapabilities

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Status|WebGPU::Direct::Constants/WebGPU::Direct::Status>

=back

=item * Arguments

=over

=item * adapter (L<WebGPU::Direct::Adapter>)

=item * capabilities (L<WebGPU::Direct::SurfaceCapabilities|WebGPU::Direct::Types/WebGPU::Direct::SurfaceCapabilities>)

=back

=back

=head3 getCurrentTexture

=over

=item * Arguments

=over

=item * surfaceTexture (L<WebGPU::Direct::SurfaceTexture|WebGPU::Direct::Types/WebGPU::Direct::SurfaceTexture>) Default: undef

=back

=back

=head3 present

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Status|WebGPU::Direct::Constants/WebGPU::Direct::Status>

=back

=back

=head3 setLabel

=over

=item * Arguments

=over

=item * label (L<WebGPU::Direct::StringView|WebGPU::Direct::Types/WebGPU::Direct::StringView>)

=back

=back

=head3 unconfigure

=head3 addRef

=head3 release

