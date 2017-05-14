package Weaving::Tablet::Twill::Card;

use Moose;
use namespace::autoclean;

extends 'Weaving::Tablet::Card';

has 'cells' => ( isa => 'ArrayRef[]', is => 'ro', default => sub { [] } );

our $VERSION = '0.009.004';

sub initialize_cells
{
    my $self = shift;
    $self->color_card;
    my $curr_color = $self->color->[0];
    my $cell_start = 0;
    my $cell       = Weaving::Tablet::Twill::Cell->new(
        color => $curr_color,
        turns => [ $self->turns->[0] ]
    );
    for my $pick ( 1 .. $self->number_of_turns - 1 )
    {
        if ( $self->color->[$pick] != $curr_color ) 
        {
            # color change forces start of new cell
            $curr_color = $self->color->[$pick];
            $cell_start = $pick;
            $self->add_cell($cell);
            my $cell       = Weaving::Tablet::Twill::Cell->new(
                color => $curr_color,
                turns => [ $self->turns->[$pick] ]
            );
            next;
        }
        if ($self->turns->[$pick] eq '|')
        {
            # idle always part of current cell
            $cell->add_turn($self->turns->[$pick], $pick);
            next;
        }
        if ($cell->cell_size > 1)
        {
            # if it's not the first pick, we call it done
            $curr_color = $self->color->[$pick];
            $cell_start = $pick;
            $self->add_cell($cell);
            my $cell       = Weaving::Tablet::Twill::Cell->new(
                color => $curr_color,
                turns => [ $self->turns->[$pick] ]
            );
            next;
        }
        
    }
}

sub add_cell
{
    my $self = shift;
    my ($cell, $after) = @_;
    if (defined $after)
    {
        die "add_cell does not do the after thing yet";
    }
    else
    {
        push @{$self->cells}, $cell;
    }
}
}
__PACKAGE__->meta->make_immutable;

1;

__END__
