package USB::HID::Report;

use feature 'switch';
use strict;
use warnings;

use USB::HID::Report::Field;

our $VERSION = '1';

=head1 NAME

USB::HID::Report - USB HID Report

=head1 SYNOPSIS

An object representation of a USB HID Report.

    use USB::HID::Report;

    my $report = USB::HID::Report->new( reportID => 1, direction => 'input' );
    $report->fields( [ USB::HID::Report::Element->new() ] );
    ...

=head1 DESCRIPTION

L<USB::HID::Report> represents a USB HID Report. When added to an instance of
L<USB::HID::Descriptor::Interface> it can be used to generate the data
structures needed to compile the firmware for a USB device.

=head1 CONSTRUCTOR

=over

=item $interface = USB::HID::Report->new(reportID=>$reportID, ...);

Constructs and returns a new L<USB::HID::Report> object using the passed
options. Each option key is the name of an accessor method.

When constructing report objects, the report type and ID can be specified with a
single key/value pair. For example, you can use C<< new('input' => 3) >> instead
of C<< new('type' => 'input', 'reportID' => 3) >>.

=back

=cut

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;

    # Set defaults
    my $self = {
	'collection'	=> 'report',
        'reportID'	=> 1,
	'type'		=> 'input',
	'fields'	=> [],
    };
    bless $self, $class;

    while( my ($key, $value) = each %options )
    {
	# Handle the 'type => reportID' shortcut
	if( ($key eq 'input') or ($key eq 'output') or ($key eq 'feature') )
	{
	    $self->type($key);
	    $self->reportID($value);
	}
	else
	{
	    $self->$key($value);
	}
    }

    return $self;
}

=head1 ARRAYIFICATION

=over

=item $report->bytes (or @{$report} )

Returns an array of bytes containing all of the items in the report.

=back

=cut

sub bytes
{
    my ($s, $state) = @_;

    my @bytes;
    my $push_report_id = not exists $state->{'global'}{'report_id'};

    if( $push_report_id )
    {
	$state->{'global'}{'report_id'} = $s->reportID;
	push @bytes, USB::HID::Descriptor::Report::Collection('report');
	push @bytes, USB::HID::Descriptor::Report::item('report_id', $s->reportID);
    }

    # Emit all of the fields
    $state->{'main'} = $s->type;
    for my $field (@{$s->fields})
    {
	push @bytes, $field->bytes($state);
	delete $state->{'local'};	# Local state resets after a Main item
    }

    if( $push_report_id )
    {
	push @bytes, USB::HID::Descriptor::Report::Collection('end');
    };

    # Cleanup the state
    delete $state->{'main'};

    return @bytes;
}

=head1 ATTRIBUTES

=over

=item $report->collection

Get/Set the collection type used to enclose the report's items. Set to 'none' to
use a bare report.

=item $report->reportID

Get/Set the report's ID. Defaults to 1.

=item $report->type

Get/Set the report's type ('input', 'output' or 'feature'). Defaults to 'input'.

=item $report->fields

Get/Set the report's fields.

=back

=cut

sub collection
{
    my $s = shift;
    $s->{'collection_type'} = shift if @_;
    $s->{'collection_type'};
}

sub reportID
{
    my $s = shift;
    $s->{'reportID'} = int(shift) & 0xFF if @_;
    $s->{'reportID'};
}

sub type
{
    my $s = shift;
    if( @_ )
    {
	my $type = shift;
	$s->{'type'} = $type if(($type eq 'input') ||
				($type eq 'output') ||
				($type eq 'feature') );
    }
    $s->{'type'};
}

sub fields
{
    my $s = shift;
    if( @_ and ref($_[0]) eq 'ARRAY' )
    {
	my @fields;
	while( @{$_[0]} )
	{
	    my $k = shift @{$_[0]};	# Field name
	    my $v = shift @{$_[0]};	# Field initializer
	    next unless USB::HID::Report::Field->can($k);
	    given( ref($v) )
	    {
		when('HASH')	{ push @fields, USB::HID::Report::Field->$k(%{$v});	}
		when('ARRAY')	{ push @fields, USB::HID::Report::Field->$k(@{$v});	}
		when('')	{ push @fields, USB::HID::Report::Field->$k($v);	}
		default		{ push @fields, $v;	}
	    }
	}
	$s->{'fields'} = \@fields;
    }
    $s->{'fields'};
}

1;

=head1 AUTHOR

Brandon Fosdick, C<< <bfoz at bfoz.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-usb-hid-report at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=USB-HID-Report>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc USB::HID::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=USB-HID-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/USB-HID-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/USB-HID-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/USB-HID-Report/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brandon Fosdick.

This program is released under the terms of the BSD License.

=cut
