package USB::HID::Descriptor::Report;

use strict;
use warnings;
use feature 'switch';

our $VERSION = '1';

our %tags = (
# Main => 0
    'input'	=> 0x80,
    'output'	=> 0x90,
    'feature'	=> 0xB0,
    'collection'=> 0xA0,
    'end'	=> 0xC0,
# Global => 1
    'usage_page'	=> 0x04,
    'logical_minimum'	=> 0x14,
    'logical_maximum'	=> 0x24,
    'physcial_minimum'	=> 0x34,
    'physical_maximum'	=> 0x44,
    'unit_exponent'	=> 0x54,
    'unit'		=> 0x64,
    'report_size'	=> 0x74,
    'report_id'		=> 0x84,
    'report_count'	=> 0x94,
    'push'		=> 0xA4,
    'pop'		=> 0xB4,
# Local => 2
    'usage'		=> 0x08,
    'usage_minimum'	=> 0x18,
    'usage_maximum'	=> 0x28,
    'designator_index'	=> 0x38,
    'designator_minimum'=> 0x48,
    'designator_maximum'=> 0x58,
    'string_index'	=> 0x78,
    'string_minimum'	=> 0x88,
    'string_maximum'	=> 0x98,
    'delimeter'		=> 0xA8,
);

our %item_size = (0 => 0, 1 => 1, 2 => 2, 4 => 3);

our %collection_type = (
    'application'	=> 1,
    'logical'		=> 2,
    'named_array'	=> 4,
    'physical'		=> 0,
    'report'		=> 3,
    'usage_switch'	=> 5,
    'usage_modifier'	=> 7,
);

our %usage_pages =
(
    'GenericDesktop'	    => 0x01,
    'SimulationControl'	    => 0x02,
    'VRControl'		    => 0x03,
    'SportControl'	    => 0x04,
    'GameControl'	    => 0x05,
    'GenericDevice'	    => 0x06,
    'Keyboard'		    => 0x07,    # Page 7 has 2 names
    'Keypad'		    => 0x07,
    'LED'		    => 0x08,
    'Button'		    => 0x09,
    'Ordinal'		    => 0x0A,
    'Consumer'		    => 0x0C,
    'Digitizers'	    => 0x0D,
    'Unicode'		    => 0x10,
    'AlphanumericDisplay'   => 0x14,
    'MedicalInstrument'	    => 0x40,
);

=head1 NAME

USB::HID::Descriptor::Report - USB Device Descriptor

=head1 SYNOPSIS

Methods for generating USB HID Report Descriptor items

=head1 DESCRIPTION

L<USB::HID::Descriptor::Report> provides a number of convenience methods for
generating the items that comprise a HID Report Descriptor.

=head1 METHODS

=over

=item tag($tag, $size)

Returns the first byte of an Item corresponding to the tag name C<$tag> and a data
size of C<$size>. The data bytes must be appended to the returned byte to create
a complete item.

=item data_size(...)

Determines the size of the data that will be appended to the byte returned by
C<tag>. If an array is passed, the data size will be determined by the length
of the array. If a single scalar is passed, the scalar's value is used to
determine the data size.

=item item($tag, ...)

Construct a report descriptor item given a tag name and associated data bytes.
Returns an array.

=item item_type($tag)

Returns the item type of the passed tag name ('main', 'global', 'local').

=back

=cut

# Return a tag for the given tag name and data size
sub tag
{
    my ($tag, $size) = @_;
    $tags{$tag} | $item_size{$size} if exists $tags{$tag} && exists $item_size{$size};
}

# Figure out the size of the data that's to be included with a tag
#  If a single scalar is passed, use the value of the scalar
#  If multiple scalars are passed, use the number of passed scalars
sub data_size
{
    if( 1 == @_ )
    {
	if( not defined $_[0] )				{ 0 }
	elsif( ($_[0] >= -128) && ($_[0] <= 127) )	{ 1 }
	elsif( ($_[0] >= -32768) && ($_[0] <= 32767) )	{ 2 }
	else						{ 4 }
    }
    else
    {
	scalar(@_);
    }
}

