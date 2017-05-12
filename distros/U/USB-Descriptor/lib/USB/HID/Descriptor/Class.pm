package USB::HID::Descriptor::Class;

use strict;
use warnings;
use USB::HID::Report;
use USB::HID::Descriptor::Report;

our $VERSION = '2'; # Bump this when the interface changes

use overload '@{}' => \&bytes;

=head1 NAME

USB::HID::Descriptor::Class - USB HID Class Descriptor

=head1 SYNOPSIS

An object representation of a USB HID class descriptor.

    use USB::HID::Descriptor::Class;

    my $class = USB::HID::Descriptor::Class->new;
    $class->country(0);
    $class->version('1.2.3');
    $class->reports( [ USB::HID::Descriptor::Report->new() ] );
    ...

=head1 DESCRIPTION

L<USB::HID::Descriptor::Class> represents a USB class descriptor for a
HID class device. Instances of L<USB::HID::Descriptor::Class> are automatically
created by L<USB::HID::Descriptor::Interface> as needed, so there's generally no
reason to use this class directly.

=head1 CONSTRUCTOR

=over

=item $class = USB::HID::Descriptor::Class->new(...);

Constructs and returns a new L<USB::HID::Descriptor::Class> object using the
passed options. Each option key is the name of an accessor method.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;

    # Set defaults
    my $self = {
        'bcdHID'	    => 0x01B0,	# HID 1.11.0
	'bCountryCode'	    => 0,	# Non-localized
	'page'		    => 0,	# Undefined
	'version'	    => [1,11,0],	# HID 1.11.0
	'reports'	    => [],
	'usage'			=> 0,	# Undefined
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

=item $class->bytes (or @{$class} )

Returns an array of bytes containing all of the fields in the class descriptor.

=back

=cut

sub bytes
{
    my $s = shift;

    my @bytes;

    push @bytes, 9;			# HID Class descriptors are 9 bytes long
    push @bytes, 0x21;				# HID class
    push @bytes, $s->bcdHID & 0xFF;		# bcdHID low
    push @bytes, ($s->bcdHID >> 8) & 0xFF;	# bcdHID high
    push @bytes, $s->country;			# bCountryCode
    push @bytes, 1;				# bNumDescriptors
    push @bytes, 0x22;				# bDescriptorType (report)

    my $length = scalar(@{$s->report_bytes});
    push @bytes, $length & 0xFF;		# wDescriptorLength low
    push @bytes, ($length >> 8) & 0xFF;		# wDescriptorLength high

    warn "Class descriptor length is wrong" unless $bytes[0] == scalar @bytes;

    return \@bytes;
}

=head1 ATTRIBUTES

=over

=item $class->bcdHID

Direct access to the B<bcdHID> value. Don't use this unless you know what you're
doing.

=item $class->country

Get/Set the country code for localized hardware (bCountryCode). Defaults to 0.

=item $class->report_bytes

Returns an array of bytes containing the report descriptor.

=item $class->report

A convenience method that wraps a single hash reference in an array and passes
it to C<reports()>.

=item $class->reports

Get/Set the array of L<USB::HID::Descriptor::Report> objects.

=item $class->version

Get/Set the HID specification release number (bcdHID). Defaults to '1.1.0'.

=back

=cut

sub bcdHID
{
    my $s = shift;
    $s->{'bcdHID'} = int(shift) & 0xFFFF if scalar @_;
    $s->{'bcdHID'};
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

sub country
{
    my $s = shift;
    $s->{'bCountryCode'} = int(shift) & 0xFF if scalar @_;
    $s->{'bCountryCode'};
}

sub report_bytes
{
    my $s = shift;
    my @bytes;
    my %state;

    # Every Report Descriptor must begin with a UsagePage, a Usage and an
    #  Application Collection, in that order. The collection contains the
    #  remainder of the descriptor.
    push @bytes, USB::HID::Descriptor::Report::UsagePage($s->page);
    push @bytes, USB::HID::Descriptor::Report::Usage($s->usage);
    push @bytes, USB::HID::Descriptor::Report::Collection('application');

    # Update the state
    $state{'local'}{'usage'} = $s->usage;
    $state{'global'}{'usage_page'} = $s->page;

    # Organize the reports by ID and type
    my %reports;
    for( @{$s->reports} )
    {
	my $reportID = $_->reportID;
	my $type = $_->type;
	$reports{$reportID}{$type} = $_;
    }

    for my $reportID (sort keys %reports)
    {
	delete $state{'global'}{'report_id'};
	for my $type (keys %{$reports{$reportID}} )
	{
	    push @bytes, ($reports{$reportID}{$type})->bytes(\%state);
	}
    }

    push @bytes, USB::HID::Descriptor::Report::Collection('end');

    \@bytes;
}

sub report
{
    my $s = shift;
    $s->reports([$_[0]]) if( scalar(@_) and (ref($_[0]) eq 'HASH') );
    $s->{'reports'}[0];
}

sub reports
{
    my $s = shift;
    if( scalar(@_) )
    {
	if( ref($_[0]) eq 'ARRAY' )
	{
	    # Convert hash reference arguments into Report objects
	    my @reports = map
	    {
		if( ref($_) eq 'HASH' )	# Hash reference?
		{
		    USB::HID::Report->new(%{$_});
		}
		elsif( ref($_) eq 'ARRAY' )	# Array reference?
		{
		    # Scan the array for field specifiers and add them to a hash
		}
		elsif( ref($_) )		# Reference to something else?
		{
		    $_;	# Use it
		}
	    } @{$_[0]};
	    $s->{'reports'} = \@reports;
	}
	elsif( ref($_[0]) eq 'HASH' )
	{
	    # If a hash reference was passed, let report() handle it
	    $s->report($_[0]);
	}
    }
    $s->{'reports'};
}

# Pass a dotted string or an array
# Returns a string in scalar context and an array in list context
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

	$s->{'bcdHID'} = ($v[0] << 8) | ($v[1] << 4) | $v[2];
	$s->{'version'} = \@v;
    }
    wantarray ? @{$s->{'version'}} : join('.',@{$s->{'version'}});
}

=head1 REPORT DESCRIPTOR ATTRIBUTES

=over

=item $class->page

Get/Set the B<Usage Page> of the interface's report descriptor. Accepts integer
values, or any of the B<Usage Page> string constants defined in
HID/Descriptor/Report.pm.

=item $class->usage

Get/Set the B<Usage> of the interface's report descriptor.

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

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-hid-descriptor-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-HID-Descriptor-Class>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::HID::Descriptor::Class


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-HID-Descriptor-Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-HID-Descriptor-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-HID-Descriptor-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-HID-Descriptor-Class/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
