package USB::Descriptor::Device;

use strict;
use warnings;
use USB::Descriptor::Configuration;

our $VERSION = '2'; # Bump this when the interface changes


use overload '@{}' => \&bytes;

use constant fields => qw(
    bLength bDescriptorType bcdUSB bDeviceClass bDeviceSubClass bDeviceProtocol
    bMaxPacketSize idVendor idProduct bcdDevice iManufacturer iProduct
    iSerialNumber bNumConfigurations
);

=head1 NAME

USB::Descriptor::Device - USB Device Descriptor

=head1 SYNOPSIS

An object representation of a USB device descriptor.

    use USB::Descriptor::Device;

    my $device = USB::Descriptor::Device->new( product => 'My First Device' );
    $device->vendorID(0x1234);
    $device->productID(0x5678);
    $device->configurations( [ USB::Descriptor::Configuration->new() ] );
    ...

=head1 DESCRIPTION

L<USB::Descriptor::Device> represents a USB device descriptor. After creating
and configuring an instanace of L<USB::Descriptor::Device>, arrayification (or
C<< $device->bytes >>) yeilds an array of all of the values that comprise the fields
of a USB Device Descriptor structure given the configured settings. The
resulting array can then be used to generate the structures (in Assembly or
C or...) necessary for building the firmware of the described device.

After adding one or more L<USB::Descriptor::Configuration> objects to an
instance of L<USB::Descriptor::Device>, it can be used to generate USB
Configuration Descriptors. Arrayifying each child descriptor in the
configurations array yields the appropriate descriptor bytes, including
interfaces and endpoints.

Strings specificed for the device descriptor (manufacturer, product or serial
number) as well as the strings for child descriptors (configuration,
interface, etc) will be automatically indexed by L<USB::Descriptor::Device> and
the proper indexes embedded in the appropriate descriptors during arrayification.

After arrayifying the L<USB::Descriptor::Device> and all child
L<USB::Descriptor::Configuration>s, the generated set of strings can be
retrieved (in index order) by calling the 'strings' method.

=head1 CONSTRUCTOR

=over

=item $device = USB::Descriptor::Device->new(vendorID=>$vendorID, ...);

Constructs and returns a new L<USB::Descriptor::Device> object using the
passed options. Each option key is the name of an accessor method.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;

    # Set defaults
    my $self = {
        'bcdUSB'	    => 0x0200,	# USB 2.0.0
	'bDeviceClass'	    => 0,	# Composite
	'bDeviceSubClass'   => 0,	# Composite
	'bDeviceProtocol'   => 0,	# Composite
	'bMaxPacketSize'    => 8,	# Low speed device
	'vendorID'	    => 0,	# Invalid
	'productID'	    => 0,	# Invalid
	'bcdDevice'	    => 0,	# Device version 0.0.0
	'strings'	    => {},
    };
    bless $self, $class;

    while( my ($key, $value) = each %options )
    {
	$self->$key($value);
    }

    return $self;
}

=head1 Arrayification

=over

=item $device->bytes (or @{$device} )

Returns an array of bytes containing all of the fields in the device
descriptor fields, but not including configuration descriptors.

=back

=cut

sub bytes
{
    my $s = shift;

    my @bytes;

    push @bytes, 0x12;	# Device descriptors are 18 bytes long
    push @bytes, 0x01;				# bDescriptorType
    push @bytes, $s->bcdUSB & 0xFF;		# bcdUSB low
    push @bytes, ($s->bcdUSB >> 8) & 0xFF;	# bcdUSB high
    push @bytes, $s->class;			# bDeviceClass
    push @bytes, $s->subclass;			# bDeviceSubClass
    push @bytes, $s->protocol;			# bDeviceProtocol
    push @bytes, $s->max_packet_size;		# bMaxPacketSize
    push @bytes, $s->vendorID & 0xFF;		# idVendor low
    push @bytes, ($s->vendorID >> 8) & 0xFF;	# idVendor high
    push @bytes, $s->productID & 0xFF;		# idProduct low
    push @bytes, ($s->productID >> 8) & 0xFF;	# idProduct high
    push @bytes, $s->bcdDevice & 0xFF;		# bcdDevice low
    push @bytes, ($s->bcdDevice >> 8) & 0xFF;	# bcdDevice high

    # Make string descriptor indices
    push @bytes, $s->_index_for_string($s->manufacturer);    # iManufacturer
    push @bytes, $s->_index_for_string($s->product);	    # iProduct
    push @bytes, $s->_index_for_string($s->serial_number);   # iSerialNumber

    my $numConfigurations = $s->{'configurations'} ? @{$s->{'configurations'}} : 0;
    push @bytes, $numConfigurations;		# bNumConfigurations

    # Check that all of the configurations have a valid bConfigurationValue
    #  Assign them sequentially for any that don't
    my $i = 0;
    for( @{$s->{'configurations'}} )
    {
	# Set the configuration value if it hasn't already been set
	$_->value($i++) if $_->value <= $i;	# Use <= to force update of $i

	# Update $i if the interface already has a higher number
	$i = $_->value if $_->value > $i;
    }

    print "Device descriptor length is wrong" unless $bytes[0] == scalar @bytes;

    return \@bytes;
}

