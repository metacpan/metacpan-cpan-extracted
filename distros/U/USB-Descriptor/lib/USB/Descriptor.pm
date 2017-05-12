package USB::Descriptor;

use strict;
use warnings;
use USB::Descriptor::Device;

our $VERSION = '2';

=head1 NAME

USB::Descriptor - USB Device Descriptor generation tools

=head1 SYNOPSIS

A set of classes and methods for generating USB descriptor sets.

    use USB::Descriptor;

    my $device = USB::Descriptor::device( product => 'My First Device' );
    $device->vendorID(0x1234);
    $device->productID(0x5678);
    $device->configurations( [ USB::Descriptor::Configuration->new() ] );
    ...

=head1 DESCRIPTION

L<USB::Descriptor> provides a means of specifying a device's USB descriptors
and then generating descriptor structures suitable for use in the device's
firmware. However, L<USB::Descriptor> only generates the bytes that comprise the
structures, it does not handle generation of valid source code.

Any strings used in the descriptor set are automatically assigned indexes and
collected into a set of string descriptors by the top level
L<USB::Descriptor::Device> object.

The easiest way to create a new descriptor set is to use the
L<USB::Descriptor::device()> factory method. It accepts a hash of arguments that
happens to be the same hash expected by L<USB::Descriptor::Device> and returns
a reference to a new L<USB::Descriptor::Device> object.

    use USB::Descriptor;

    my $device = USB::Descriptor::device(
	'usb_version' 	    => '2.0.0',		# Default
	'max_packet_size'   => 64,		# Full speed device
	'vendorID'	    => 0x1234,
	'productID'	    => 0x5678,
	'manufacturer'	    => 'Acme, Inc.',
	'product'	    => 'Giant Catapult',
	'serial_number'	    => '007',
	'configurations'    => [{
	    'description'   => 'Configuration 0',
	    'remote_wakeup'	=> 1,
	    'max_current'	=> 100,   # mA
	    'interfaces'	=> [{
		'description'       => 'Interface 0',
		'endpoints'	    => [{
		    'direction'	    	=> 'in',
		    'number'	    	=> 1,
		    'max_packet_size'   => 42,
		}],
	    }],
	},
    );

The code above generates a L<USB::Descriptor::Device> object as well as a
L<USB::Descriptor::Configuration>, a L<USB::Descriptor::Interface> and a single
L<USB::Descriptor::Endpoint>. Each descriptor object is configured using the
provided arguments and added to the descriptor tree.

Values for the device descriptor structure can be obtained by calling
C<< $device->bytes >>, or by using arrayification ( C<@{$device}> ).

    my @bytes = $device->bytes

or

    my @bytes = @{$device};

A simple script can then be written to emit the device descriptor structure in
whatever language is appropriate to the device's project. For example, to store
the descriptor as an array of bytes for a B<C> language project...

    print "uint8_t device_descriptor[] = {", join(', ', @bytes), "};\n";

Calling C<bytes> on a L<USB::Descriptor::Configuration> object, or arrayifying
it, produces a similar result. However, the configuration object returns more
than a configuration descriptor worth of values. It returns the concatenated set
of configuration, interface and endpoint descriptors that is requested by a USB
host during device enumeration. Generating suitable B<C> source might be
accomplished with:

    my @configurations = @{$device->configurations};
    foreach my $configuration ( @configurations )
    {
	print 'uint8_t configuration[] = {',
		join(', ', @{$configuration->bytes} ), "}\n";
    }

When calling C<bytes>, or arrayifying a L<USB::Descriptor::Device>, all of the
child objects are queried for their strings. The resulting strings are
automatically assigned string indexes and assembled into a string descriptor set.
The set of assembled strings can be retrieved as an array, in index order, by
calling C<< $device->strings >>. The first string in the array is the string that
should be returned by the device in response to a request for string ID 1.

    my @strings = $device->strings

Suitable language-specific code can then be generated from the resulting array
of strings.

=head1 CLASS METHODS

=over

=item $device = USB::Descriptor::composite(vendorID=>$vendorID, ...);

Convience method for creating descriptors for Composite devices.

Constructs and returns a new L<USB::Descriptor::Device> object using the
passed options and sets C<class>, C<subclass>, and C<protocol> to zero. Each
option key is the name of an accessor method of L<USB::Descriptor::Device>.

=item $device = USB::Descriptor::device(vendorID=>$vendorID, ...);

Constructs and returns a new L<USB::Descriptor::Device> object using the
passed options. Each option key is the name of an accessor method of
L<USB::Descriptor::Device>.

=back

=cut

sub composite
{
    my %options = @_;		# Hijack the passed options

    $options{'class'} = 0;	# Forcefully configure for a composite device
    $options{'subclass'} = 0;
    $options{'protocol'} = 0;

    return device(%options);
}

sub device
{
    return USB::Descriptor::Device->new(@_);
}

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-descriptor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-Descriptor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::Descriptor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-Descriptor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-Descriptor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-Descriptor>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-Descriptor/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
