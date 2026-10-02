package Test2::Harness::UI::Schema::ResultBase;
use strict;
use warnings;

use Scalar::Util qw/blessed/;

use base 'DBIx::Class::Core';

sub get_all_fields {
    my $self = shift;
    my @fields = $self->result_source->columns;
    return map {
        my $val = $self->$_;
        # When a belongs_to relationship shares the same name as a FK column,
        # the accessor returns the related Row object instead of the column
        # value. Fall back to get_column to get the raw value in that case.
        $val = $self->get_column($_) if blessed($val) && $val->isa('DBIx::Class::Row');
        ($_ => $val)
    } @fields;
}

1;