=head1 ATTRIBUTES

=over

=item $interface->bcdDevice

Direct access to the bcdDevice value. Don't use this unless you know what you're
doing.

=item $interface->bcdUSB

Direct access to the bcdUSB value. Don't use this unless you know what you're
doing.

=item $device->class

Get/Set the device class code (bDeviceClass).

=item $interface->configuration

A convenience method that wraps a single hash reference in an array and passes
it to C<configurations()>.

=item $device->configurations

Get/Set the array of L<USB::Descriptor::Configuration> objects.

=item $device->manufacturer

Get/Set the device's manufacturer string. A string descriptor index
(iManufacturer) will be automatically assigned during arrayification.

=item $device->max_packet_size

Get/Set the maximum packet size for endpoint 0 (bMaxPacketSize). Valid values
are 8, 16, 32, 64. Defaults to 8.

=item $device->product

Get/Set the device's product string. A string descriptor index
(iProduct) will be automatically assigned during arrayification.

=item $device->productID

Get/Set the device's Product ID (idProduct).

=item $device->protocol

Get/Set the device's protocol (bDeviceProtocol).

=item $device->serial_number

Get/Set the device's serial number string. A string descriptor index
(iSerialNumber) will be automatically assigned during arrayification.

=item $device->strings

Returns an array of strings in index order from the string descriptor set.

=item $device->subclass

Get/Set the device's SubClass (bDeviceSubClass).

=item $device->usb_version

Get/Set the supported USB version (bcdUSB). The version is specified as a dotted
string. eg. '1.2.3'. Defaults to '2.0.0'.

=item $device->vendorID

Get/Set the device's Vendor ID (idVendor).

=item $device->version

Get/Set the device's version number (bcdDevice). The version is specified as a
dotted string. eg. '1.2.3'.

=back

=cut

sub bcdUSB
{
    my $s = shift;
    $s->{'bcdUSB'} = int(shift) & 0xFFFF if scalar @_;
    $s->{'bcdUSB'};
}

sub class
{
    my $s = shift;
    $s->{'bDeviceClass'} = int(shift) & 0xFF if scalar @_;
    $s->{'bDeviceClass'};
}

sub subclass
{
    my $s = shift;
    $s->{'bDeviceSubClass'} = int(shift) & 0xFF if scalar @_;
    $s->{'bDeviceSubClass'};
}

sub protocol
{
    my $s = shift;
    $s->{'bDeviceProtocol'} = int(shift) & 0xFF if scalar @_;
    $s->{'bDeviceProtocol'};
}

sub max_packet_size
{
    my $s = shift;
    $s->{'bMaxPacketSize'} = int(shift) & 0xFF if scalar @_;
    $s->{'bMaxPacketSize'};
}

sub vendorID
{
    my $s = shift;
    $s->{'vendorID'} = int(shift) & 0xFFFF if scalar @_;
    $s->{'vendorID'};
}

sub productID
{
    my $s = shift;
    $s->{'productID'} = int(shift) & 0xFFFF if scalar @_;
    $s->{'productID'};
}

sub bcdDevice
{
    my $s = shift;
    $s->{'bcdDevice'} = int(shift) & 0xFFFF if scalar @_;
    $s->{'bcdDevice'};
}

