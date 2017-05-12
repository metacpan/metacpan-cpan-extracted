package Wx::Perl::TreeView::SimpleModel;

=head1 NAME

Wx::Perl::TreeView::SimpleModel - virtual tree control simple model class

=head1 DESCRIPTION

A simple model class for C<Wx::Perl::TreeView>.

=head1 METHODS

=cut

use strict;
use base qw(Wx::Perl::TreeView::Model);

=head2 new

  my $model = Wx::Perl::TreeView::SimpleModel->new( $data );

Where C<$data> has the following structure:

  { node   => 'label',
    childs => [ { ... },
                { ... },
                ],
    }

=cut

sub new {
    my( $class, $data ) = @_;
    my $self = bless { data => $data }, $class;

    return $self;
}

sub get_root {
    my( $self ) = @_;

    return ( $self->data, $self->data->{node}, undef, $self->data->{data} );
}

sub get_child_count {
    my( $self, $cookie ) = @_;
    my $childs = $cookie->{childs} || [];

    return scalar @$childs;
}

sub get_child {
    my( $self, $cookie, $index ) = @_;
    my $childs = $cookie->{childs} || [];

    return ( $childs->[$index], $childs->[$index]->{node}, undef,
             $childs->[$index]->{data} );
}

=head2 data

  my $data = $self->data;

Accessor for the model data.

=cut

sub data { $_[0]->{data} }

1;
