package Wx::Perl::ListView::SimpleModel;

=head1 NAME

Wx::Perl::ListView::SimpleModel - virtual list control simple model class

=head1 DESCRIPTION

A simple model class for C<Wx::Perl::ListView>.

=head1 METHODS

=cut

use strict;
use base qw(Wx::Perl::ListView::Model);

=head2 new

  my $model = Wx::Perl::ListView::SimpleModel->new( $data );

Where data has the form:

  [ [ $item, $item, $item, ... ],
    [ $item, $item, $item, ... ],
    [ $item, $item, $item, ... ],
    ]

and each item is a valid return value for C<get_item>.

=cut

sub new {
    my( $class, $data ) = @_;
    my $self = bless { data => $data }, $class;

    return $self;
}

sub get_item {
    my( $self, $row, $column ) = @_;

    return $self->data->[$row][$column];
}

sub get_item_count {
    my( $self ) = @_;

    return scalar @{$self->data};
}

=head2 data

  my $data = $self->data;

Accessor for the model data.

=cut

sub data { $_[0]->{data} }

1;