sub _sanitize_bcd_array
{
    my @v = @_;
    @v = map(int, @v);			# Force integers
    @v = $v[0..2] if 3 < scalar @v;	# Limit the array to three elements
    push @v, 0 while scalar(@v) < 3;	# Append any missing trailing zeros

    # Mask out overly large numbers
    $v[0] = $v[0] & 0xFF;
    @v[1..2] = map { $_ & 0x0F } @v[1..2];

    return @v;
}

# Pass a dotted string or an array
# Returns a string in scalar context and an array in list context
sub usb_version
{
    my $s = shift;
    if( scalar @_ )
    {
	my @v;
	# Parse string arguments, otherwise hope that the argument is an array
	if( 1 == scalar @_ )
	{
	    @v = split /\./, shift;
	}
	else
	{
	    @v = @_;
	}
	@v = _sanitize_bcd_array(@v);

	$s->{'bcdUSB'} = ($v[0] << 8) | ($v[1] << 4) | $v[2];
	$s->{'usb_version'} = \@v;
    }
    wantarray ? @{$s->{'usb_version'}} : join('.',@{$s->{'usb_version'}});
}

sub version
{
    my $s = shift;
    if( scalar @_ )
    {
	my @v;
	# Parse string arguments, otherwise hope that the argument is an array
	if( 1 == scalar @_ )
	{
	    @v = split /\./, shift;
	}
	else
	{
	    @v = @_;
	}
	@v = _sanitize_bcd_array(@v);

	$s->{'bcdDevice'} = ($v[0] << 8) | ($v[1] << 4) | $v[2];
	$s->{'device_version'} = \@v;
    }
    wantarray ? @{$s->{'device_version'}} : join('.',@{$s->{'device_version'}});
}

sub configuration
{
    my $s = shift;
    $s->configurations([$_[0]]) if( scalar(@_) and (ref($_[0]) eq 'HASH') );
    $s->{'configurations'}[0];
}

sub configurations
{
    my $s = shift;
    if( scalar @_ )
    {
	if( ref($_[0]) eq 'ARRAY' )
	{
	    # Convert hash reference arguments into Configuration objects
	    my @configurations = map
	    {
		if( ref($_) eq 'HASH' )	# Hash reference?
		{
		    USB::Descriptor::Configuration->new(%{$_});
		}
		elsif( ref($_) )		# Reference to something else?
		{
		    $_;	# Use it
		}
	    } @{$_[0]};
	    $s->{'configurations'} = \@configurations;

	    # Reparent the new configuration descriptors
	    $_->_parent($s) for @{$s->{'configurations'}};
	}
	elsif( ref($_[0]) eq 'HASH' )
	{
	    # If a hash reference was passed, let configuration() handle it
	    $s->configuration($_[0]);
	}
    }
    $s->{'configurations'};
}

# String descriptors

sub manufacturer
{
    my $s = shift;
    $s->{'manufacturer'} = shift if scalar @_;
    $s->{'manufacturer'};
}

sub product
{
    my $s = shift;
    $s->{'product'} = shift if scalar @_;
    $s->{'product'};
}

sub serial_number
{
    my $s = shift;
    $s->{'serial_number'} = shift if scalar @_;
    $s->{'serial_number'};
}

# In list context, returns the array of string descriptors
# In scalar context, returns the number of string descriptors
sub strings
{
    my $s = shift;
    my @strings;

    push @strings, $s->manufacturer if $s->manufacturer;	# Manufacturer
    push @strings, $s->product if $s->product;			# Product
    push @strings, $s->serial_number if $s->serial_number;	# Serial number
    # Walk configurations...

    return sort { $s->{'strings'}{$a} <=> $s->{'strings'}{$b} } keys %{$s->{'strings'}};
}

sub _index_for_string
{
    my ($s, $string) = @_;
    if( defined($string) and length($string) )
    {
	# Return the string's index if it's already known
	return $s->{'strings'}{$string} if $s->{'strings'}{$string};

	# Otherwise, create a new index for it
	my $max = (sort values %{$s->{'strings'}})[-1];
	$max = 0 unless $max;

	# Assign the string an index one higher than the current highest
	$s->{'strings'}->{$string} = $max+1;
	return $s->{'strings'}->{$string};
    }
    return 0;
}

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-descriptor-device at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-Descriptor-Device>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::Descriptor::Device


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-Descriptor-Device>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-Descriptor-Device>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-Descriptor-Device>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-Descriptor-Device/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
