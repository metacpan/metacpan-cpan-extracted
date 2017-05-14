package Weaving::Tablet::Card;
use strict;
use warnings;
use Carp;
use Moose;
use namespace::autoclean;

has 'number_of_holes' => (isa => 'Int', is => 'ro', default => 4);
has 'number_of_turns' => (isa => 'Int', is => 'ro', writer => '_set_turns');
has 'SZ' => (isa => 'Str', is => 'rw', default => 'S');
has 'turns' => (isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] });
has 'threading' => (isa => 'ArrayRef[Int]', is => 'ro', default => sub { [0,1,2,3] });
has 'start' => (isa => 'Int', is => 'rw', default => '0');
has 'color' => (isa => 'ArrayRef[Int]', is => 'ro', default => sub { [] });
has 'twist' => (isa => 'ArrayRef[Int]', is => 'ro', default => sub { [] });
has 'floats' => (isa => 'ArrayRef', is => 'ro', default => sub { [] });

our $VERSION = '0.9.2';

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = @_ == 1 ? shift : {@_};
    
    if (exists $args->{turns})
    {
        if (!ref $args->{turns})
        {
            $args->{turns} = [split(//, $args->{turns})];
        }
        $args->{number_of_turns} =  @{$args->{turns}};
    }
    elsif (exists $args->{number_of_turns})
    {
        $args->{turns} = [('/') x $args->{number_of_turns}];
    }
    else
    {
        die 'Must specify number_of_turns or turns';
    }
    if (exists $args->{start})
    {
        $args->{start} =~ tr/ABCDEFGH/01234567/;
    }
    return $class->$orig($args);
};

sub BUILD
{
    my $self = shift;
    $self->color_card;
    $self->twist_card;
}

sub set_threading
{
    my $self = shift;
    my ($threading) = @_;
    for my $hole (0 .. $self->number_of_holes-1)
    {
        $self->threading->[$hole] = $threading->[$hole];
    }
}

sub insert_picks
{
    my $self = shift;
    my ($after, $picks) = @_;
    my @picks = split(//, $picks);
    splice @{$self->turns}, $after+1, 0, @picks;
	$self->_set_turns(scalar @{$self->turns});
}

sub delete_picks
{
    my $self = shift;
    my @picks = reverse sort { $a <=> $b } @_;
	splice @{$self->turns}, $_, 1 for @picks;
	$self->_set_turns(scalar @{$self->turns});
}

sub color_card
{
    my $self = shift;
    my $color = $self->start;
    my $pos = $color;
    my $holes = $self->number_of_holes;
    for my $pick (0 .. $self->number_of_turns-1)
    {
        my $turn = $self->turns->[$pick];
        if ($turn ne '|')
        {
            $color = ($turn eq '/' ? $pos : $pos+1) % $holes;
            $pos = ($turn eq '/' ? $pos-1 : $pos+1) % $holes;
        }
        $self->color->[$pick] = $color;
    }
}

sub twist_card
{
    my $self = shift;
    my $twist = 0;
    my $sign = $self->SZ eq 'S' ? 1 : -1;
    for my $pick (0 .. $self->number_of_turns-1)
    {
        $twist++ if $self->turns->[$pick] eq '/';
        $twist-- if $self->turns->[$pick] eq '\\';
        $self->twist->[$pick] = $twist * $sign;
    }
}

sub float_card
{
    my $self = shift;
    $self->color_card;
    my $top = $self->color->[0];
    my $float_start = 0;
    pop @{$self->floats} while @{$self->floats};
    for my $pick (1 .. $self->number_of_turns-1)
    {
        next if $self->color->[$pick] == $top;
        push @{$self->floats}, [ $float_start, $pick ];
        $top = $self->color->[$pick];
        $float_start = $pick;
    }
    push @{$self->floats}, [ $float_start, $self->number_of_turns ];
}

__PACKAGE__->meta->make_immutable;
1;