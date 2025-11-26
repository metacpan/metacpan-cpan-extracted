package WebGPU::Direct::Device
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Scalar::Util qw/blessed/;
  use Carp qw/croak/;

  sub createShaderModule (
    $self,
    $descriptor,
      )
  {
    if ( !blessed $descriptor )
    {
      if ( exists $descriptor->{code} )
      {
        croak "Cannot load code when `nextInChain` also exists"
            if exists $descriptor->{nextInChain};

        my $stype = WebGPU::Direct->SType;
        my $label = delete $descriptor->{label} // '(anon).wsgl';
        my $code  = delete $descriptor->{code};

        $descriptor = WebGPU::Direct->ShaderModuleDescriptor->new(
          {
            label       => $label,
            nextInChain => WebGPU::Direct->ShaderSourceWGSL->new(
              {
                sType => $stype->shaderSourceWGSL,
                code  => $code,
              }
            ),
            %$descriptor,
          }
        );

      }
    }

    return $self->_createShaderModule($descriptor);
  }

  sub createCommandEncoder (
    $self,
    $descriptor = {},
  )
  {
    return $self->_createCommandEncoder($descriptor);
  }

  sub createSampler (
    $self,
    $descriptor = {},
  )
  {
    return $self->_createSampler($descriptor);
  }

};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Device

=head2 Methods

=head3 createBindGroup

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::BindGroup>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::BindGroupDescriptor|WebGPU::Direct::Types/WebGPU::Direct::BindGroupDescriptor>)

=back

=back

=head3 createBindGroupLayout

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::BindGroupLayout>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::BindGroupLayoutDescriptor|WebGPU::Direct::Types/WebGPU::Direct::BindGroupLayoutDescriptor>)

=back

=back

=head3 createBuffer

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Buffer>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::BufferDescriptor|WebGPU::Direct::Types/WebGPU::Direct::BufferDescriptor>)

=back

=back

=head3 createCommandEncoder

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::CommandEncoder>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::CommandEncoderDescriptor|WebGPU::Direct::Types/WebGPU::Direct::CommandEncoderDescriptor>) Default: {}

=back

=back

=head3 createComputePipeline

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::ComputePipeline>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::ComputePipelineDescriptor|WebGPU::Direct::Types/WebGPU::Direct::ComputePipelineDescriptor>)

=back

=back

=head3 createComputePipelineAsync

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::ComputePipelineDescriptor|WebGPU::Direct::Types/WebGPU::Direct::ComputePipelineDescriptor>)

=item * callbackInfo (L<WebGPU::Direct::CreateComputePipelineAsyncCallbackInfo|WebGPU::Direct::Types/WebGPU::Direct::CreateComputePipelineAsyncCallbackInfo>)

=back

=back

=head3 createPipelineLayout

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::PipelineLayout>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::PipelineLayoutDescriptor|WebGPU::Direct::Types/WebGPU::Direct::PipelineLayoutDescriptor>)

=back

=back

=head3 createQuerySet

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::QuerySet>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::QuerySetDescriptor|WebGPU::Direct::Types/WebGPU::Direct::QuerySetDescriptor>)

=back

=back

=head3 createRenderBundleEncoder

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::RenderBundleEncoder>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::RenderBundleEncoderDescriptor|WebGPU::Direct::Types/WebGPU::Direct::RenderBundleEncoderDescriptor>)

=back

=back

=head3 createRenderPipeline

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::RenderPipeline>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::RenderPipelineDescriptor|WebGPU::Direct::Types/WebGPU::Direct::RenderPipelineDescriptor>)

=back

=back

=head3 createRenderPipelineAsync

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::RenderPipelineDescriptor|WebGPU::Direct::Types/WebGPU::Direct::RenderPipelineDescriptor>)

=item * callbackInfo (L<WebGPU::Direct::CreateRenderPipelineAsyncCallbackInfo|WebGPU::Direct::Types/WebGPU::Direct::CreateRenderPipelineAsyncCallbackInfo>)

=back

=back

=head3 createSampler

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Sampler>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::SamplerDescriptor|WebGPU::Direct::Types/WebGPU::Direct::SamplerDescriptor>) Default: {}

=back

=back

=head3 createShaderModule

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::ShaderModule>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::ShaderModuleDescriptor|WebGPU::Direct::Types/WebGPU::Direct::ShaderModuleDescriptor>)

=back

=back

=head3 createTexture

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Texture>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::TextureDescriptor|WebGPU::Direct::Types/WebGPU::Direct::TextureDescriptor>)

=back

=back

=head3 destroy

=head3 getAdapterInfo

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::AdapterInfo|WebGPU::Direct::Types/WebGPU::Direct::AdapterInfo>

=back

=back

=head3 getFeatures

=over

=item * Arguments

=over

=item * features (L<WebGPU::Direct::SupportedFeatures|WebGPU::Direct::Types/WebGPU::Direct::SupportedFeatures>)

=back

=back

=head3 getLimits

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Status|WebGPU::Direct::Constants/WebGPU::Direct::Status>

=back

=item * Arguments

=over

=item * limits (L<WebGPU::Direct::Limits|WebGPU::Direct::Types/WebGPU::Direct::Limits>)

=back

=back

=head3 getLostFuture

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=back

=head3 getQueue

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Queue>

=back

=back

=head3 hasFeature

=over

=item * Return Type

=over

=item * Boolean (WGPUBool)

=back

=item * Arguments

=over

=item * feature (L<WebGPU::Direct::FeatureName|WebGPU::Direct::Constants/WebGPU::Direct::FeatureName>)

=back

=back

=head3 popErrorScope

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=item * Arguments

=over

=item * callbackInfo (L<WebGPU::Direct::PopErrorScopeCallbackInfo|WebGPU::Direct::Types/WebGPU::Direct::PopErrorScopeCallbackInfo>)

=back

=back

=head3 pushErrorScope

=over

=item * Arguments

=over

=item * filter (L<WebGPU::Direct::ErrorFilter|WebGPU::Direct::Constants/WebGPU::Direct::ErrorFilter>)

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

