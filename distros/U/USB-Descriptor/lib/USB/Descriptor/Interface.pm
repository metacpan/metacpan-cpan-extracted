package USB::Descriptor::Interface;

use strict;
use warnings;
use USB::Descriptor::Endpoint;

our $VERSION = '2'; # Bump this when the interface changes

use overload '@{}' => \&bytes;

use constant fields => qw(
    bLength bDescriptorType bInterfaceNumber bAlternateSetting bNumEndpoints
    bInterfaceClass bInterfaceSubClass bInterfaceProtocol iInterface
);

=head1 NAME

USB::Descriptor::Interface - USB Interface Descriptor

=head1 SYNOPSIS

An object representation of a USB interface descriptor.

    use USB::Descriptor::Interface;

    my $interface = USB::Descriptor::Interface->new( description => 'My First Interface' );
    $interface->class(0);
    $interface->subclass(0);
    $interface->endpoints( [ USB::Descriptor::Endpoint->new() ] );
    ...

=head1 DESCRIPTION

L<USB::Descriptor::Interface> represents a USB interface descriptor. When added
to the descriptor tree of a L<USB::Descriptor::Device> object it can be used to
generate the data structures needed to compile the firmware for a USB device.

=head1 CONSTRUCTOR

=over

=item $interface = USB::Descriptor::Interface->new(description=>$description, ...);

Constructs and returns a new L<USB::Descriptor::Interface> object using the
passed options. Each option key is the name of an accessor method.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self =
    {
	'bAlternateSetting'	=> 0,
	'bInterfaceClass'	=> 0,
	'bInterfaceNumber'	=> 0,
	'bInterfaceSubClass'	=> 0,
	'bInterfaceProtocol'	=> 0,
    };
    bless $self, $class;

    while( my ($key, $value) = each %options )
    {
	$self->$key($value);
    }

    return $self;
}

=head1 ARRAYIFICATION

=over

=item $interface->bytes (or @{$interface} )

Returns an array of bytes containing all of the fields in the interface
descriptor as well as all of the child endpoint descriptors.

=back

=cut

sub bytes
{
    my $s = shift;

    my @bytes;

    push @bytes, 9;		# Interface descriptors are 9 bytes long
    push @bytes, 0x04;				# bDescriptorType
    push @bytes, $s->number;			# bInterfaceNumber
    push @bytes, $s->alternate;			# bAlternateSetting

    my $numEndpoints = defined($s->{'endpoints'}) ? @{$s->{'endpoints'}} : 0;
    push @bytes, $numEndpoints;			# bNumEndpoints

    push @bytes, $s->class;			# bInterfaceClass
    push @bytes, $s->subclass;			# bInterfaceSubClass
    push @bytes, $s->protocol;			# bInterfaceProtocol
    my $stringIndex = defined($s->_parent) ? $s->_parent->_index_for_string($s->description) : 0;
    push @bytes, $stringIndex;			# iInterface

    warn "Interface descriptor length is wrong" unless $bytes[0] == scalar @bytes;

    # Append the Class Descriptor, if one is available
    push @bytes, @{$s->class_descriptor->bytes} if( ref($s->class_descriptor) );

    # Append the endpoint descriptors
    push @bytes, @{$_->bytes} for @{$s->{'endpoints'}};

    return \@bytes;
}

=head1 ATTRIBUTES

=over

=item $interface->alternate

Get/Set the alternate setting value (bAlternateSetting).

=item $interface->class

Get/Set the interface class (bInterfaceClass).

=item $interface->class_descriptor

Get/Set the interface class descriptor object reference.

=item $interface->description

Get/Set the interface's description string. A string descriptor index (iInterface)
will be automatically assigned when arrayified by L<USB::Descriptor::Configuration>.

=item $interface->endpoint

A convenience method that wraps a single hash reference in an array and passes
it to C<endpoints()>.

=item $interface->endpoints

Get/Set the array of L<USB::Descriptor::Endpoint> objects. All of the endpoints
in the passed array will be arrayified when the interface object is arrayified
by L<USB::Descriptor::Configuration>.

=item $interface->number

Get/Set the interface's number (bInterfaceNumber).

=item $interface->protocol

Get/Set the interface's protocol (bInterfaceProtocol).

=item $interface->subclass

Get/Set the interface's SubClass (bInterfaceSubClass).

=back

=cut

sub alternate
{
    my $s = shift;
    $s->{'bAlternateSetting'} = int(shift) & 0xFF if scalar @_;
    $s->{'bAlternateSetting'};
}

sub class
{
    my $s = shift;
    $s->{'bInterfaceClass'} = int(shift) & 0xFF if scalar @_;
    $s->{'bInterfaceClass'};
}

sub class_descriptor
{
    my $s = shift;
    $s->{'class_descriptor'} = shift if @_ and ref($_[0]);
    $s->{'class_descriptor'};
}

sub description
{
    my $s = shift;
    $s->{'description'} = shift if scalar @_;
    $s->{'description'};
}

sub endpoint
{
    my $s = shift;
    $s->endpoints([$_[0]]) if( scalar(@_) and (ref($_[0]) eq 'HASH') );
    $s->{'endpoints'}[0];
}

sub endpoints
{
    my $s = shift;
    if( scalar @_ )
    {
	if( ref($_[0]) eq 'ARRAY' )
	{
	    # Convert hash reference arguments into Endpoint objects
	    my @endpoints = map
	    {
		if( ref($_) eq 'HASH' )	# Hash reference?
		{
		    USB::Descriptor::Endpoint->new(%{$_});
		}
		elsif( ref($_) )		# Reference to something else?
		{
		    $_;	# Use it
		}
	    } @{$_[0]};
	    $s->{'endpoints'} = \@endpoints;

	    # Reparent the new interface descriptors
	    $_->_parent($s) for @{$s->{'endpoints'}};
	}
	elsif( ref($_[0]) eq 'HASH' )
	{
	    # If a hash reference was passed, let endpoint() handle it
	    $s->endpoint($_[0]);
	}
    }
    $s->{'endpoints'};
}

sub number
{
    my $s = shift;
    $s->{'bInterfaceNumber'} = int(shift) & 0xFF if scalar @_;
    $s->{'bInterfaceNumber'};
}

sub protocol
{
    my $s = shift;
    $s->{'bInterfaceProtocol'} = int(shift) & 0xFF if scalar @_;
    $s->{'bInterfaceProtocol'};
}

sub subclass
{
    my $s = shift;
    $s->{'bInterfaceSubClass'} = int(shift) & 0xFF if scalar @_;
    $s->{'bInterfaceSubClass'};
}

# --- String Descriptor support ---

# Called by children during arrayification
sub _index_for_string
{
    my ($s, $string) = @_;
    if( defined($string) and length($string) and defined($s->_parent) )
    {
	return $s->_parent->_index_for_string($string);
    }
    return 0;
}

# Get/Set the object parent
sub _parent
{
    my $s = shift;
    $s->{'parent'} = shift if scalar(@_) && $_[0]->can('_index_for_string');
    $s->{'parent'};
}

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-descriptor-interface at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-Descriptor-Interface>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::Descriptor::Interface


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-Descriptor-Interface>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-Descriptor-Interface>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-Descriptor-Interface>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-Descriptor-Interface/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
