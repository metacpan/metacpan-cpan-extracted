package Weaving::Tablet::Twill;

use Moose;
use namespace::autoclean
use Carp;

extends 'Weaving::Tablet';

our $VERSION = '0.009.004';

sub BUILD
{
    my $self = shift;
    if ( defined $self->file_name )
    {
        $self->load_pattern;
        return;
    }
    push @{ $self->cards },
      Weaving::Tablet::Twill::Card->new(
        number_of_turns => $self->pattern_length,
        offset          => $_ % 2
      ) for 1 .. $self->number_of_cards;
}

sub load_pattern
{
    my $self = shift;

    return 0 unless defined $self->file_name;
    return 0 unless -r $self->file_name;
    open my $pattern, '<', $self->file_name
      or croak "Can't open " . $self->file_name . ": $!";
    my ( $cards, $rows, $holes ) = ( split( / /, <$pattern> ) )[ 0, 2, 4 ];
    $holes ||= 4;
    $self->number_of_cards($cards);
    $self->_set_number_of_holes($holes);

    # prime cards with empty cards
    push @{ $self->cards },
      Weaving::Tablet::Twill::Card->new( number_of_turns => 0 )
      for 1 .. $self->number_of_cards;

    my $card;
    while (<$pattern>)
    {
        chomp;
        last unless /^[\\\/|]/;
        $self->insert_pick( [ -1, $_ ] );
    }

    # now $_ contains the start line...
    tr /ABCDEFGH/01234567/;
    my @starts = split( //, $_ );
    for my $card ( 0 .. $self->number_of_cards - 1 )
    {
        $self->cards->[$card]->start( $starts[$card] );
    }

    $_ = <$pattern>;
    chomp;
    my @SZ = split( //, $_ );
    for my $card ( 0 .. $self->number_of_cards - 1 )
    {
        $self->cards->[$card]->SZ( $SZ[$card] );
    }

    for my $card ( 0 .. $self->number_of_cards - 1 )
    {
        $_ = <$pattern>;
        chomp;
        $self->cards->[$card]->set_threading( [ split( /,/, $_ ) ] );
    }

    pop @{ $self->color_table } while @{ $self->color_table };
    while (<$pattern>)
    {
        chomp;
        push @{ $self->color_table }, $_;    # use X color names here
    }

    close $pattern;

    $self->color_pattern;
    $self->initialize_cells;
    $self->twist_pattern;
    $self->dirty(0);
    1;
}

sub initialize_cells
{
    my $self = shift;
    for my $card (@{$self->cards})
    {
        $card->initialize_cells;
    }
}

__PACKAGE__->meta->make_immutable
1;
__END__

=head1 NAME

Weaving::Tablet::Twill - Perl extension for manipulating 3/1 twill tablet weaving patterns


=head1 VERSION

This document describes Weaving::Tablet::Twill version 0.9.4


=head1 SYNOPSIS

  use Weaving::Tablet;
  
