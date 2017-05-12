package VS::Chart::Dataset;

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use List::Util qw();

my %Data;
my %Attributes;

sub new {
    my ($pkg) = @_;
    
    my $self = bless \do { my $v; }, $pkg;
    $$self = refaddr $self;
    $Data{$$self} = [];
    $Attributes{$$self} = {};
    
    return $self;
}

sub set {
    my ($self, %attrs) = @_;

    my $id = refaddr $self;
    while (my ($key, $value) = each %attrs) {
        $Attributes{$id}->{$key} = $value;
    }
}

sub get {
    my ($self, $key) = @_;
    return $Attributes{refaddr $self}->{$key};
}

sub max {
    my $self = shift;
    return List::Util::max grep { defined } @{$Data{$$self}};
}

sub min {
    my $self = shift;
    return List::Util::min grep { defined } @{$Data{$$self}};
}

sub length {
    my $self = shift;
    return scalar @{$Data{$$self}};
}

sub insert {
    my ($self, $idx, $value) = @_;
    $Data{$$self}->[$idx] = $value;
}

sub value {
    my ($self, $idx) = @_;
    return $Data{$$self}->[$idx];
}    

sub data {
    my ($self) = @_;
    return $Data{$$self};
}

sub DESTROY {
    my $self = shift;
    delete $Data{$$self};
}

1;
__END__

=head1 NAME

VS::Chart::Dataset - Carries data to be displayed in chart

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new 

Creates a new instance.

=back

=head2 INSTANCE METHODS

=over 4

=item data

Returns an array reference of all data in the dataset.

=item max

Returns the maximum value in the dataset.

=item min

Returns the minimum value in the dataset.

=item length

Returns the number of items in the dataset.

=item insert ( INDEX, VALUE )

Sets the contents of the row I<INDEX> to I<VALUE>. Rows start at 0.

=item value ( INDEX )

Returns the value at row I<INDEX>. Rows start at 0.

=item set ( %ATTRIBUTE )

Sets attributes on the dataset such as C<color>.

=item get ( ATTRIBUTE )

Returns the value for the requested attribute.

=back

=cut
