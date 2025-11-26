package WebGPU::Direct::Texture
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Scalar::Util qw/blessed/;
  use Carp qw/croak/;

  sub createView (
    $self,
    $descriptor = {}
      )
  {
    if ( !blessed $descriptor )
    {
      my $new_descriptor = WebGPU::Direct->TextureViewDescriptor->new($descriptor);
      my $tvd            = WebGPU::Direct->TextureViewDimension;
      my $td             = WebGPU::Direct->TextureDimension;

      if ( !exists $descriptor->{Dimension} )
      {
        my $dim  = $self->getDimension;
        my $doal = $self->getDepthOrArrayLayers;
        if ( $dim == $td->_1D )
        {
          $new_descriptor->dimension( $tvd->_1D );
        }
        elsif ( $dim == $td->_2D && $doal == 1 )
        {
          $new_descriptor->dimension( $tvd->_2D );
        }
        elsif ( $dim == $td->_2D && $doal > 1 )
        {
          $new_descriptor->dimension( $tvd->_2DArray );
        }
        elsif ( $dim == $td->_3D )
        {
          $new_descriptor->dimension( $tvd->_3D );
        }
      }

      if ( !exists $descriptor->{ArrayLayerCount} )
      {
        my $doal        = $self->getDepthOrArrayLayers;
        my $bal         = $new_descriptor->baseArrayLayer;
        my %ALC_default = (
          0 + $tvd->_1D       => 1,
          0 + $tvd->_2D       => 1,
          0 + $tvd->_3D       => 1,
          0 + $tvd->cube      => 6,
          0 + $tvd->_2DArray  => $doal - $bal,
          0 + $tvd->cubeArray => $doal - $bal,
        );

        my $dim = 0 + $new_descriptor->dimension;
        $new_descriptor->arrayLayerCount( $ALC_default{$dim} );
      }

      if ( !exists $descriptor->{format} )
      {
        my $aspect = $new_descriptor->aspect;
        my $format = $self->getFormat;

        state %depth_or_stencil = map { 0 + WebGPU::Direct->TextureFormat->$_ => 1 } qw/
            stencil8        depth16Unorm
            depth24Plus     depth24PlusStencil8
            depth32Float    depth32FloatStencil8
            /;

        if (
          (
               $aspect == WebGPU::Direct->TextureAspect->stencilOnly
            || $aspect == WebGPU::Direct->TextureAspect->depthOnly
          )
          && $depth_or_stencil{ 0 + $format }
            )
        {
          croak "Do not yet have a mapping for Depth or Stencil formats";
        }
        else
        {
          $new_descriptor->format($format);
        }
      }

      if ( !exists $descriptor->{mipLevelCount} )
      {
        $new_descriptor->mipLevelCount( $self->getMipLevelCount - $new_descriptor->baseMipLevel );
      }
      $descriptor = $new_descriptor;
    }
    return $self->_createView($descriptor);
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Texture

=head2 Methods

=head3 createView

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::TextureView>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::TextureViewDescriptor|WebGPU::Direct::Types/WebGPU::Direct::TextureViewDescriptor>) Default: {}

=back

=back

=head3 destroy

=head3 getDepthOrArrayLayers

=over

=item * Return Type

=over

=item * Unsigned 32bit (uint32_t)

=back

=back

=head3 getDimension

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::TextureDimension|WebGPU::Direct::Constants/WebGPU::Direct::TextureDimension>

=back

=back

=head3 getFormat

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::TextureFormat|WebGPU::Direct::Constants/WebGPU::Direct::TextureFormat>

=back

=back

=head3 getHeight

=over

=item * Return Type

=over

=item * Unsigned 32bit (uint32_t)

=back

=back

=head3 getMipLevelCount

=over

=item * Return Type

=over

=item * Unsigned 32bit (uint32_t)

=back

=back

=head3 getSampleCount

=over

=item * Return Type

=over

=item * Unsigned 32bit (uint32_t)

=back

=back

=head3 getUsage

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::TextureUsage|WebGPU::Direct::Constants/WebGPU::Direct::TextureUsage>

=back

=back

=head3 getWidth

=over

=item * Return Type

=over

=item * Unsigned 32bit (uint32_t)

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

