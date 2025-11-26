package WebGPU::Direct::Adapter
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use WebGPU::Direct::Error qw/webgpu_die/;

  sub createDevice (
    $self,
    $descriptor = undef,
    $callback   = undef,
    $userdata   = {}
      )
  {

    # If they provide a callback themselves, we will always return undef
    my $device;

    $callback //= sub
    {
      my $status = shift;
      $device = shift;
      my $msg  = shift;
      my $data = shift;

      if ( $status != WebGPU::Direct::RequestDeviceStatus->success )
      {
        warn(qq{RequestDevice returned "$msg" ($status)"});
      }
    };

    if ( !defined $descriptor )
    {
      my $limits = WebGPU::Direct->Limits->new;

      $self->getLimits($limits);

      my $croak = sub
      {
        my $device   = shift;
        my $type     = shift;
        my $message  = shift;
        my $userdata = shift;
        webgpu_die( $type, $message );
      };

      my $error_callback = {
        callback => $croak,
      };

      my $req_limits = WebGPU::Direct->Limits->new( { limits => $limits } );
      $descriptor = WebGPU::Direct->DeviceDescriptor->new(
        requiredLimits              => $limits,
        uncapturedErrorCallbackInfo => $error_callback,
      );
    }

    my $future = $self->requestDevice( $descriptor, { callback => $callback, userdata1 => $userdata } );

    while ( !defined $descriptor )
    {
      my $status = $self->waitAny( [$future], 500 );
      die $status
          if $status->error;
    }

    return $device;
  }

  sub getLimits (
    $self,
    $limits = undef,
      )
  {
    if ( !defined $limits )
    {
      $limits = WebGPU::Direct::Limits->new;
    }

    $self->_getLimits($limits);

    return $limits;
  }

  sub getFeatures (
    $self,
    $features = undef,
      )
  {
    if ( !defined $features )
    {
      $features = WebGPU::Direct::SupportedFeatures->new;
    }

    $self->_getFeatures($features);

    return $features;
  }

  sub getInfo (
    $self,
    $info = undef,
      )
  {
    if ( !defined $info )
    {
      $info = WebGPU::Direct::AdapterInfo->new;
    }

    $self->_getInfo($info);

    return $info;
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Adapter

=head2 Methods

=head3 getFeatures

=over

=item * Arguments

=over

=item * features (L<WebGPU::Direct::SupportedFeatures|WebGPU::Direct::Types/WebGPU::Direct::SupportedFeatures>)

=back

=back

=head3 getInfo

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Status|WebGPU::Direct::Constants/WebGPU::Direct::Status>

=back

=item * Arguments

=over

=item * info (L<WebGPU::Direct::AdapterInfo|WebGPU::Direct::Types/WebGPU::Direct::AdapterInfo>)

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

=head3 requestDevice

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::DeviceDescriptor|WebGPU::Direct::Types/WebGPU::Direct::DeviceDescriptor>)

=item * callbackInfo (L<WebGPU::Direct::RequestDeviceCallbackInfo|WebGPU::Direct::Types/WebGPU::Direct::RequestDeviceCallbackInfo>)

=back

=back

=head3 addRef

=head3 release

