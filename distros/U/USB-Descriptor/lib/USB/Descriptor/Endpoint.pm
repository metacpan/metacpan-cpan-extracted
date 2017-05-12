package USB::Descriptor::Endpoint;

use strict;
use warnings;
use 5.010;	# Require perl 5.10 to enable the switch feature

our $VERSION = '2'; # Bump this when the interface changes

use overload '@{}' => \&bytes;

use constant fields => qw(
    bLength bDescriptorType bEndpointAddress bmAttributes wMaxPacketSize
    bInterval
);

=head1 NAME

USB::Descriptor::Endpoint - USB Endpoint Descriptor

=head1 SYNOPSIS

An object representation of a USB endpoint descriptor.

    use USB::Descriptor::Endpoint;

    my $endpoint = USB::Descriptor::Endpoint->new( address => 1 );
    $endpoint->type('interrupt');
    $endpoint->direction('in');
    ...

=head1 DESCRIPTION

L<USB::Descriptor::Endpoint> represents a USB interface descriptor. When added
to the descriptor tree of a L<USB::Descriptor::Device> object it can be used to
generate the data structures needed to compile the firmware for a USB device.

=head1 CONSTRUCTOR

=over

=item $endpoint = USB::Descriptor::Endpoint->new(interval=>$interval, ...);

Constructs and returns a new L<USB::Descriptor::Endpoint> object using the
passed options. Each option key is the name of an accessor method.

When constructing endpoint objects, the endpoint direction and endpoint
number can be specified with a single key/value pair. For example, you can use
C<< new('in' => 3) >> instead of C<< new('direction' => 'in', 'number' => 3) >>.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self =
    {
	'address'	=> 0,	    # Endpoint 0 OUT is invalid
	'attributes'	=> 0,	    # Control
	'bMaxPacketSize'=> 0,
	'bInterval'	=> 10,	    # 10ms at low/full speed, 125ms at high speed
    };
    bless $self, $class;

    while( my ($key, $value) = each %options )
    {
	# Handle the 'direction => number' shortcut for specifying endpoints
	if( ($key eq 'in') or ($key eq 'out') )
	{
	    $self->direction($key);
	    $self->number($value);
	}
	else
	{
	    $self->$key($value);
	}
    }

    return $self;
}

=head1 Arrayification

=over

=item $endpoint->bytes (or @{$interface} )

Returns an array of bytes containing all of the fields in the endpoint
descriptor.

=back

=cut

sub bytes
{
    my $s = shift;

    my @bytes;

    push @bytes, 7;			# Endpoint descriptors are 7 bytes long
    push @bytes, 0x05;					# bDescriptorType
    push @bytes, $s->address;				# bEndpointAddress
    push @bytes, $s->attributes;			# bmAttributes
    push @bytes, $s->max_packet_size & 0xFF;		# wMaxPacketSize low
    push @bytes, ($s->max_packet_size >> 8) & 0xFF;	# wMaxPacketSize high

    # Force interval=1 for isochronous endpoints
    $s->interval(1) if( 1 == ($s->{'attributes'} & 0x03) );

    push @bytes, $s->interval;				# bInterval

    warn "Endpoint descriptor length is wrong" unless $bytes[0] == scalar @bytes;

    return \@bytes;
}

=head1 ATTRIBUTES

=over

=item $interface->address

Direct access to the bEndpointAddress value. Don't use this unless you know what
you're doing.

=item $interface->attributes

Direct access to the bmAttributes value. Don't use this unless you know what
you're doing.

=item $interface->direction

Get/Set the endpoint's direction (bEndpointAddress). Pass 'in' for an IN
endpoint or 'out' for an OUT endpoint.

=item $interface->interval

Get/Set the endpoint's polling interval in frame counts (bInterval). Forced to
1 for isochronous endpoints as required by the USB specification.

=item $interface->max_packet_size

Get/Set the endpoint's maximum packet size (wMaxPacketSize).

=item $interface->number

Get/Set the endpoint number (bEndpointAddress).

=item $interface->synchronization_type

Get/Set the endpoint's synchronization type (bmAttributes). Only used by
isochronous endpoints.

=item $interface->type

Get/Set the endpoint's type (bmAttributes). Valid values are 'control',
'isochronous', 'bulk', and 'interrupt'.

=item $interface->usage_type

Get/Set the endpoint's usage type (bmAttributes). Only used by isochronous
endpoints.

=back

=cut

