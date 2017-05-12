package USB::HID;

use strict;
use warnings;
use USB::Descriptor;
use USB::HID::Descriptor::Interface;

our $VERSION = '1';

=head1 NAME

USB::HID - USB HID Descriptor generation tools

=head1 SYNOPSIS

A set of classes and methods for generating USB HID descriptor sets.

    use USB::HID;

    my $device = USB::HID::Descriptor( product => 'My First Device' );
    $device->vendorID(0x1234);
    $device->productID(0x5678);
    $device->configurations( [ USB::Descriptor::Configuration->new() ] );
    ...

=head1 DESCRIPTION

L<USB::HID> provides a means of specifying a USB Human Interface Device's
descriptors and then generating descriptor structures suitable for use in the
device's firmware. However, L<USB::HID::Descriptor> only generates the bytes
that comprise the structures, it does not handle generation of valid source code.

The easiest way to create a new HID descriptor set is to use the
C<USB::HID::Descriptor()> factory method. It accepts a hash of arguments that
happens to be the same hash expected by L<USB::Descriptor::Device> and returns
a reference to a new L<USB::Descriptor::Device> object. Any interface
specifications provided to the method will be automatically converted into
L<USB::HID::Descriptor::Interface> objects

    use USB::HID;

    my $device = USB::HID::Descriptor(
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


=head1 CLASS METHODS

=over

=item $device = USB::HID::Descriptor(vendorID=>$vendorID, ...);

Constructs and returns a new L<USB::Descriptor::Device> object using the
passed options. Each option key is the name of an accessor method of
L<USB::Descriptor::Device>. Interface specifications are automatically converted
to L<USB::HID::Descriptor::Interface>.

=back

=cut

sub Descriptor
{
    my %options = @_;

    # Convert all Interfaces into HID::Interfaces
    if(exists $options{'configurations'} and scalar $options{'configurations'})
    {
	# Find the interfaces in each configuration
	foreach my $configuration ( @{$options{'configurations'}} )
	{
	    my $interfaces;
	    if( ref($configuration) eq 'HASH' )	# Hash reference?
	    {
		$interfaces = $configuration->{'interfaces'};
	    }
	    elsif( ref($configuration) )	# Reference to something else?
	    {
		$interfaces = $configuration->interfaces;
	    }

	    # Now $interfaces is a reference to an array. But, an array of what?
	    #  If an array element is a hash reference, use it to create a new
	    #   HID interface object. If it's already an object, find out what
	    #	kind of object it is and try to convert it to a HID interface
	    #	object.
	    my @interfaces = map
	    {
		if( ref($_) eq 'HASH' )	# Hash reference?
		{
		    USB::HID::Descriptor::Interface->new(%{$_});
		}
		elsif( ref($_) )		# Reference to something else?
		{
		    if( $_->isa('USB::Descriptor::Interface') )
		    {
			USB::HID::Descriptor::Interface->convert($_); # Convert it to a HID interface
		    }
		    else
		    {
			$_;	# Use it, whatever it is
		    }
		}
		else { undef; }
	    } @{$interfaces};

	    # Now insert the new interfaces array into the original location
	    #  and no one will be the wiser
	    if( ref($configuration) eq 'HASH' )	# Hash reference?
	    {
		$configuration->{'interfaces'} = \@interfaces;
	    }
	    elsif( ref($_) )		# Reference to something else?
	    {
		$configuration->interfaces = \@interfaces;
	    }
	}
    }

    # Create and return a Composite Device descriptor
    USB::Descriptor::composite(%options);
}

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-hid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-HID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::HID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-HID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-Descriptor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-HID>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-HID/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
