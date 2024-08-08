package WebGPU::Direct;

use v5.30;
no warnings qw(experimental::signatures);
use feature 'signatures';

our $VERSION = '0.15';

use Carp;
use WebGPU::Direct::XS;

use Exporter 'import';

our @export_all;
our %EXPORT_TAGS = ( 'all' => [ @export_all ] );
our @EXPORT_OK = ( @export_all );
our @EXPORT = qw//;

use base 'WebGPU::Direct::Instance';

sub new
{
  my $class = shift;
  die "$class does not inherit from WebGPU::Direct\n"
      if !$class->isa("WebGPU::Direct");
  $class = ref($class) ? ref($class) : $class;

  my $ref = { ref( $_[0] ) eq ref {} ? %{ $_[0] } : @_ };
  my $result = WebGPU::Direct::XS::createInstance($ref);

  # Rebless into our class, which inherits from Instance
  $result = bless( $result, $class );

  return $result;
}

sub new_window (
  $class,
  $xw = 640,
  $yh = 360,
    )
{
  if (WebGPU::Direct::XS::HAS_X11)
  {
    local $@;
    my $result = eval { $class->new_window_x11( $xw, $yh ); };
    return $result
        if $result;
  }
  if (WebGPU::Direct::XS::HAS_WAYLAND)
  {
    local $@;
    my $result = eval { $class->new_window_wayland( $xw, $yh ); };
    return $result
        if $result;
  }

  croak "Could not find a usable windowing system";
}

1;
__END__

=encoding utf-8

=head1 NAME

WebGPU::Direct - Direct access to the WebGPU native APIs.

=head1 SYNOPSIS

  use WebGPU::Direct;
  my $wgpu = WebGPU::Direct->new;
  
  my $adapter = $wgpu->RequestAdapter;
  my $device  = $adapter->RequestDevice;

=head1 DESCRIPTION

WebGPU::Direct is a thin, perl-ish coating over the WebGPU native APIs. While it provides some helper functions, much of the work is still left up to the developer to provide and know.

=head2 EXPERIMENTAL STATUS

This module is currently I<extremely> experimental, including the documentation. This includes but is not limited to the following.

=over

=item * Much of the XS code is automatically generated.

=item * Some arguments that are optional or has a default in the JavaScript WebGPU standard are required to be passed

=item * While all of the documentation is currently created, most of it is automatically generated from L<webgpu/webgpu.h|https://github.com/webgpu-native/webgpu-headers>.

=item * Not all of the generated documentation is currently accurate, for instance callbacks are handled in a perl-ish manner.

=item * Not all errors generated inside of WebGPU can be captured and likely will call C<abort>

=item * Providing the window handle for rendering is done manually

=item * Sample window creation code does have any input or controls, only a WebGPU surface is shown

=item * Memory leaks are likely to exist

=item * This has only been tested with L<wgpu-native|https://github.com/gfx-rs/wgpu-native>, not with L<Dawn|https://dawn.googlesource.com/dawn>.

=item * The WebGPU native standard is not finalized and is likely to change

=back

=head1 FUNCTIONS

=head2 new

    my $wgpu = WebGPU::Direct->new;

Create a new WebGPU::Direct instance. This inherits from L<WebGPU::Direct::Instance>, but also provides easy access to L<Constants|/CONSTANTS> and L<Types|/TYPES>.

=head2 new_window

    $wgpu->CreateSurface( { nextInChain => WebGPU::Direct->new_window( $width, $height ) } );

=over

=item Arguments

=over

=item * xw - Width of window

=item * yh - Height of window

=back

=back

Constructs a C<WebGPU::Direct::SurfaceDescriptorFrom*> object, usable for passing to L<CreateSurface|WebGPU::Direct::Instance/CreateSurface>. These are crude and simplistic windows suitable for testing WebGPU with, but there are no options and doesn't come with any way to interact or configure the window.

Currently the supported windowing systems are:

=over

=item * X11

=item * Wayland

=back

=head2 WebGPU::Direct::XS::HAS_<FOO>

Constant indicating if C<FOO> support is compiled in. This only indicates that C<WebGPU::Direct> detected and compiled C<FOO> was available when installed, making L</new_window> available. C<FOO> windows can still be used if you manually construct the C<WebGPU::Direct::SurfaceDescriptorFrom*> object.

