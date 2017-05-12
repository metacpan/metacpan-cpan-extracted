package xDT::Record;

use v5.10;
use Moose;
use namespace::autoclean;

use xDT::RecordType;

=head1 NAME

xDT::Record - A xDT record

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

Instances of this module correspond to records (lines) in a xDT file.
They provide some methods to acces fields and record type metadata.

    use xDT::Record;

    my $record = xDT::Record->new($line);
    say 'Value: '. $record->getValue();
    say 'Length: '. $record->getLength();

    my $recordType = $record->getRecordType();

=head1 ATTRIBUTES

=head2 length

The length of this record.

=cut

has 'length' => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	reader        => 'getLength',
	documentation => q{The length of this records value (there are 2 extra symbols at the end of the string).},
);

=head2 recordType

This records record type.

=cut

has 'recordType' => (
	is            => 'rw',
	isa           => 'Maybe[xDT::RecordType]',
	required      => 1,
	writer        => 'setRecordType',
	reader        => 'getRecordType',
	handles       => {
		getAccessor  => 'getAccessor',
		getLabels    => 'getLabels',
		getId        => 'getId',
		getType      => 'getType',
		getMaxLength => 'getLength',
		isObjectEnd  => 'isObjectEnd',
	},
	documentation => q{The record type of this record.},
);

=head2 value

The value of this record.

=cut

has 'value' => (
	is            => 'ro',
	isa           => 'Maybe[Str]',
	reader        => 'getValue',
	documentation => q{The value of this record as string.},
);


around BUILDARGS => sub {
	my ($orig, $class, $line) = @_;

	return $class->$orig(
		length     => substr($line, 0, 3),
		recordType => undef,
		value      => substr($line, 7, -2),
	);
};

=head1 SUBROUTINES/METHODS

=head2 getLength

Returns the length of this record.

=cut

=head2 getRecordType

Returns the record type of this record.

=cut

=head2 getAccessor

Returns the accessor of the records record type.

=cut

=head2 getLabels

Returns the labels of the records record type.

=cut

=head2 getId

Returns the id of the records record type.

=cut

=head2 getType

Returns the type of the records record type.

=cut

=head2 getMaxLength

Returns the maximum length of the records record type.

=cut

=head2 isObjectEnd

Checks if the records record type is an end record.

=cut

=head2 getValue

Returns the value of this record.

=cut

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at imise.uni-leipzig.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xdt-parser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=xDT-Parser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc xDT::Record


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=xDT-Parser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/xDT-Parser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/xDT-Parser>

=item * Search CPAN

L<http://search.cpan.org/dist/xDT-Parser/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Christoph Beger.

This program is released under the following license: MIT


=cut

__PACKAGE__->meta->make_immutable;

1; # End of xDT::Record