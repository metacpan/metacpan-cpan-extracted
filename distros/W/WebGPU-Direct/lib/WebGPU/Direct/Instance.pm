package WebGPU::Direct::Instance
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Carp;
  use Scalar::Util qw/reftype/;

  my %_processEvents;

  my %integrated_win = (
    'WebGPU::Direct::SurfaceSourceAndroidNativeWindow' => 1,
    'WebGPU::Direct::SurfaceSourceMetalLayer'          => 1,
    'WebGPU::Direct::SurfaceSourceWaylandSurface'      => 1,
    'WebGPU::Direct::SurfaceSourceWindowsHWND'         => 1,
    'WebGPU::Direct::SurfaceSourceXCBWindow'           => 1,
    'WebGPU::Direct::SurfaceSourceXlibWindow'          => 1,
    'X11::Xlib::Window'                                => sub
    {
      my $window = shift;

      my $opaque_display = WebGPU::Direct::XS::_x11_xlib_display_to_opaque( $window->display );
      return WebGPU::Direct::SurfaceSourceXlibWindow->new(
        {
          sType   => WebGPU::Direct::SType->surfaceSourceXlibWindow,
          display => $opaque_display,
          window  => $window->xid,
        }
      );
    },
    'X11::XCB::Window' => sub
    {
      my $window = shift;

      my $opaque_conn = WebGPU::Direct::XS::_x11_xcb_conn_to_opaque( $window->_conn );
      return WebGPU::Direct::SurfaceSourceXCBWindow->new(
        {
          sType      => WebGPU::Direct::SType->surfaceSourceXCBWindow,
          connection => $opaque_conn,
          window     => $window->id,
        }
      );
    },
  );

  my $desc_class = WebGPU::Direct::SurfaceDescriptor;

  sub createSurface (
    $self,
    $options = undef,
      )
  {
    if ( exists $integrated_win{ ref $options } )
    {
      $options = { nextInChain => $options };
    }

    if ( ref $options ne 'HASH' && ref $options ne $desc_class )
    {
      croak "createSurface requires a SurfaceDescriptor or compatible native window";
    }

    if ( exists $options->{nextInChain} )
    {
      my $next_in_chain = $options->{nextInChain};
      my $integrate     = $integrated_win{ ref $next_in_chain };
      if ( ref $integrate eq 'CODE' )
      {
        $options->{nextInChain} = $integrate->( $options->{nextInChain} );
      }

      if ( reftype $next_in_chain eq 'HASH'
        && exists $next_in_chain->{processEvents}
        && ref $next_in_chain->{processEvents} eq 'CODE' )
      {
        $next_in_chain->{processEvents}->();
        $_processEvents{$$self} //= [];
        push $_processEvents{$$self}->@*, $next_in_chain->{processEvents};
      }
    }

    if ( ref $options eq 'HASH' )
    {
      $options = WebGPU::Direct::SurfaceDescriptor->new($options);
    }

    return $self->_createSurface($options);
  }

  sub createAdapter (
    $self,
    $options  = undef,
    $callback = undef,
    $userdata = {}
      )
  {

    # If they provide a callback themselves, we will return undef
    my $adapter;

    $callback //= sub
    {
      my $status = shift;
      $adapter = shift;
      my $msg  = shift;
      my $data = shift;

      if ( $status != WebGPU::Direct::RequestAdapterStatus->success )
      {
        warn(qq{RequestAdapter returned "$msg" ($status)"});
      }
    };

    if ( !$options || !exists $options->{compatibleSurface} )
    {
      my $pkg = __PACKAGE__;
      my $fn  = 'createAdapter';
      carp "$pkg: $fn: compatibleSurface not provided"
          . "\n\tThis is likely not what you want, the returned adapter may be incompataible with your surface";
    }

    my $future = $self->requestAdapter( $options, { callback => $callback, userdata1 => $userdata } );

    while ( !defined $adapter )
    {
      my $status = $self->waitAny([$future], 500);
      die $status
        if $status->error;
    }

    return $adapter;
  }

  sub processEvents ($self)
  {
    if ( $_processEvents{$$self} )
    {
      foreach my $pe ( $_processEvents{$$self}->@* )
      {
        $pe->();
      }
    }
    return $self->_processEvents;
  }
};

# Also add a WGPUWaitStatus_* package so we can use ->is_error and ->is_success for each
{
  use v5.30;
  foreach my $constant ( WebGPU::Direct::WaitStatus->all_constants )
  {
    state %states = ( success => 1, timedOut => 1 );
    my $success = $states{$constant} ? 1 : 0;
    my $pkg = ucfirst $constant;
    local $@;
    eval qq{
      package WebGPU::Direct::WaitStatus::$pkg
      {
        sub is_error { !$success };
        sub is_success { $success };
      };
      package WGPUWaitStatus_$pkg
      {
        our \@ISA = ( "WebGPU::Direct::WaitStatus::$pkg" );
      };
    };
    die $@ if $@;
  }
}

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Instance

=head2 Methods

=head3 createSurface

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Surface>

=back

=item * Arguments

=over

=item * descriptor (L<WebGPU::Direct::SurfaceDescriptor|WebGPU::Direct::Types/WebGPU::Direct::SurfaceDescriptor>)

=back

=back

=head3 getWGSLLanguageFeatures

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Status|WebGPU::Direct::Constants/WebGPU::Direct::Status>

=back

=item * Arguments

=over

=item * features (L<WebGPU::Direct::SupportedWGSLLanguageFeatures|WebGPU::Direct::Types/WebGPU::Direct::SupportedWGSLLanguageFeatures>)

=back

=back

=head3 hasWGSLLanguageFeature

=over

=item * Return Type

=over

=item * Boolean (WGPUBool)

=back

=item * Arguments

=over

=item * feature (L<WebGPU::Direct::WGSLLanguageFeatureName|WebGPU::Direct::Constants/WebGPU::Direct::WGSLLanguageFeatureName>)

=back

=back

=head3 processEvents

=head3 requestAdapter

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::Future|WebGPU::Direct::Types/WebGPU::Direct::Future>

=back

=item * Arguments

=over

=item * options (L<WebGPU::Direct::RequestAdapterOptions|WebGPU::Direct::Types/WebGPU::Direct::RequestAdapterOptions>)

=item * callbackInfo (L<WebGPU::Direct::RequestAdapterCallbackInfo|WebGPU::Direct::Types/WebGPU::Direct::RequestAdapterCallbackInfo>)

=back

=back

=head3 waitAny

=over

=item * Return Type

=over

=item * L<WebGPU::Direct::WaitStatus|WebGPU::Direct::Constants/WebGPU::Direct::WaitStatus>

=back

=item * Arguments

=over

=item * futureCount (Integer (size_t))

=item * futures (L<WebGPU::Direct::FutureWaitInfo|WebGPU::Direct::Types/WebGPU::Direct::FutureWaitInfo>)

=item * timeoutNS (Unsigned 64bit (uint64_t))

=back

=back

=head3 addRef

=head3 release

