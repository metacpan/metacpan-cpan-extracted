package Text::vCard::Precisely::V4::Node::N;

use Carp;
use Moose;

my @order = qw( family given additional prefixes suffixes );

extends qw|Text::vCard::Precisely::V3::Node::N Text::vCard::Precisely::V4::Node|;

has sort_as => ( is => 'rw', isa => 'Str' );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID if $self->altID;
    push @lines, 'PID=' . join ',', @{ $self->pid } if $self->pid;
    push @lines, 'LANGUAGE=' . $self->language if $self->language;
    push @lines, 'SORT-AS="' . $self->sort_as . '"' if $self->sort_as;

    my @values = map{ $self->_escape($_) } map{ $self->$_ or  $self->content && $self->content()->{$_} } @order;

    my $string = join(';', @lines ) . ':' . join( ';', @values );
    return $self->fold( $string, -force => 1 );
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