# Construct a report descriptor item
# Expects the tag name followed by the data bytes
sub item
{
    my $tag = shift;
    given($tag)
    {
	# Handle Main items
	when( 'collection' )
	{
	    my $type = shift;
	    push @_, $collection_type{$type} if exists $collection_type{$type};
	}
	when(['input', 'output', 'feature'])
	{
	    # Input items can't be volatile or non-volatile (page 28)
	    @_ = grep { $_ ne 'nonvolatile' and @_ ne 'volatile' } @_ if $tag eq 'input';
	    my $data = 0;	# Main items default to 0
	    for( @_ )
	    {
		when('data')		{ $data &= ~(1 << 0) }
		when('constant')	{ $data |=  (1 << 0) }
		when('array')		{ $data &= ~(1 << 1) }
		when('variable')	{ $data |=  (1 << 1) }
		when('absolute')	{ $data &= ~(1 << 2) }
		when('relative')	{ $data |=  (1 << 2) }
		when('nowrap')		{ $data &= ~(1 << 3) }
		when('wrap')		{ $data |=  (1 << 3) }
		when('linear')		{ $data &= ~(1 << 4) }
		when('nonlinear')	{ $data |=  (1 << 4) }
		when('preferred')	{ $data &= ~(1 << 5) }
		when('noprefered')	{ $data |=  (1 << 5) }
		when('nonull')		{ $data &= ~(1 << 6) }
		when('null')		{ $data |=  (1 << 6) }
		when('nonvolatile')	{ $data &= ~(1 << 7) }
		when('volatile')	{ $data |=  (1 << 7) }
		when('bitfield')	{ $data &= ~(1 << 8) }
		when('buffered')	{ $data |=  (1 << 8) }
	    }
	    # Input items are allowed to have a data size of zero, but feature
	    #  and output items must have at leat one data byte. (page 29)
	    my $data_size = data_size($data);
	    $data_size = 1 if (0 == $data_size) && ($tag ne 'input');
	    return (tag($tag, $data_size), $data);
	}
	when( 'usage_page' )
	{
	    my $page = shift;

	    # Convert UsagePage names into integers
	    if( exists($usage_pages{$page}) ) # Parameter is a string?
	    {
		unshift @_, $usage_pages{$page};
	    }
	    else    # Nope
	    {
		# Put it back and let it be handled normally
		unshift @_, $page;
	    }
	}
    }

    # Split large data elements into individual bytes
    my @b;
    @_ = map {
	@b = ();
	do {
	    push @b, $_ & 0xFF;
	    $_ >>= 8;
	} while( data_size($_) > 1 );
	@b;
    } @_;

    (tag($tag, data_size(@_)), @_);
}

# Return an item's type given its tag
sub item_type
{
    my $tag = shift;
    given( $tags{$tag} & 0x0C )
    {
	when( 0x00 ) { return 'main' }
	when( 0x04 ) { return 'global' }
	when( 0x08 ) { return 'local' }
    }
}

=head1 WRAPPERS

Wrap calls to C<item()> to make the calling code a bit prettier.

=over

=item Collection($type);

Retuns a B<Collection> item of the specified type ('application', 'logical' or
'physcial'). Returns an B<End Collection> item for 'end'.

=item Usage($usage)

Returns a B<Usage> item constructed with the given usage number.

=item UsagePage($usage)

Returns a B<Usage Page> item constructed with the given usage page number.

=back

=cut

sub Collection
{
    ($_[0] eq 'end') ? item('end') : item('collection', @_);
}

sub Usage
{
    item('usage', @_);
}

sub UsagePage
{
    item('usage_page', @_);
}


=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-hid-descriptor-report at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-HID-Descriptor-Report>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::HID::Descriptor::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-HID-Descriptor-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-HID-Descriptor-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-HID-Descriptor-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-HID-Descriptor-Report/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
