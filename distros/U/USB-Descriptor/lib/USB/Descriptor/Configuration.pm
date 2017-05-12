package USB::Descriptor::Configuration;

use strict;
use warnings;
use USB::Descriptor::Interface;

our $VERSION = '2'; # Bump this when the interface changes

use overload '@{}' => \&bytes;

use constant fields => qw(
    bLength bDescriptorType wTotalLength bNumInterfaces bConfigurationValue
    iConfiguration bmAttributes bMaxPower
);

=head1 NAME

USB::Descriptor::Configuration - USB Interface Descriptor

=head1 SYNOPSIS

An object representation of a USB configuration descriptor.

    use USB::Descriptor::Configuration;

    my $configuration = USB::Descriptor::Configuration->new( description => 'My First Configuration' );
    $configuration->max_current(100);	# Max current in mA
    $configuration->self_powered(1);	# Self-powered device
    $configuration->interfaces( [ USB::Descriptor::Interface->new() ] );
    ...

=head1 DESCRIPTION

L<USB::Descriptor::Configuration> represents a USB configuration descriptor.
When added to the descriptor tree of a L<USB::Descriptor::Device> object it can
be used to generate the data structures needed to compile the firmware for a USB
device.

=head1 CONSTRUCTOR

=over

=item $configuration = USB::Descriptor::Configuration->new(description=>$description, ...);

Constructs and returns a new L<USB::Descriptor::Configuration> object using the
passed options. Each option key is the name of an accessor method.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self =
    {
	'attributes'	=> 0x80,    # Bit 7 is reserved and set
	'max_current'	=> 0,
	'value'		=> 0,
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

=item $configuration->bytes (or @{$configuration} )

Returns an array of bytes containing all of the fields in the configuration
descriptor fields as well as all of the child interface descriptors.

=back

=cut

sub bytes
{
    my $s = shift;

    my @bytes;

    push @bytes, 9;		# Configuration descriptors are 9 bytes long
    push @bytes, 0x02;				# bDescriptorType
    push @bytes, 0;				# Placeholder for wTotalLength low
    push @bytes, 0;				# Placeholder for wTotalLength high

    my $numInterfaces = $s->{'interfaces'} ? @{$s->{'interfaces'}} : 0;
    push @bytes, $numInterfaces;		# bNumInterfaces

    push @bytes, $s->value;			# bConfigurationValue

    my $stringIndex = defined($s->_parent) ? $s->_parent->_index_for_string($s->description) : 0;
    push @bytes, $stringIndex;			# iConfiguration
    push @bytes, $s->attributes;		# bmAttributes
    push @bytes, int($s->max_current/2) & 0xFF;	# bMaxPower

    warn "Configuration descriptor length is wrong" unless $bytes[0] == scalar @bytes;

    # Append the interface descriptors
    my $i = 0;
    for( @{$s->{'interfaces'}} )
    {
	# Set the interface number if it hasn't already been set
	$_->number($i++) if $_->number <= $i;	# Use <= to force update of $i

	# Update $i if the interface already has a higher number
	$i = $_->number if $_->number > $i;

	push @bytes, @{$_->bytes};
    }

    # Update wTotalLength
    my $wTotalLength = scalar @bytes;
    $bytes[2] = $wTotalLength & 0xFF;		# wTotalLength low
    $bytes[3] = ($wTotalLength >> 8) & 0xFF;	# wTotalLength high

    return \@bytes;
}

=head1 ATTRIBUTES

=over

=item $interface->attributes

Direct access to the bmAttributes value. Don't use this unless you know what
you're doing.

=item $interface->description

Get/Set the configuration's description string. A string descriptor index
(iConfiguration) will be automatically assigned when arrayified by
L<USB::Descriptor::Configuration>.

=item $interface->interface

A convenience method that wraps a single hash reference in an array and passes
it to C<interfaces()>.

=item $interface->interfaces

Get/Set the array of L<USB::Descriptor::Interface> objects. All of the
interfaces in the passed array will be arrayified when the configuration object
is arrayified by L<USB::Descriptor::Device>.

=item $interface->max_current

Get/Set the configuration's max current draw in milliamps (bMaxPower). Defaults
to 0.

=item $interface->remote_wakeup

Get/Set the configuration's remote wakeup attribute (bmAttributes).

=item $interface->self_powered

Get/Set the configuration's self-powered attribute (bmAttributes).

=item $interface->value

Get/Set the configuration's configuration value (bConfigurationValue).

If no value is specified, and the configuration has been added to a
L<USB::Descriptor::Device>, a value will be automatically assigned by
L<< USB::Descriptor::Device->bytes() >>.

=back

=cut

sub attributes
{
    my $s = shift;
    $s->{'attributes'} = int(shift) & 0xFF if scalar @_;
    $s->{'attributes'};
}

sub description
{
    my $s = shift;
    $s->{'description'} = shift if scalar @_;
    $s->{'description'};
}

sub interface
{
    my $s = shift;
    $s->interfaces([$_[0]]) if( scalar(@_) and (ref($_[0]) eq 'HASH') );
    $s->{'interfaces'}[0];
}

sub interfaces
{
    my $s = shift;
    if( scalar @_ )
    {
	if( ref($_[0]) eq 'ARRAY' )
	{
	    # Convert hash reference arguments into Interface objects
	    my @interfaces = map
	    {
		if( ref($_) eq 'HASH' )	# Hash reference?
		{
		    USB::Descriptor::Interface->new(%{$_});
		}
		elsif( ref($_) )		# Reference to something else?
		{
		    $_;	# Use it
		}
	    } @{$_[0]};
	    $s->{'interfaces'} = \@interfaces;

	    # Reparent the new interface descriptors
	    $_->_parent($s) for @{$s->{'interfaces'}};
	}
	elsif( ref($_[0]) eq 'HASH' )
	{
	    # If a hash reference was passed, let interface() handle it
	    $s->interface($_[0]);
	}
    }
    $s->{'interfaces'};
}

sub max_current
{
    my $s = shift;
    $s->{'max_current'} = int(shift) & 0xFF if scalar @_;
    $s->{'max_current'};
}

sub remote_wakeup
{
    my $s = shift;
    if( scalar @_ )
    {
	if( $_[0] )
	{
	    $s->{'attributes'} |= 0x20;
	}
	else
	{
	    $s->{'attributes'} &= ~0x20;
	}

    }
    $s->{'attributes'} & 0x20;
}

sub self_powered
{
    my $s = shift;
    if( scalar @_ )
    {
	if( $_[0] )
	{
	    $s->{'attributes'} |= 0x40;
	}
	else
	{
	    $s->{'attributes'} &= ~0x40;
	}

    }
    $s->{'attributes'} & 0x40;
}

sub value
{
    my $s = shift;
    $s->{'value'} = int(shift) & 0xFF if scalar @_;
    $s->{'value'};
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

Please report any bugs or feature requests to C<bug-usb-descriptor-configuration at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-Descriptor-Configuration>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::Descriptor::Configuration


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-Descriptor-Configuration>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-Descriptor-Configuration>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-Descriptor-Configuration>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-Descriptor-Configuration/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