sub address
{
    my $s = shift;
    $s->{'address'} = int(shift) & 0xFF if scalar @_;
    $s->{'address'};
}

sub attributes
{
    my $s = shift;
    $s->{'attributes'} = int(shift) & 0xFF if scalar @_;
    $s->{'attributes'};
}

sub direction
{
    my $s = shift;
    if( scalar @_ )
    {
	my $d = shift;
	given($d)
	{
	    when('in')	{ $s->{'address'} |= 0x80; }	# Set the direction bit for IN
	    when('out')	{ $s->{'address'} &= ~0x80; }	# Clear the direction bit for OUT
	}
    }
    ($s->{'address'} & 0x80) ? 'in' : 'out';
}

sub interval
{
    my $s = shift;
    $s->{'bInterval'} = int(shift) & 0xFF if scalar @_;
    $s->{'bInterval'};
}

sub max_packet_size
{
    my $s = shift;
    $s->{'bMaxPacketSize'} = int(shift) & 0xFF if scalar @_;
    $s->{'bMaxPacketSize'};
}

sub number
{
    my $s = shift;
    $s->{'address'} = ($s->{'address'} & ~0x0F) | (int(shift) & 0x0F) if scalar @_;
    $s->{'address'} & 0x0F;
}

sub synchronization_type
{
    my $s = shift;
    if( scalar @_ )
    {
	my $a = shift;
	my $masked = $s->{'attributes'} & ~0x0C;
	given($a)
	{
	    when('none')	{ $s->{'attributes'} = $masked;	}
	    when('asynchronous'){ $s->{'attributes'} = $masked | (0x01 << 2); }
	    when('adaptive' )	{ $s->{'attributes'} = $masked | (0x02 << 2); }
	    when('synchronous')	{ $s->{'attributes'} = $masked | (0x03 << 2); }
	}
    }

    my $t = ($s->{'attributes'} & 0x0C) >> 2;

    if( 0 == $t )   { 'none'; }
    elsif( 1 == $t) { 'asynchronous'; }
    elsif( 2 == $t) { 'adaptive'; }
    elsif( 3 == $t) { 'synchronous'; }
    else	    { undef; }
}

sub type
{
    my $s = shift;
    if( scalar @_ )
    {
	my $d = shift;
	my $masked = $s->{'attributes'} & ~0x03;
	if( $d eq 'control' )
	{
	    $s->{'attributes'} = $masked;
	}
	elsif( $d eq 'isochronous' )
	{
	    $s->{'attributes'} = $masked | 0x01;
	    $s->interval(1);	# Isochronous endpoints must have interval == 1
	}
	elsif( $d eq 'bulk' )
	{
	    $s->{'attributes'} = $masked | 0x02;
	}
	elsif( $d eq 'interrupt' )
	{
	    $s->{'attributes'} = $masked | 0x03;
	}
    }

    my $t = $s->{'attributes'} & 0x03;

    if( 0 == $t )   { 'control'; }
    elsif( 1 == $t) { 'isochronous'; }
    elsif( 2 == $t) { 'bulk'; }
    elsif( 3 == $t) { 'interrupt'; }
    else	    { undef; }
}

sub usage_type
{
    my $s = shift;
    if( scalar @_ )
    {
	my $a = shift;
	my $masked = $s->{'attributes'} & ~0x0C;
	if( $a eq 'data' )
	{
	    $s->{'attributes'} = $masked;
	}
	elsif( $a eq 'feedback' )
	{
	    $s->{'attributes'} = $masked | (0x01 << 2);
	}
	elsif( $a eq 'explicit' )
	{
	    $s->{'attributes'} = $masked | (0x02 << 2);
	}
    }

    my $t = ($s->{'attributes'} & 0x0C) >> 2;

    if( 0 == $t )   { 'data'; }
    elsif( 1 == $t) { 'feedback'; }
    elsif( 2 == $t) { 'explicit'; }
    else	    { undef; }
}


# --- String Descriptor support ---

sub _index_for_string
{
    my ($s, $string) = @_;
    if( defined($string) and length($string) and defined($s->_parent) )
    {
	return $s->_parent->_index_for_string($string);
    }
    return 0;
}

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

Please report any bugs or feature requests to C<bug-usb-descriptor-endpoint at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-Descriptor-Endpoint>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::Descriptor::Endpoint


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-Descriptor-Endpoint>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-Descriptor-Endpoint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-Descriptor-Endpoint>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-Descriptor-Endpoint/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
