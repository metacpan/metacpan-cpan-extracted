package VS::Chart::RowIterator;

use strict;
use warnings;

use Scalar::Util qw(refaddr);

my %Idx;

sub new {
    my ($pkg, $values) = @_;
    
    # Sort
    my @values;
    for (my $i = 0; $i < @$values; $i++) {
        push @values, [ $values->[$i], $i ];
    }
    @values = sort { $a->[0] <=> $b->[0] } @values;
    
    # Calculate relatives
    my $min = $values[0]->[0];
    my $max = $values[-1]->[0];
    my $span = $max - $min;
    for my $value (@values) {
        my $current = $value->[0];
        my $relative = ($current - $min) / $span;
        $value->[2] = $relative;
    }
    
    my $self = bless \@values, $pkg;
    $Idx{refaddr $self} = 0;
    return $self;
}

sub min {
    my ($self) = @_;
    return $self->[0]->[0];
}

sub max {
    my ($self) = @_;
    return $self->[-1]->[0];
}

sub rows {
    my ($self) = @_;
    return scalar @$self;
}

sub next {
    my ($self) = @_;
    return $self->[$Idx{refaddr $self}++]->[1];
}

sub value {
    my ($self) = @_;
    return if $Idx{refaddr $self} < 1;
    return $self->[$Idx{refaddr $self} - 1]->[0];
}

sub relative {
    my ($self) = @_;
    return if $Idx{refaddr $self} < 1;
    return $self->[$Idx{refaddr $self} - 1]->[2];
}

sub reset {
    my ($self) = @_;   
    $Idx{refaddr $self} = 0;
}

1;
__END__

=head1 NAME

VS::Chart::RowIterator - Iterator for fetching X axis values

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( VALUES )

Creates a new iterator for the array reference I<VALUES>.

=back

=head2 INSTANCE METHODS

=over 4

=item min
 
Returns the minumum value for the axis.

=item max

Returns the maximum value for the axis.

=item rows

Returns the number of items for the axis.

=item next

Fetches the next item from the iterator and returns its row index.

=item value

Returns the value of the current row.

=item relative

Returns the relative value of the current row. This value is the offset (0 to 1) between min and max.

=item reset

Resets the iterator to start from the beginning again.

=back

=cut
