package USB::HID::Descriptor::Interface;

use strict;
use warnings;
use base 'USB::Descriptor::Interface';

use USB::HID::Descriptor::Class;

our $VERSION = '1';

=head1 NAME

USB::HID::Descriptor::Interface - USB HID Interface Descriptor

=head1 SYNOPSIS

An object representation of a USB HID interface descriptor. Subclass of
L<USB::Descriptor::Interface>.

    use USB::HID::Descriptor::Interface;

    my $interface = USB::HID::Descriptor::Interface->new( description => 'My First Interface' );
    $interface->protocol(0);
    $interface->subclass(0);
    $interface->endpoints( [ USB::Descriptor::Endpoint->new() ] );
    ...

=head1 DESCRIPTION

L<USB::HID::Descriptor::Interface> represents a USB interface descriptor for a
HID class device. When added to the descriptor tree of a
L<USB::Descriptor::Device> object it can be used to generate the data structures
needed to compile the firmware for a USB device.

=head1 CONSTRUCTOR

=over

=item $interface = USB::HID::Descriptor::Interface->new(description=>$description, ...);

Constructs and returns a new L<USB::HID::Descriptor::Interface> object using the
passed options. Each option key is the name of an accessor method. The C<class>
option is overriden.

=item $interface = USB::HID::Descriptor::Interface->convert($another_interface)

Converts a L<USB::Descriptor::Interface> object into a
L<USB::HID::Descriptor::Interface> object and returns it.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self = $class->SUPER::new(%options);

    # Force the interface class to HID
    $self->SUPER::class(0x03);

    return $self;
}

# Convert a USB::Descriptor::Interface object
sub convert
{
    my ($this, $interface) = @_;
    my $class = ref($this) || $this;
    if( ref($interface) && $interface->isa('USB::Descriptor::Interface') )
    {
	bless $interface, $class;

	# Force the interface class to HID
	$interface->SUPER::class(0x03);

	return $interface;
    }
    undef;
}

=head1 ATTRIBUTES

=over

=item $interface->class

Returns the interface's class (bInterfaceClass). No setting allowed.

=item $interface->class_descriptor

Returns the current class descriptor object. No setting allowed.

=item $interface->country

Get/Set the country code for localized hardware (bCountryCode). Defaults to 0.

=item $class->report_bytes

Returns an array of bytes containing the report descriptor.

=item $interface->report

A convenience method that wraps a single hash reference in an array and passes
it to C<reports()>.

=item $interface->reports

Get/Set the array of C<USB::HID::Descriptor::Report> objects.

=item $interface->version

Get/Set the HID specification release number (bcdHID). Defaults to '1.1.0'.

=back

=cut

# Forward the call to the Class descriptor
sub country
{
    my $s = shift;
    $s->class_descriptor->country = shift if scalar @_;
    $s->class_descriptor->country;
}

# Override class to prevent setting
sub class
{
    my $s = shift;
    $s->SUPER::class;
}

# Override class_descriptor to prevent setting
#  Create a new default Class descriptor if one doesn't already exist
sub class_descriptor
{
    my $s = shift;
    my $c = $s->SUPER::class_descriptor;
    return $c if ref($c);
    $s->SUPER::class_descriptor(USB::HID::Descriptor::Class->new);
}

sub report_bytes
{
    my $s = shift;
    $s->class_descriptor->report_bytes;
}

sub report
{
    my $s = shift;
    $s->class_descriptor->report(@_) if @_;
    $s->class_descriptor->report;
}

# Forward the call to the Class descriptor
sub reports
{
    my $s = shift;
    $s->class_descriptor->reports(@_) if @_;
    $s->class_descriptor->reports;
}

# Forward the call to the Class descriptor
sub version
{
    my $s = shift;
    $s->class_descriptor->version(shift) if @_;
    $s->class_descriptor->version;
}

=head1 REPORT DESCRIPTOR ATTRIBUTES

=over

=item $interface->page

Get/Set the B<Usage Page> of the interface's report descriptor.

=item $interface->usage

Get/Set the B<Usage> of the interface's report descriptor.

=back

=cut

sub page
{
    my $s = shift;
    $s->class_descriptor->page(@_) if @_;
    $s->class_descriptor->page;
}

sub usage
{
    my $s = shift;
    $s->class_descriptor->usage(shift) if @_;
    $s->class_descriptor->usage;
}

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-hid-descriptor-interface at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-HID-Descriptor-Interface>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::HID::Descriptor::Interface


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-HID-Descriptor-Interface>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-HID-Descriptor-Interface>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-HID-Descriptor-Interface>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-HID-Descriptor-Interface/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