=head1 METHODS

=head1 TYPES

There are two basic segments of types: Structs and Opaque. The struct types have members that can manipulated and modified. The opaque types are implementation specific to WebGPU so they have no fields that can be directly accessed, but they do have functions made available to them.

The struct types can be instantiated by calling C<new> on the class; opaque types can only be returned by functions.

Struct type classes can be access in a few different ways: with the class name directly or as a class method on C<WebGPU::Direct>. Struct types can also be instantiated with the C<newE<lt>TypeNameE<gt>> functions on C<WebGPU::Direct>.

    WebGPU::Direct::Color()->new({});
    WebGPU::Direct->Color->new;
    $wgpu->Color->new;
    WebGPU::Direct->newColor;
    $wgpu->newColor();

Often these type members and functions require other types. If these are given a plain hash, those hashes will be coerced into the correct type.

=head2 Functions on all struct types

=head3 new

    my $color = $wgpu->Color->new({ r => 0.0, g => 1.0, b => 0.2, a => 0.9 });

Create a new object of the requested type. It accepts either a hash or a single hashref parameters. This will automatically call L<pack> with the defaults and provided values. There is an associated C<C> level struct stored in memory along side the object.

=head3 pack

    $color->pack;

Take all of the members and copies the values from the C<perl> level down to the C<C> level struct in memory. Any references to other objects will be copied appropriately; in most cases this will copy a pointer to the referenced object. In some cases the entire struct will be copied into the object, in which case a new object will appear pointing directly to the new struct.

If you decide to manually manipulate the blessed hashref instead of using the mutator functions, you must call pack to propagate those changes down to the C<C> level.

=head3 unpack

    $color->unpack;

This is the opposite of L</pack>; this will take the values in the C<C> level struct and ensure the C<perl> level values match.

=head3 bytes

    my $binary = $color->bytes;

Returns the underlying, raw memory bytes of the struct. This includes direct pointers to other structures and the like. There is no way to save any changes to the returned string back to the C<C> level memory. L<Caveat emptor|https://en.wikipedia.org/wiki/Caveat_emptor>.

=head2 Callbacks

In some places in the WebGPU API are callbacks; functions that are passed a function and userdata. The calls are adjusted so that regular perl subs can be passed along with arbitrary perl data. The calling parameters are dependant on the callback in question, but the last parameter will always be passed userdata.

=head2 Arrays

Some types have arrays of data, represented at the C<C> level as a pointer field and a count field. These are translated from C<perl> arrayrefs into the appropriate types. If a single hashref is passed instead, it will be coerced into an array automatically.

=head2 Enums

A value saved to an enum member will get coerced into the corresponding enum L<constant|/CONSTANTS>.

=head1 CONSTANTS

All of the WebGPU enum constant sets can be accessed in a few different ways: from the package directly, as class functions on C<WebGPU::Direct>, and as exports from C<WebGPU::Direct>. All three methods return the enum package for the set. Each of the following calls will produce the same results.

    use WebGPU::Direct qw/:all/;
    TextureFormat->RGBA8Uint;
    WebGPU::Direct::TextureFormat->RGBA8Uint;
    WebGPU::Direct->TextureFormat->RGBA8Uint;
    $wgpu->TextureFormat->RGBA8Uint;

Enums are implemented as L<dualvars|Scalar::Util/dualvar>, so the numerical value will be the integer value that WebGPU expects, but the string value will match WebGPU's enum name. In the example above, C<RGBA8Uint> will have a value of C<0x00000015> as well as C<WGPUTextureFormat_RGBA8Uint>. Note that the enum name preserves both the WGPU and the enum set prefixes.

=head1 ADDITIONAL WEBGPU INFORMATION

=head2 Force32

All of the enums have a C<Force32> value. These are not valid values, but are simply there to ensure that the underlying enum is a 32bit integer. WebGPU::Direct does not include them.

=head2 SwapChain

There are older tutorials or code examples around the internet that use a C<SwapChain> type, both for WebGPU native and JavaScript. Later revisions of WebGPU eliminated that type and moved its functionality onto Surface.

=head2 WebGPU errors

