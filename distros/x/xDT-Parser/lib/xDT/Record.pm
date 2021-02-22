package xDT::Record;

use v5.10;
use Moose;

use xDT::RecordType;

=head1 NAME

xDT::Record - A xDT record

=head1 SYNOPSIS

Instances of this module correspond to records (lines) in a xDT file.
They provide some methods to acces fields and record type metadata.

    use xDT::Record;

    my $record = xDT::Record->new($line);
    say 'Value: '. $record->get_value();
    say 'Length: '. $record->get_length();

    my $record_type = $record->get_record_type();

=head1 ATTRIBUTES

=head2 length

The length of this record.

=cut

has 'length' => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	reader        => 'get_length',
	documentation => q{The length of this records value (there are 2 extra symbols at the end of the string).},
);

=head2 record_type

This records record type.

=cut

has 'record_type' => (
	is            => 'rw',
	isa           => 'Maybe[xDT::RecordType]',
	required      => 1,
	writer        => 'set_record_type',
	reader        => 'get_record_type',
	handles       => {
		get_accessor   => 'get_accessor',
		get_labels     => 'get_labels',
		get_id         => 'get_id',
		get_type       => 'get_type',
		get_max_length => 'get_length',
		is_object_end  => 'is_object_end',
	},
	documentation => q{The record type of this record.},
);

=head2 value

The value of this record.

=cut

has 'value' => (
	is            => 'ro',
	isa           => 'Maybe[Str]',
	reader        => 'get_value',
	documentation => q{The value of this record as string.},
);


around BUILDARGS => sub {
	my ($orig, $class, $line) = @_;

	my $value = substr($line, 7);
	$value =~ s/\s*$//g;

	return $class->$orig(
		length      => substr($line, 0, 3),
		record_type => undef,
		value       => $value,
	);
};

=head1 SUBROUTINES/METHODS

=head2 get_length

Returns the length of this record.

=cut

=head2 get_record_type

Returns the record type of this record.

=cut

=head2 get_accessor

Returns the accessor of the records record type.

=cut

=head2 get_labels

Returns the labels of the records record type.

=cut

=head2 get_id

Returns the id of the records record type.

=cut

=head2 get_type

Returns the type of the records record type.

=cut

=head2 get_max_length

Returns the maximum length of the records record type.

=cut

=head2 is_object_end

Checks if the records record type is an end record.

=cut

=head2 get_value

Returns the value of this record.

=cut

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at medizin.uni-leipzig.de> >>

=cut

__PACKAGE__->meta->make_immutable;

1; # End of xDT::Record
