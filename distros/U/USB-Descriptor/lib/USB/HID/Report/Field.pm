package USB::HID::Report::Field;

use strict;
use warnings;
use feature 'switch';

our $VERSION = '1';

=head1 NAME

USB::HID::Report::Field - USB HID Report Field

=head1 SYNOPSIS

An object representation of a USB HID Report Field. L<USB::HID::Report::Field>
doesn't directly correspond to any particular part of a HID report desriptor. It
provides a convenience interface for specifying the properties of a report
field that can be translated into the appropriate descriptor items.

    use USB::HID::Report::Field;

    my $field = USB::HID::Report::Field->new( 'usage' => 1, ... );
    $field->set_attribute('variable');
    ...

=head1 DESCRIPTION

L<USB::HID::Report::Field> is an abstract representation of a field in a USB HID
Report. When added to an instance of L<USB::HID::Report> it can be used to
generate the items in HID Report Descriptor.

Several convenience constructors are provided for creating commonly used field
types.

    use USB::HID::Report::Field;

    # Button 1
    my $button = USB::HID::Report::Field->button( 'usage' => 1 );
    # 7 bits of padding
    my $constant = USB::HID::Report::Field->constant(7);


=head1 CONSTRUCTORS

Several convenience constructors are provided for creating commonly used field
types. Each constructor accepts the same arguments as the default constructor
(C<new()>). Some constructors also accept a simplified argument set.

=over

=item $field = USB::HID::Report::Field->new('usage'=>$usage, ...);

Constructs and returns a new L<USB::HID::Report::Field> object using the passed
options. Each option key is the name of an accessor method.

=item $button = USB::HID::Report::Field->button();

Constructs and returns a L<USB::HID::Report::Field> configured as a button.
B<Usage Page> and B<ReportSize> are automatically set and override any
corresponding arguments. Specify a B<Usage> to set the button number.

Alternatively, a single scalar can be passed to set the button number:

    $button = USB::HID::Report::Field->button(3);	# Button 3

=item $padding = USB::HID::Report::Field->constant($num_bits);

Constructs and returns a L<USB::HID::Report::Field> configured to be used as
constant padding bits in a report. Pass a single integer to set the number of
bits. Alternatively, a hash containing a 'bits' key can be used to set the
number of bits.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;

    # Set defaults
    my $self =
    {
	'usage'	=> 0,	# Undefined
    };

    bless $self, $class;

    while( my ($key, $value) = each %options )
    {
	$self->$key($value);
    }

    return $self;
}

sub button
{
    # If a single scalar was passed, assume it's a button number and pass it
    #  as the field's Usage
    push @_, 'usage' => pop(@_) if( 2 == @_ );

    my $s = new(@_);

    $s->logical_range(0,1);	# Binary
    $s->page(9);	# Buttons
    $s->count(1);	# Each button is a single bit
    $s->size(1);	# Each button is a single bit
    $s->set_attribute('variable');

    return $s;
}

# Accepts a single integer that behaves like 'bits'
sub constant
{
    if( 2 == @_ )
    {
	new($_[0], 'bits' => $_[1], 'attributes' => ['constant']);
    }
    else
    {
	new(@_, 'attributes' => ['constant']);
    }
}

=head1 ARRAYIFICATION

=over

=item $field->bytes(\%state)

Returns an array of bytes containing all of the items for the field. Uses %state
to avoid repeating items that have been emitted by previous fields.

=back

=cut

sub _should_emit
{
    my ($state, $tag, $value) = @_;
    if( defined($value) )
    {
	if( exists $state->{$tag} )	{ $value != $state->{$tag} }
	else 				{ 1 }
    }
    else { 0 }
}

sub _emit_item
{
    my ($state, $tag, $value) = @_;
    my $type = USB::HID::Descriptor::Report::item_type($tag);
    if( _should_emit($state->{$type}, $tag, $value) )
    {
	$state->{$type}{$tag} = $value;
	USB::HID::Descriptor::Report::item($tag, $value);
    }
    else { () }
}

sub bytes
{
    my ($s, $state) = @_;

    (
	_emit_item($state, 'logical_minimum', $s->logical_min),
	_emit_item($state, 'logical_maximum', $s->logical_max),
	_emit_item($state, 'report_count', $s->count),
	_emit_item($state, 'report_size', $s->size),
	_emit_item($state, 'usage', $s->usage),
	USB::HID::Descriptor::Report::item($state->{'main'}, $s->attributes),
    )
}

=head1 MAIN ITEM ATTRIBUTES

