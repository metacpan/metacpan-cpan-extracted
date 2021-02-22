package xDT::RecordType;

use v5.10;
use Moose;

=head1 NAME

xDT::RecordType - The record type of a xDT record.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use xDT::RecordType;

    my $record_type = xDT::RecordType->new($id);
	# or
	my $record_type = xDT::RecordType->new($id, $config_file);

	say $record_type->get_labels()->{en};
	say $record_type->get_accessor();

=head1 CONSTANTS

=head2 LENGTH

The maximum length of a record type identifier.

=head2 END_RECORD_ID

ID of records at the end of an object.

=cut

use constant {
	LENGTH        => 4,
	END_RECORD_ID => 8003,
};

=head1 ATTRIBUTES

=head2 id

Unique identifier of this record type.

=cut

has id => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	reader        => 'get_id',
	trigger       => \&_check_id,
	documentation => q{Unique identifier of this record type.},
);

=head2 labels

The human readable labels of this record type. Language is used as key value.

=cut

has labels => (
	is            => 'ro',
	isa           => 'Maybe[HashRef[Str]]',
	reader        => 'get_labels',
	documentation => q{The human readable labels of this record type. Language is used as key value.},
);

=head2 accessor

Short string for easy access to this record via xDT::Object.

=cut

has accessor => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	lazy          => 1,
	reader        => 'get_accessor',
	default       => sub { shift->get_id },
	documentation => q{Short string for easy access to this record via xDT::Object.},
);

=head2 length

Max length of this record type.

=cut

has length => (
	is            => 'ro',
	isa           => 'Maybe[Str]',
	reader        => 'get_length',
	documentation => q{Max length of this record type.},
);

=head2 type

Corresponds to xDT record type string.

=cut

has type => (
	is            => 'ro',
	isa           => 'Maybe[Str]',
	reader        => 'get_type',
	documentation => q{Corresponds to xDT record type string.},
);

=head1 SUBROUTINES/METHODS

=head2 is_object_end

Checks if this record type is an ending record

=cut

sub is_object_end {
	my $self = shift;

	return $self->get_id == END_RECORD_ID;
}

=head2 get_id

Returns the id of this record type.

=cut

=head2 get_labels

Returns the labels of this record type.

=cut

=head2 get_accessor

Returns the accessor of this record type.

=cut

=head2 get_length

Returns the maximum length of this recourd type.

=cut

=head2 build_from_arrayref

Constructs a C<RecordType> from a arrayref containing configurations.
This method will propagate the hashref, that contains the provided id, to the C<new> method.

=cut

sub build_from_arrayref {
	my $id       = shift // die 'Error: parameter $id missing.';
	my $arrayref = shift;
	my $config;

	($config) = grep { $_->{id} eq $id } @$arrayref
		if ($arrayref);

	$config = { id => $id, accessor => $id } unless ($config);

	return xDT::RecordType->new($config);
}


sub _check_id {
	my ($self, $id) = @_;

	die(sprintf("Error: attribute 'id' has length %d (should be %d).", length $id, LENGTH))
		unless (length $id == LENGTH);
}

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at medizin.uni-leipzig.de> >>

=cut

__PACKAGE__->meta->make_immutable;

1; # End of xDT::RecordType