The default operation of L<RequestDevice|WebGPU::Direct::Adapter/RequestDevice> will install an error handler using L<SetUncapturedErrorCallback|WebGPU::Direct::Device/SetUncapturedErrorCallback> if a device is acquired. This means any errors not handled (generally using L<PushErrorScope|WebGPU::Direct::Device/PushErrorScope>/L<PopErrorScope|WebGPU::Direct::Device/PopErrorScope>) will be thrown as L<Error|WebGPU::Direct::Error> objects. If you override how L<RequestDevice|WebGPU::Direct::Adapter/RequestDevice> searches for devices, you will need to install your own error handler.

B<BE WARNED> that WebGPU is still young and experimental, and as such WebGPU native is more so as it lags behind the WebGPU JavaScript API. This means that not all errors will be passed to L<SetUncapturedErrorCallback|WebGPU::Direct::Device/SetUncapturedErrorCallback>, any may even abort instead, and may vary wildly between implementations and versions.

=head2 Error Diagnostics

=head3 invalid vertex shader module for vertex state

This is when the Buffer's step mode is invalid. Check the buffer objects in L<VertexState|WebGPU::Direct::VertexState> to ensure the sizes are correct and align with what data you are expecting to pack into a buffer.

=head3 invalid vertex shader module for vertex state

This is when a vertex state does not include a valid L<ShaderModuleDescriptor|WebGPU::Direct::ShaderModuleDescriptor>.

=head3 invalid bind group entry for bind group descriptor

In JavaScript examples, you may see a L<BindGroupEntry|WebGPU::Direct::BindGroupEntry> have a C<resource> entry that points to a buffer, sampler or textureView. In WeGPU native, there is not that extra resource layer. So instead of C<resource =E<gt> { buffer =E<gt> $x }>, simply use C<buffer =E<gt> $x>.

=head3 (left == right), Texture[1] is no longer alive

There appears to be an issue with L<ColorAttachment|WebGPU::Direct::ColorAttachment> inside of L<RenderPassDescriptor|WebGPU::Direct::RenderPassDescriptor>, where just setting C<$renderPassDescriptor-E<gt>{colorAttachments}-E<gt>[0]-E<gt>{view}> on each frame causes this issue. This issue is likely inside of C<WebGPU::Direct>. Generating a new L<ColorAttachment|WebGPU::Direct::ColorAttachment> object should help while the fix is outstanding.

=head3 Error reflecting bind group 0: Validation Error / Invalid group index 0

When a L<RenderPipeline|WebGPU::Direct::RenderPipeline> is being ran with an C<auto> layout, that C<layout> is not defined in the L<RenderPipelineDescriptor|WebGPU::Direct::RenderPipelineDescriptor> passed to C<$device-E<gt>CreateRenderPipeline>, WebGPU will auto analyze the C<WGSL> to determine the group bindings. If a group binding is not used, the layout for it will not be included in the layout. You will need to either use the group binding in the shaders, or manually create and use a layout definition.

=head3 Surface image is already acquired

The WebGPU JavaScript API and the WebGPU Native API differ slightly in how you interact with the hardware. In JavaScript, the L<GPUCanvasContext|https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext> is used, and with the native it is a L<Surface|WebGPU::Direct::Surface>. The core functions are in both, but the Native API has several extra that the JavaScript API does not have, most notably L<Present|WebGPU::Direct::Surface/Present>, which informs the system that rendering is complete. Because of this, this you cannot acquire a L<TextureView|WebGPU::Direct::TextureView> twice in a single frame via the L<CreateView|WebGPU::Direct::TextureView/CreateView> function before calls to L<Present|WebGPU::Direct::Surface/Present>. Tryig to get it a second time will will throw this error.

Because the JavaScript WebGPU API does not have a L<Present|WebGPU::Direct::Surface/Present> function, examples will not include it; it happens implictly after each frame function. That means you must remember to call it at the end of each frame loop when the render is ready to go.

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2023- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=over

=item * L<WebGPU|https://en.wikipedia.org/wiki/WebGPU>

=item * L<WebGPU Working Draft|https://www.w3.org/TR/webgpu/>

=item * L<WebGPU native API|https://github.com/webgpu-native/>

=item * L<Dawn|https://dawn.googlesource.com/dawn>

=item * L<wgpu-native|https://github.com/gfx-rs/wgpu-native>

=back

=cut