HID report B<Main Item>s have a number of attributes that can be set. Anything
that isn't explicitly set defaults to 0. These attributes correspond to the
names of the bits of the "Main Items" specified on page 28 of the
L<Device Class Definition for Human Interface Devices Version 1.11|http://www.usb.org/developers/devclass_docs/HID1_11.pdf>.

The attribute names accepted by C<set_attribute> are:

    constant variable relative wrap nonlinear noprefered null volatile buffered
    data array absolute nowrap linear preferred nonull nonvolatile bitfield

=over

=item $field->attributes(...)

Set the list of attributes for the field object and replace any existing list.
Returns all currently set attributes.

=item $field->set_attribute(...)

Add the passed attributes to the current list of attributes. Returns all
currently set attributes, including the passed arguments.

=back

=cut

# Replace the existing set of attributes with the given list
sub attributes
{
    my $s = shift;
    if( @_ )
    {
	$s->{'attributes'} = {};
	$s->set_attribute(@_);
    }
    keys %{$s->{'attributes'}};
}

# Set the given list of attributes. Doesn't clear existing attributes.
sub set_attribute
{
    my $s = shift;
    for(@_)
    {
	when([qw(constant variable relative wrap nonlinear noprefered null volatile buffered)])
	{
	    $s->{'attributes'}{$_} = 1;
	}
	when([qw(data array absolute nowrap linear preferred nonull nonvolatile bitfield)])
	{
	    delete $s->{'attributes'}{$_};
	}
    }
    keys %{$s->{'attributes'}};
}

=head1 ATTRIBUTES

=over

=item $field->bits($num_bits)

Sets C<size> to 1 and C<count> to C<$num_bits>. Returns C<count>,

=item $field->count()

Get/Set the field's B<ReportCount> property.

=item $field->logical_max()

Get/Set the field's maximum logical value.

=item $field->logical_min()

Get/Set the field's minimum logical value.

=item $field->logical_range($min, $max)

Get/Set both C<logical_min> and C<logical_max>.

=item $field->page($page_number)

Get/Set the field's B<Usage Page>.

=item $field->size()

Get/Set the field's B<ReportSize> property.

=item $field->usage($usage_number)

Get/Set the field's B<Usage>.

=item $field->usage_max()

Get/Set the upper end of the usage range for field objects that correspond to
multiple B<Main Item>s.

=item $field->usage_min()

Get/Set the lower end of the usage range for field objects that correspond to
mutiple B<Main Item>s.

=item $field->usage_range($min, $max)

Get/Set both C<usage_min> and C<usage_max>.

=back

=cut

sub page
{
    my $s = shift;
    $s->{'page'} = shift if scalar @_;
    $s->{'page'};
}

sub usage
{
    my $s = shift;
    $s->{'usage'} = int(shift) & 0xFF if scalar @_;
    $s->{'usage'};
}

sub usage_max
{
    my $s = shift;
    $s->{'usage_max'} = shift if scalar @_;
    $s->{'usage_max'};
}

sub usage_min
{
    my $s = shift;
    $s->{'usage_min'} = shift if scalar @_;
    $s->{'usage_min'};
}

# Pass (min,max)
sub usage_range
{
    my $s = shift;
    if( 2 == @_ )
    {
	@_[0..1] = @_[1..0] if( $_[1] < $_[0] );	# swap?
	$s->usage_min($_[0]);
	$s->usage_max($_[1]);
    }
    grep { defined $_; } ($s->usage_min, $s->usage_max);# elide undefs
}

sub logical_max
{
    my $s = shift;
    $s->{'logical_max'} = shift if scalar @_;
    $s->{'logical_max'};
}

sub logical_min
{
    my $s = shift;
    $s->{'logical_min'} = shift if scalar @_;
    $s->{'logical_min'};
}

sub logical_range
{
    my $s = shift;
    if( 2 == @_ )
    {
	@_[0..1] = @_[1..0] if( $_[1] < $_[0] );		# swap?
	$s->logical_min($_[0]);
	$s->logical_max($_[1]);
    }
    grep { defined $_; } ($s->logical_min, $s->logical_max);	# elide undefs
}

sub count
{
    my $s = shift;
    $s->{'count'} = shift if scalar @_;
    $s->{'count'};
}

sub size
{
    my $s = shift;
    $s->{'size'} = shift if scalar @_;
    $s->{'size'};
}

sub bits
{
    my $s = shift;
    if( @_ )
    {
	$s->size(1);
	$s->count(shift);
    }
    $s->count;
}

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-hid-report-field at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-HID-Report-Field>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::HID::Report::Field


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-HID-Report-Field>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-HID-Report-Field>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-HID-Report-Field>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-HID-Report-Field/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
