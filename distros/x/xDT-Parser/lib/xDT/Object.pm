package xDT::Object;

use v5.10;
use Moose;

use xDT::Record;

=head1 NAME

xDT::Object - Instances of this module are collections of xDT records.

=head1 SYNOPSIS

Instances should be used to aggregate records for a single patient.
Each object should start and end with respective record types of the used xDT version.

    use xDT::Object;

    my @records = (); # should be an array of xDT::Record instances
    my $object  = xDT::Object->new();
    $object->add_record(@records);

    say 'Patient number: '. $object->get_value('patient_number');
    say 'Birthdate: '. $object->get_value('birthdate');

=head1 ATTRIBUTES

=head2 records

An ArrayRef to xDT::Record instances.

=cut

has 'records' => (
    is      => 'rw',
    isa     => 'ArrayRef[xDT::Record]',
    traits  => ['Array'],
    default => sub { [ ] },
    handles => {
        get_records    => 'elements',
        add_record     => 'push',
        map_records    => 'map',
        record_count   => 'count',
        sorted_records => 'sort',
        next_record    => 'shift',
    },
    documentation => q{A collection of logical associated records.},
);

=head1 SUBROUTINES/METHODS

=head2 is_empty

Checks if this object has any records.

=cut

sub is_empty {
    my $self = shift;

    return $self->record_count == 0;
}

=head2 get_every_record($accessor)

Returns all records as arrayref, which have the given accessor.

=cut

sub get_every_record {
    my $self     = shift;
    my $accessor = shift // die 'Error: parameter $accessor missing.';
    return [ grep { $_->get_accessor() eq $accessor } $self->get_records() ];
}

=head2 get_record($accessor)

Returns the first record with the given accessor, if there are any, else undef.

=cut

sub get_record {
    my $self     = shift;
    my $accessor = shift // die 'Error: parameter $accessor missing.';
    my ($record) = grep { $_->get_accessor() eq $accessor } $self->get_records();

    return $record;
}

=head2 get_every_value($accessor)

Returns the values of all records as arrayref, which have the given accessor.

=cut

sub get_every_value {
    my $self     = shift;
    my $accessor = shift // die 'Error: parameter $accessor missing.';
    my $records  = $self->get_every_record($accessor);

    return [ map { $_->get_value } @$records ];
}

=head2 get_value($accessor)

Returns the value of the first record with the given accessor, if there are any, else undef.

=cut

sub get_value {
    my $self     = shift;
    my $accessor = shift // die 'Error: parameter $accessor missing.';
    my $record   = $self->get_record($accessor);

    return $record ? $record->get_value : undef;
}

=head2 get_records

Corresponse to the elements function.

=cut

=head2 add_record

Corresponse to the push function.

=cut

=head2 map_records

Corresponse to the map function.

=cut

=head2 record_count

Correpsonse to the count function.

=cut

=head2 sorted_records

Corresponse to the sort function.

=cut

=head2 next_record

Corresponse to the shift function.

=cut

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at medizin.uni-leipzig.de> >>

=cut

__PACKAGE__->meta->make_immutable;

1; # End of xDT::Object
